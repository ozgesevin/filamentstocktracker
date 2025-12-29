import SwiftUI
import Combine

@main
struct FilamentStockTrackerApp: App {
    @StateObject private var auth: AuthManager
    @StateObject private var store: CloudInventoryStore

    init() {
        let client = SupabaseService.client
        _auth = StateObject(wrappedValue: AuthManager(client: client))
        _store = StateObject(wrappedValue: CloudInventoryStore(client: client))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(auth)
        }
    }
}
