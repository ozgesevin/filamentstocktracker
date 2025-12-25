//
//  AuthView.swift
//  FilamentStockTracker
//
//  Created by Ozge Sevin Keskin on 25.12.2025.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var email = ""
    @State private var code = ""
    @State private var phase: Phase = .enterEmail
    @State private var errorText: String?

    enum Phase { case enterEmail, enterCode }

    var body: some View {
        VStack(spacing: 12) {
            Text("Filament Stock Tracker").font(.title2).bold()

            if phase == .enterEmail {
                TextField("company email (…@fited.co)", text: $email)
                    .textFieldStyle(.roundedBorder)

                Button("Send Code") {
                    Task {
                        do {
                            errorText = nil
                            try await auth.sendCode(to: email)
                            phase = .enterCode
                        } catch { errorText = error.localizedDescription }
                    }
                }
                .keyboardShortcut(.defaultAction)
            } else {
                Text("Code sent to \(email)").foregroundStyle(.secondary)
                TextField("6-digit code", text: $code)
                    .textFieldStyle(.roundedBorder)

                Button("Verify") {
                    Task {
                        do {
                            errorText = nil
                            try await auth.verify(email: email, code: code)
                        } catch { errorText = error.localizedDescription }
                    }
                }
                .keyboardShortcut(.defaultAction)

                Button("Back") { phase = .enterEmail; code = "" }
                    .buttonStyle(.link)
            }

            if let errorText {
                Text(errorText).foregroundStyle(.red).font(.footnote)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
