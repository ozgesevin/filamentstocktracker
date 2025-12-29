import SwiftUI
import Auth
import Supabase

struct ContentView: View {
    @EnvironmentObject var store: CloudInventoryStore
    @EnvironmentObject var auth: AuthManager

    @State private var selectedMaterial: MaterialType = .pp
    @State private var amount: Int = 1
    @State private var reason: String = "Baskı"
    private let reasons = ["Print", "Faulty", "Scrap"]

    @State private var didBootstrap = false

    var body: some View {
        Group {
            if auth.isSignedIn {
                mainUI
            } else {
                AuthView()
            }
        }
        .task {
            // sadece 1 kere çalışsın
            guard !didBootstrap else { return }
            didBootstrap = true

            await auth.restoreSession()
            if auth.isSignedIn {
                await store.refresh()
            }
        }
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn {
                Task { await store.refresh() }
            }
        }
    }

    private var mainUI: some View {
        NavigationSplitView {
            List {
                Section("Stock") {
                    ForEach(MaterialType.allCases) { m in
                        HStack {
                            Text(m.rawValue)
                            Spacer()
                            Text("\(store.quantity(for: m))")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Settings") {
                    Stepper("Low stock ≤ \(store.lowStockThreshold)",
                            value: $store.lowStockThreshold,
                            in: 0...500)
                }
            }
            .navigationTitle("Filament")
        } detail: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Actions").font(.title2).bold()
                    Spacer()
                    Button("Refresh") { Task { await store.refresh() } }
                    Button("Sign out") { Task { await auth.signOut() } }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Material", selection: $selectedMaterial) {
                            ForEach(MaterialType.allCases) { Text($0.rawValue).tag($0) }
                        }

                        Stepper("Amount: \(amount)", value: $amount, in: 1...100)

                        HStack {
                            Button("Add Stock") {
                                Task {
                                    let email = auth.userEmail
                                    await store.addStock(material: selectedMaterial,
                                                         amount: amount,
                                                         userEmail: email)
                                }
                            }

                            Spacer()

                            Picker("Reason", selection: $reason) {
                                ForEach(reasons, id: \.self) { Text($0) }
                            }
                            .frame(width: 160)

                            Button("Reduce Stock") {
                                Task {
                                    let email = auth.userEmail
                                    await store.subtractStock(material: selectedMaterial,
                                                              amount: amount,
                                                              reason: reason,
                                                              userEmail: email)
                                }
                            }
                        }
                    }
                    .padding(6)
                } label: {
                    Text("Update stock")
                }

                GroupBox {
                    VStack(alignment: .leading) {
                        if store.logs.isEmpty {
                            Text("No logs yet").foregroundStyle(.secondary)
                        } else {
                            Table(store.logs) {
                                TableColumn("Time") { row in
                                    Text(row.created_at.formatted(date: .abbreviated, time: .shortened))
                                }.width(160)

                                TableColumn("Material") { row in Text(row.material) }.width(80)
                                TableColumn("Δ") { row in Text("\(row.delta)").monospacedDigit() }.width(60)
                                TableColumn("Reason") { row in Text(row.reason ?? "") }.width(120)
                                TableColumn("User") { row in Text(row.user_email ?? "") }
                            }
                            .frame(minHeight: 260)
                        }
                    }
                    .padding(6)
                } label: {
                    Text("Log")
                }

                Spacer()

                HStack {
                    Text("Developed by Özge Sevin Keskin")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let email = auth.userEmail {
                        Text(email).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("Dashboard")
            .task { await store.requestNotificationPermissionIfNeeded() }
        }
    }
}
