# GhostVault

**A Local-First Private Finance Tracker for iOS**

> The automation of Mint with the privacy of a spreadsheet.

## Overview

GhostVault is a mobile app that acts as a secure "viewer" for your finances. It uses SimpleFIN Bridge to fetch your financial data but stores 100% of that data locally on your device and in your private iCloud container. The developer never sees a single transaction.

## Core Features

- **100% Local-First**: All data stored on-device and in your private iCloud
- **SimpleFIN Integration**: Connect to 10,000+ financial institutions via SimpleFIN Bridge
- **No Bank Passwords**: We never see or store your bank credentials
- **Net Worth Tracking**: Unified view of all accounts
- **Transaction Feed**: Unified transaction list with auto-categorization
- **Privacy by Design**: Zero analytics, zero data collection, zero cloud servers

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Apple Developer Account (for CloudKit)
- SimpleFIN Bridge account ($15/year) - [Get one here](https://bridge.simplefin.org/simplefin/create)

### Setup

1. Clone this repository
2. Open `GhostVault.xcodeproj` in Xcode
3. Update the bundle identifier and team in project settings
4. Enable CloudKit capability and create your iCloud container
5. Build and run

---

# SimpleFIN Bridge Developer Guide

This section documents the SimpleFIN Bridge API for developers.

## Overview

SimpleFIN Bridge provides read-only access to a user's financial data. Your application never sees the user's bank account credentials.

### Authentication Flow

1. User gets a **Setup Token** from SimpleFIN
2. User provides the Setup Token to your app
3. App exchanges Setup Token for an **Access Token** (one-time operation)
4. App uses Access Token to fetch financial data
5. User can disable Access Token at any time

## API Reference

### Step 1: Generate a Setup Token

Send users to: https://bridge.simplefin.org/simplefin/create

The user will:
1. Sign up for SimpleFIN ($15/year)
2. Connect their bank accounts
3. Receive a Setup Token (base64-encoded string)

### Step 2: Exchange Setup Token for Access Token

The Setup Token is a base64-encoded URL. Decode it to get the claim URL, then POST to it:

```bash
SETUP_TOKEN='<base64-encoded-token>'
CLAIM_URL="$(echo "$SETUP_TOKEN" | base64 --decode)"
ACCESS_URL=$(curl -H "Content-Length: 0" -X POST "$CLAIM_URL")
```

**Important**: This can only be done **once**. Save the `ACCESS_URL` - the Setup Token becomes invalid after claiming.

### Step 3: Fetch Account Data

Make an HTTP GET request to `{ACCESS_URL}/accounts`:

```bash
curl -L "${ACCESS_URL}/accounts"
```

The ACCESS_URL includes Basic Auth credentials in the format:
```
https://username:password@api.simplefin.org/simplefin
```

### Query Parameters

| Parameter | Description |
|-----------|-------------|
| `start-date` | Unix timestamp. Only return transactions on or after this date |
| `end-date` | Unix timestamp. Only return transactions before this date |
| `account` | Account ID. Fetch only this specific account |

### Response Format

```json
{
  "errors": [],
  "accounts": [
    {
      "id": "account-id",
      "org": {
        "sfin_url": "https://...",
        "name": "Bank Name",
        "domain": "bank.com",
        "url": "https://bank.com"
      },
      "name": "Checking Account",
      "currency": "USD",
      "balance": "1234.56",
      "available_balance": "1200.00",
      "balance_date": 1704067200,
      "transactions": [
        {
          "id": "transaction-id",
          "posted": 1704067200,
          "amount": "-50.00",
          "description": "GROCERY STORE",
          "payee": "Grocery Store",
          "memo": "",
          "pending": false
        }
      ]
    }
  ]
}
```

### Rate Limits

- **24 requests per day** per Access Token
- Date range limited to **60 days** per request
- Exceeding limits will show warnings in the `errors` array
- Persistent rate limit violations will disable Access Tokens

### Error Handling

Always check the `errors` array in responses and surface them to users:

```json
{
  "errors": ["Rate limit warning: You are making more requests than expected."],
  "accounts": [...]
}
```

## Swift Implementation Example

```swift
import Foundation

actor SimpleFINService {
    /// Exchange setup token for access URL
    func claimSetupToken(_ setupToken: String) async throws -> String {
        // Base64 decode to get claim URL
        guard let data = Data(base64Encoded: setupToken),
              let claimURL = String(data: data, encoding: .utf8),
              let url = URL(string: claimURL) else {
            throw SimpleFINError.invalidSetupToken
        }

        // POST to claim URL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("0", forHTTPHeaderField: "Content-Length")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let accessURL = String(data: data, encoding: .utf8) else {
            throw SimpleFINError.invalidResponse
        }

        return accessURL
    }

    /// Fetch accounts using access URL
    func fetchAccounts(accessURL: String) async throws -> AccountSet {
        // Parse access URL: https://user:pass@host/path
        guard let url = URL(string: accessURL),
              let user = url.user,
              let pass = url.password,
              let host = url.host else {
            throw SimpleFINError.invalidAccessURL
        }

        // Build accounts URL without credentials
        let accountsURL = URL(string: "https://\(host)\(url.path)/accounts")!

        var request = URLRequest(url: accountsURL)
        let auth = "\(user):\(pass)".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AccountSet.self, from: data)
    }
}
```

## Python Implementation Example

```python
import requests
import base64

# 1. Get Setup Token from user
setup_token = input('Setup Token? ')

# 2. Claim Access URL
claim_url = base64.b64decode(setup_token).decode('utf-8')
response = requests.post(claim_url)
access_url = response.text

# 3. Fetch accounts
from urllib.parse import urlparse
parsed = urlparse(access_url)
username = parsed.username
password = parsed.password
url = f"{parsed.scheme}://{parsed.hostname}{parsed.path}/accounts"

response = requests.get(url, auth=(username, password))
data = response.json()

for account in data['accounts']:
    print(f"{account['name']}: ${account['balance']}")
```

## Resources

- [SimpleFIN Bridge](https://bridge.simplefin.org/)
- [SimpleFIN Protocol Specification](https://www.simplefin.org/protocol.html)
- [Developer Guide](https://bridge.simplefin.org/info/developers)

---

## Project Structure

```
GhostVault/
├── App/
│   ├── GhostVaultApp.swift      # App entry point
│   └── ContentView.swift         # Main navigation
├── Views/
│   ├── Dashboard/                # Net worth & overview
│   ├── Accounts/                 # Account list
│   ├── Transactions/             # Transaction feed
│   ├── Settings/                 # Settings & SimpleFIN connection
│   ├── Onboarding/               # First-run experience
│   └── Components/               # Reusable UI components
├── Models/
│   ├── Account.swift             # Account data model
│   ├── Transaction.swift         # Transaction data model
│   ├── Organization.swift        # Financial institution model
│   └── Category.swift            # Category & rules model
├── Services/
│   ├── SimpleFIN/
│   │   ├── SimpleFINService.swift    # API client
│   │   └── SimpleFINModels.swift     # API response models
│   ├── Storage/
│   │   └── KeychainService.swift     # Secure token storage
│   └── Sync/
│       └── CloudKitService.swift     # iCloud sync
├── Utilities/
└── Resources/
    └── Assets.xcassets
```

## Architecture

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Local persistence with CloudKit sync
- **CloudKit** - Private iCloud container for cross-device sync
- **Keychain** - Secure storage for SimpleFIN access token

## Privacy

GhostVault is designed with privacy as a core principle:

- No analytics or tracking
- No data collection
- No cloud servers owned by the developer
- Data flows: Bank → SimpleFIN → Your Device (never through us)
- SimpleFIN access token stored in iOS Keychain
- All financial data stored in your private iCloud container

## License

[TBD]
