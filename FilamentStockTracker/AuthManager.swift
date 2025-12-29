//
//  AuthManager.swift
//  FilamentStockTracker
//

import Foundation
import Combine
import Supabase
import Auth

@MainActor
final class AuthManager: ObservableObject {

    @Published private(set) var session: Session? = nil
    @Published var lastError: String? = nil
    @Published var isLoading: Bool = false

    let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    var isSignedIn: Bool { session != nil }
    var userEmail: String? { session?.user.email }

    // MARK: - Session

    func restoreSession() async {
        do {
            session = try await client.auth.session
        } catch {
            session = nil
        }
    }

    // MARK: - OTP (6-digit)

    func sendCode(to email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        lastError = nil

        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard e.hasSuffix("@fited.co") else {
            throw NSError(
                domain: "Auth",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Lütfen @fited.co email kullan."]
            )
        }

        // Bu çağrı OTP üretir. Mailin 6 haneli "kod" göstermesi için
        // Supabase template'inde {{ .Token }} olmalı.
        try await client.auth.signInWithOTP(email: e)
    }

    func verifyCode(email: String, code: String) async throws {
        isLoading = true
        defer { isLoading = false }
        lastError = nil

        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let c = code.trimmingCharacters(in: .whitespacesAndNewlines)

        guard (6...8).contains(c.count) else {
            throw NSError(domain: "Auth", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Kod 6–8 haneli olmalı."
            ])
        }

        // Önce email OTP dene, olmazsa signup OTP dene
        do {
            _ = try await client.auth.verifyOTP(email: e, token: c, type: .email)
        } catch {
            _ = try await client.auth.verifyOTP(email: e, token: c, type: .signup)
        }

        self.session = try await client.auth.session
    }
    // MARK: - Sign out

    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        lastError = nil

        do {
            try await client.auth.signOut()
            session = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
