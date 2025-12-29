//
//  Models.swift
//  FilamentStockTracker
//
//  Created by Ozge Sevin Keskin on 25.12.2025.
//
import Foundation

enum MaterialType: String, CaseIterable, Codable, Identifiable {
    case pp = "PP"
    case tpu = "TPU"
    case pla = "PLA"
    case abs = "ABS"
    case petg = "PETG"

    var id: String { rawValue }
}

struct StockRow: Codable, Identifiable, Hashable {
    // stock.material UNIQUE varsayımı → id olarak material kullanıyoruz
    var id: String { material }
    let material: String
    let quantity: Int
}

struct LogRow: Codable, Identifiable, Hashable {
    let id: UUID
    let created_at: Date
    let material: String
    let delta: Int
    let reason: String?
    let user_email: String?
}
