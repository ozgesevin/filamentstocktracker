//
//  CloudInventoryStore.swift
//  FilamentStockTracker
//
//  Created by Ozge Sevin Keskin on 25.12.2025.
//
import Foundation
import Combine
import Supabase
import UserNotifications

@MainActor
final class CloudInventoryStore: ObservableObject {
    @Published private(set) var stocks: [StockRow] = []
    @Published private(set) var logs: [LogRow] = []
    @Published var lowStockThreshold: Int = 20
    @Published var lastError: String? = nil
    @Published var isLoading: Bool = false

    let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            lastError = nil
            let s: [StockRow] = try await client.from("stock").select().execute().value
            let l: [LogRow] = try await client.from("log").select().order("created_at", ascending: false).limit(200).execute().value
            self.stocks = s.sorted { $0.material < $1.material }
            self.logs = l
        } catch {
            lastError = error.localizedDescription
        }
    }

    func quantity(for material: MaterialType) -> Int {
        stocks.first(where: { $0.material == material.rawValue })?.quantity ?? 0
    }

    // MARK: - Public actions

    func addStock(material: MaterialType, amount: Int, userEmail: String?) async {
        await adjust(material: material, delta: abs(amount), reason: "Stock In", userEmail: userEmail)
    }

    func subtractStock(material: MaterialType, amount: Int, reason: String, userEmail: String?) async {
        await adjust(material: material, delta: -abs(amount), reason: reason, userEmail: userEmail)
    }

    // MARK: - Internals

    private struct StockUpsert: Codable {
        let material: String
        let quantity: Int
    }

    private struct LogInsert: Codable {
        let material: String
        let delta: Int
        let reason: String
        let user_email: String?
    }

    private func adjust(material: MaterialType, delta: Int, reason: String, userEmail: String?) async {
        guard delta != 0 else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            lastError = nil

            let current = quantity(for: material)
            let newQty = max(0, current + delta)

            // stock upsert (stock.material UNIQUE olmalı)
            let stockPayload = StockUpsert(material: material.rawValue, quantity: newQty)
            _ = try await client
                .from("stock")
                .upsert(stockPayload, onConflict: "material")
                .execute()

            // log insert
            let logPayload = LogInsert(material: material.rawValue, delta: delta, reason: reason, user_email: userEmail)
            _ = try await client
                .from("log")
                .insert(logPayload)
                .execute()

            await refresh()

            if newQty <= lowStockThreshold {
                await notifyLowStock(material: material, quantity: newQty)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Notifications

    func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    private func notifyLowStock(material: MaterialType, quantity: Int) async {
        await requestNotificationPermissionIfNeeded()

        let content = UNMutableNotificationContent()
        content.title = "Low stock: \(material.rawValue)"
        content.body = "\(material.rawValue) stock is \(quantity). Threshold: \(lowStockThreshold)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "low-\(material.rawValue)", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(req)
    }
}
