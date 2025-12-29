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
        VStack(spacing: 14) {
            Text("Filament Stock Tracker")
                .font(.title2)
                .bold()

            if phase == .enterEmail {
                TextField("company email (…@fited.co)", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .disabled(auth.isLoading)

                Button {
                    Task { await sendCode() }
                } label: {
                    if auth.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Send Code")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(auth.isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            } else {
                Text("Code sent to \(email)")
                    .foregroundStyle(.secondary)

                TextField("8-digit code", text: $code)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .disabled(auth.isLoading)
                    .onChange(of: code) { _, newValue in
                        let digitsOnly = newValue.filter { $0.isNumber }
                        code = String(digitsOnly.prefix(8))
                    }

                Button("Verify") {
                    Task {
                        do {
                            errorText = nil
                            try await auth.verifyCode(email: email, code: code)
                        } catch {
                            errorText = error.localizedDescription
                        }
                    }
                }
                .disabled(auth.isLoading || !(6...8).contains(code.count))


                Button("Back") {
                    phase = .enterEmail
                    code = ""
                    auth.lastError = nil
                }
                .buttonStyle(.link)
                .disabled(auth.isLoading)
            }

            if let err = auth.lastError, !err.isEmpty {
                Text(err)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
        }
        .padding(24)
        .frame(width: 420)
    }

    // MARK: - Actions

    private func sendCode() async {
        auth.lastError = nil
        do {
            try await auth.sendCode(to: email)
            phase = .enterCode
        } catch {
            // AuthManager zaten lastError set ediyor, ama garanti olsun diye:
            auth.lastError = error.localizedDescription
        }
    }

    private func verify() async {
        auth.lastError = nil
        do {
            try await auth.verifyCode(email: email, code: code)
            // session geldiyse ContentView route edecek; phase değiştirmen gerekmiyor.
        } catch {
            auth.lastError = error.localizedDescription
        }
    }
}
