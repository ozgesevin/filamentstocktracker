//
//  CloudInventoryStore.swift
//  FilamentStockTracker
//
//  Created by Ozge Sevin Keskin on 25.12.2025.
//
import Foundation
import Combine
import Supabase

@MainActor
final class CloudInventoryStore: ObservableObject {
    @Published private(set) var stock: [MaterialType: Int] = [:]
    @Published private(set) var log: [LogRow] = []

    init() {
        // başlangıç: hepsi 0
        MaterialType.ordered.forEach { stock[$0] = 0 }
    }

    func qty(_ m: MaterialType) -> Int {
        max(0, stock[m] ?? 0)
    }

    func refresh() async {
        do {
            let stockRows: [StockRow] = try await supabase
                .from("stock")
                .select()
                .order("material", ascending: true)
                .execute()
                .value

            var newStock: [MaterialType: Int] = [:]
            MaterialType.ordered.forEach { newStock[$0] = 0 }
            for r in stockRows {
                newStock[r.material] = max(0, r.qty)
            }
            self.stock = newStock

            let logs: [LogRow] = try await supabase
                .from("stock_log")
                .select()
                .order("created_at", ascending: false)
                .limit(200)
                .execute()
                .value

            self.log = logs
        } catch {
            print("refresh error:", error)
        }
    }

    func add(material: MaterialType, amount: Int, note: String? = nil) async {
        guard amount > 0 else { return }
        await adjust(material: material, delta: amount, reason: .other, note: note ?? "Ekleme")
    }

    func subtract(material: MaterialType, amount: Int, reason: StockReason, note: String? = nil) async {
        guard amount > 0 else { return }
        await adjust(material: material, delta: -amount, reason: reason, note: note)
    }

    private func adjust(material: MaterialType, delta: Int, reason: StockReason, note: String?) async {
        do {
            // RPC imzası: p_material / p_delta / p_reason / p_note
            let result: [AdjustResult] = try await supabase
                .rpc("adjust_stock", params: [
                    "p_material": material.rawValue,
                    "p_delta": "\(delta)",
                    "p_reason": reason.rawValue,
                    "p_note": note ?? ""
                ])
                .execute()
                .value

            if let first = result.first {
                stock[first.material] = first.qty
            }

            await refresh()
        } catch {
            print("adjust error:", error)
        }
    }
}
