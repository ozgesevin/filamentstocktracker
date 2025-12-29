//
//  SupabaseService.swift
//  FilamentStockTracker
//
//  Created by Ozge Sevin Keskin on 25.12.2025.
//
import Foundation
import Supabase

enum SupabaseService {
    static let client = SupabaseClient(
        supabaseURL: Secrets.supabaseURL,
        supabaseKey: Secrets.supabaseAnonKey
    )
}
