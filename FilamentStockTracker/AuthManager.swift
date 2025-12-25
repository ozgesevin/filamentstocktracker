//
//  AuthManager.swift
//  FilamentStockTracker
//
//  Created by Ozge Sevin Keskin on 25.12.2025.
//
import Foundation
import Combine
import Supabase

@MainActor
final class AuthManager: ObservableObject {
    @Published var session: Session? = nil   // ✅ default değer

    var email: String? { session?.user.email }

    init() {} // ✅ artık AuthManager() çalışır

    func loadSession() async {
        // session varsa getir, yoksa nil bırak
        session = try? await supabase.auth.session
    }

    func sendCode(to email: String) async throws {
        try await supabase.auth.signInWithOTP(email: email)
    }

    func verify(email: String, code: String) async throws {
        try await supabase.auth.verifyOTP(email: email, token: code, type: .email)
        session = try await supabase.auth.session
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        session = nil
    }
}
