//
//  ContentView.swift
//  FilamentStockTracker
//
//  Created by Ozge Sevin Keskin on 25.12.2025.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CloudInventoryStore
    @EnvironmentObject private var auth: AuthManager

    @State private var selection: MaterialType? = .pp
    @State private var showLowStockOnly = false

    @State private var showAdjustSheet = false
    @State private var adjustMode: AdjustMode = .add
    @State private var adjustMaterial: MaterialType = .pp
    @State private var adjustAmount: Int = 1
    @State private var adjustReason: StockReason = .print
    @State private var adjustNote: String = ""

    @State private var showSettings = false

    // Threshold’ları JSON olarak saklayalım
    @AppStorage("thresholds_json") private var thresholdsJSON: String = ""

    var body: some View {
        Group {
            if auth.session == nil {
                // Senin projende AuthView varsa onu göster
                AuthView()
            } else {
                main
            }
        }
        .task {
            guard auth.session != nil else { return }
            await store.refresh()
        }

    }

    private var main: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showSettings = true
                } label: {
                    Label("Ayarlar", systemImage: "gearshape")
                }

                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("Yenile", systemImage: "arrow.clockwise")
                }

                Spacer()

                Button {
                    adjustMode = .add
                    adjustMaterial = selection ?? .pp
                    adjustAmount = 1
                    adjustReason = .other
                    adjustNote = ""
                    showAdjustSheet = true
                } label: {
                    Label("Stok Ekle", systemImage: "plus.circle.fill")
                }

                Button {
                    adjustMode = .subtract
                    adjustMaterial = selection ?? .pp
                    adjustAmount = 1
                    adjustReason = .print
                    adjustNote = ""
                    showAdjustSheet = true
                } label: {
                    Label("Stok Düş", systemImage: "minus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAdjustSheet) {
            adjustSheet
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet
        }
        .frame(minWidth: 980, minHeight: 640)
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Filament Stok")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Toplam adet: \(totalQty)")
                .foregroundStyle(.secondary)

            Toggle("Sadece düşük stok", isOn: $showLowStockOnly)
                .toggleStyle(.switch)

            List(selection: $selection) {
                ForEach(filteredMaterials) { mat in
                    HStack(spacing: 10) {
                        Image(systemName: mat.icon)
                            .foregroundStyle(.secondary)
                        Text(mat.title)
                        Spacer()
                        let q = store.qty(mat)
                        Text("\(q)")
                            .monospacedDigit()
                            .foregroundStyle(q <= threshold(for: mat) ? .orange : .primary)
                    }
                    .tag(Optional(mat))
                }
            }
        }
        .padding()
    }

    private var filteredMaterials: [MaterialType] {
        if !showLowStockOnly { return MaterialType.ordered }
        return MaterialType.ordered.filter { store.qty($0) <= threshold(for: $0) }
    }

    private var totalQty: Int {
        store.stock.values.reduce(0, +)
    }

    // MARK: Detail

    private var detail: some View {
        Group {
            if let mat = selection {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(mat.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Eşik: \(threshold(for: mat)) • \(store.qty(mat) <= threshold(for: mat) ? "Düşük stok" : "OK")")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Stok")
                                .foregroundStyle(.secondary)
                            Text("\(store.qty(mat))")
                                .font(.system(size: 54, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                    }

                    Divider()

                    Text("İşlem Geçmişi")
                        .font(.title3)
                        .fontWeight(.semibold)

                    logTable(for: mat)
                        .frame(minHeight: 260)

                    Spacer()
                }
                .padding()
            } else {
                ContentUnavailableView("Bir malzeme seç", systemImage: "cube")
            }
        }
    }

    private func logTable(for mat: MaterialType) -> some View {
        let rows = store.log.filter { $0.material == mat }

        return Table(rows) {
            TableColumn("Tarih") { e in
                Text(e.date?.formatted(date: .abbreviated, time: .omitted) ?? "-")
                    .foregroundStyle(.secondary)
            }
            .width(110)

            TableColumn("Saat") { e in
                Text(e.date?.formatted(date: .omitted, time: .shortened) ?? "-")
                    .foregroundStyle(.secondary)
            }
            .width(80)

            TableColumn("Δ") { e in
                Text(e.delta >= 0 ? "+\(e.delta)" : "\(e.delta)")
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            .width(70)

            TableColumn("Neden") { e in
                Text(e.reason.rawValue)
            }
            .width(120)

            // ✅ KULLANICI (MAIL) KOLONU
            TableColumn("Kullanıcı") { e in
                Text(e.user_email)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .width(220)

            TableColumn("Not") { e in
                Text(e.note ?? "")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: Adjust Sheet

    enum AdjustMode { case add, subtract }

    private var adjustSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(adjustMode == .add ? "Stok Ekle" : "Stok Düş")
                    .font(.title2).fontWeight(.semibold)
                Spacer()
            }

            Form {
                Picker("Malzeme", selection: $adjustMaterial) {
                    ForEach(MaterialType.ordered) { m in
                        Text(m.title).tag(m)
                    }
                }

                Stepper(value: $adjustAmount, in: 1...999) {
                    Text("Adet: \(adjustAmount)")
                }

                if adjustMode == .subtract {
                    Picker("Neden", selection: $adjustReason) {
                        Text("Baskı").tag(StockReason.print)
                        Text("Fire").tag(StockReason.fire)
                        Text("İade").tag(StockReason.return)
                        Text("Diğer").tag(StockReason.other)
                    }
                }

                TextField("Not (opsiyonel)", text: $adjustNote)
            }

            HStack {
                Spacer()
                Button("İptal") { showAdjustSheet = false }
                Button("Kaydet") {
                    Task {
                        if adjustMode == .add {
                            await store.add(material: adjustMaterial, amount: adjustAmount, note: adjustNote.isEmpty ? nil : adjustNote)
                        } else {
                            await store.subtract(material: adjustMaterial, amount: adjustAmount, reason: adjustReason, note: adjustNote.isEmpty ? nil : adjustNote)
                        }
                        showAdjustSheet = false
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(width: 460)
    }

    // MARK: Settings Sheet (threshold)

    private var settingsSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ayarlar")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Düşük stok eşiğini malzeme bazında ayarla.")
                .foregroundStyle(.secondary)

            Form {
                ForEach(MaterialType.ordered) { m in
                    Stepper(value: bindingThreshold(for: m), in: 0...999) {
                        HStack {
                            Text(m.title)
                            Spacer()
                            Text("\(threshold(for: m))")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            Text("Developed by Özge Sevin Keskin • FITED")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Kapat") { showSettings = false }
            }
        }
        .padding(18)
        .frame(width: 520, height: 420)
    }

    // MARK: Threshold storage helpers

    private func threshold(for m: MaterialType) -> Int {
        let dict = decodeThresholds()
        return dict[m.rawValue] ?? 20 // default 20
    }

    private func bindingThreshold(for m: MaterialType) -> Binding<Int> {
        Binding(
            get: { threshold(for: m) },
            set: { newValue in
                var dict = decodeThresholds()
                dict[m.rawValue] = newValue
                encodeThresholds(dict)
            }
        )
    }

    private func decodeThresholds() -> [String: Int] {
        guard let data = thresholdsJSON.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
    }

    private func encodeThresholds(_ dict: [String: Int]) {
        if let data = try? JSONEncoder().encode(dict),
           let s = String(data: data, encoding: .utf8) {
            thresholdsJSON = s
        }
    }
}
