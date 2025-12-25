cat > README.md <<'EOF'
# Filament Stock Tracker (FITED)

macOS desktop app to track filament spool stock with shared cloud state (Supabase) and audit log.

## Features
- Materials: PP, TPU, PLA, ABS, PETG
- Add / subtract stock with reason (Baskı / Fire / İade / Diğer)
- Audit log shows user email (who did what)
- Company login (example: *@fited.co*)

## Requirements
- Xcode 26+
- macOS 26+
- Supabase project (DB + Auth)

## Setup (Supabase)
Create tables:
- `stock`
- `stock_log`
Create RPC:
- `adjust_stock`

Enable Row Level Security + policies to restrict to company users.

## Local Setup
1) Clone
2) Open `FilamentStockTracker.xcodeproj`
3) Create a `Secrets.swift` file **locally** (NOT committed):

```swift
import Foundation

enum Secrets {
  static let supabaseURL = URL(string: "https://YOUR_PROJECT.supabase.co")!
  static let supabaseAnonKey = "YOUR_ANON_KEY"
}

