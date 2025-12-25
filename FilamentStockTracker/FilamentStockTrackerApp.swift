//
//  FilamentStockTrackerApp.swift
//  FilamentStockTracker
//
//  Created by Ozge Sevin Keskin on 25.12.2025.
//
import SwiftUI

@main
struct FilamentStockTrackerApp: App {
    @StateObject private var store = CloudInventoryStore()
    @StateObject private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(auth)
        }
    }
}
