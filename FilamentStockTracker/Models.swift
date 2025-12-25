//
//  Models.swift
//  FilamentStockTracker
//
//  Created by Ozge Sevin Keskin on 25.12.2025.
//
import Foundation

enum MaterialType: String, CaseIterable, Identifiable, Codable, Hashable {
    case pp = "PP"
    case tpu = "TPU"
    case pla = "PLA"
    case abs = "ABS"
    case petg = "PETG"

    var id: String { rawValue }

    static var ordered: [MaterialType] { [.pp, .tpu, .pla, .abs, .petg] }

    var title: String { rawValue } // UI için

    var icon: String {
        switch self {
        case .pp: "cube.transparent"
        case .tpu: "drop"
        case .pla: "leaf"
        case .abs: "flame"
        case .petg: "shield"
        }
    }
}

enum StockReason: String, CaseIterable, Identifiable, Codable, Hashable {
    case `print` = "Baskı"   // ✅ UI’da .print diye kullanabil
    case fire = "Fire"
    case `return` = "İade"
    case other = "Diğer"

    var id: String { rawValue }
}

struct StockRow: Codable {
    let material: MaterialType
    let qty: Int
    let updated_at: String?
}

struct LogRow: Codable, Identifiable {
    let id: UUID
    let created_at: String?
    let material: MaterialType
    let delta: Int
    let reason: StockReason
    let note: String?
    let user_email: String
}

struct AdjustResult: Codable {
    let material: MaterialType
    let qty: Int
}

// created_at string -> Date (UI’da tarih/saat göstermek için)
extension LogRow {
    var date: Date? {
        guard let s = created_at else { return nil }
        // Supabase genelde ISO-8601 döndürür
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }
}
