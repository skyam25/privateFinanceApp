# Project Canvas: "GhostVault" (Working Title)

**Concept:** A "Local-First" Net Worth & Spend Tracker
**Core Promise:** The automation of Mint with the privacy of a spreadsheet.

---

## 1. Executive Summary

**The Problem:** Users are forced to choose between **convenience** (selling their data to cloud apps like Mint/Monarch) or **privacy** (laborious manual entry in spreadsheets/GnuCash).

**The Solution:** A mobile app that acts as a secure "viewer" for your finances. It uses a paid bridge (SimpleFIN) to fetch data but stores 100% of that data in the user's private iCloud container. The developer never sees a single transaction.

---

## 2. Competitive Landscape

The market is polarized. GhostVault targets the "Hybrid" gap.

| Category | Leaders | Pros | Cons |
| :--- | :--- | :--- | :--- |
| **Cloud Aggregators** | Monarch, Copilot, Rocket Money | Easy setup, polished UI. | Privacy nightmare. Data is mined/sold. Subscription fatigue. |
| **Hardcore Privacy** | GnuCash, Excel | Zero data leakage. Free. | High friction. Ugly UI. Manual entry required. |
| **Self-Hosted** | Actual Budget, Firefly III | Private & Automated. | High technical barrier (requires server/Docker). |
| **GhostVault Niche** | **GhostVault** | **Private AND Automated. No server required.** | Relies on "Bring Your Own Key" (SimpleFIN). |

---

## 3. Technical Architecture

**Philosophy:** "The app is just a lens; the data is yours."

### Data Layer

| Component | Technology | Notes |
|-----------|------------|-------|
| **Local Database** | SwiftData (SQLite) | Native Apple framework with CloudKit integration |
| **Sync Engine** | Apple CloudKit | Private container, encrypted by Apple, free for developers |
| **Encryption** | iOS Data Protection | Hardware-backed encryption when device is locked |
| **Secure Storage** | iOS Keychain | For SimpleFIN access token |

### Integration Layer (The Bridge)

| Component | Details |
|-----------|---------|
| **Provider** | SimpleFIN Bridge |
| **Protocol** | Read-only HTTPS API |
| **Data Flow** | Bank → MX/Plaid (via SimpleFIN) → SimpleFIN Server → **User's Device** |

**Crucial:** The data **never** touches the developer's server. It goes straight from SimpleFIN API to the user's iPhone.

---

## 4. UX Strategy: "The Trust Flow"

Since we cannot white-label SimpleFIN, we turn the friction into a feature.

### The Onboarding "Handshake"

1. **The Pitch:** "We don't want your bank password. We use a secure bridge called SimpleFIN."

2. **The Handoff:**
   - Button: `Get Secure Key ($15/yr)` → Opens SFSafariViewController to SimpleFIN.org
   - *User Action:* User signs up, connects banks on SimpleFIN's site
   - *User Action:* User copies the "Setup Token"

3. **The Return:**
   - User closes Safari view
   - App detects token on clipboard (or user presses "Paste Token")
   - **Success:** "Connected! Downloading 12 months of history..."

---

## 5. Business Model: "Bring Your Own Key"

Avoid reselling the data feed. It lowers liability and increases trust.

### Revenue Stream

| Item | Price | Notes |
|------|-------|-------|
| **App Price** | $24.99/year OR $49.99 lifetime | Subscription or one-time purchase |
| **Data Cost** | $0 to developer | User pays SimpleFIN $15/year directly |
| **Total Cost to User** | ~$40/year | Cheaper than Monarch's $100/year |

### Marketing Angle

> *"We charge for the software, not the data. By paying SimpleFIN directly, you ensure that WE (the app developers) are never the middleman for your banking credentials."*

---

## 6. MVP Roadmap (Phase 1)

Focus on "Net Worth" first, "Budgeting" second.

### MVP Features

#### 1. The Dashboard
- [ ] Total Net Worth card (Assets - Liabilities)
- [ ] "Safe to Spend" daily number (Income - Fixed Costs)
- [ ] Last sync timestamp and manual refresh

#### 2. Account Management
- [ ] List of all connected accounts
- [ ] Account balance and type display
- [ ] Group by institution

#### 3. Transaction Feed
- [ ] Unified transaction list from all SimpleFIN accounts
- [ ] Search and filter functionality
- [ ] Basic auto-categorization (Regex rules stored locally)

#### 4. Settings & Connection
- [ ] SimpleFIN token entry flow
- [ ] Connection status display
- [ ] Disconnect/reconnect capability

### Future Phases

#### Phase 2: Enhanced Tracking
- [ ] Asset Classes
  - Real Estate (Zillow API or Manual Estimate)
  - Vehicles (Manual Depreciation curve)
  - Crypto/Stocks (Public API for pricing)
- [ ] Spending trends and charts
- [ ] Monthly reports

#### Phase 3: Budgeting
- [ ] Budget categories
- [ ] Spending limits
- [ ] Alerts and notifications

#### Phase 4: Advanced Features
- [ ] Export to CSV/JSON
- [ ] Recurring transaction detection
- [ ] Bill reminders
- [ ] Multi-currency support

---

## 7. Technical Decisions

### Platform Choice: Native iOS (Swift/SwiftUI)

**Rationale:**
- CloudKit integration is seamless with native development
- No server required for sync
- SwiftData provides automatic CloudKit sync
- Better security integration (Keychain, Face ID)

**Trade-off:** No Android support initially. Cross-platform (React Native/Flutter) would lose the "No Server" promise due to lack of CloudKit support.

### Data Model

```swift
// Core Models
Account {
    id: String (SimpleFIN ID)
    name: String
    type: AccountType (checking, savings, credit, investment, loan)
    balance: Decimal
    currency: String
    organization: String
    lastSynced: Date
}

Transaction {
    id: String (SimpleFIN ID)
    accountId: String
    amount: Decimal
    description: String
    payee: String?
    posted: Date
    pending: Bool
    category: String?
}

Category {
    id: UUID
    name: String
    icon: String
    rules: [CategoryRule]
}

CategoryRule {
    pattern: String (regex)
    field: description | payee | memo
}
```

### Security Considerations

1. **Access Token Storage:** iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
2. **Data at Rest:** Protected by iOS Data Protection (encrypted when locked)
3. **Network:** All API calls over HTTPS
4. **No Logging:** Never log transaction data or access tokens

---

## 8. Success Metrics

### MVP Success Criteria
- [ ] User can connect SimpleFIN and see accounts
- [ ] Transactions sync successfully
- [ ] Data persists across app restarts
- [ ] Data syncs across devices via iCloud

### Key Performance Indicators
- User retention at 30 days
- Average session duration
- Sync success rate
- App Store rating

---

## 9. Open Questions

1. **Pricing Model:** Subscription vs. one-time purchase vs. freemium?
2. **App Name:** "GhostVault" or something else?
3. **Asset Tracking:** Include manual assets (real estate, vehicles) in MVP or Phase 2?
4. **Widgets:** iOS home screen widgets for net worth display?
5. **Mac App:** Universal app with Mac Catalyst or dedicated macOS app?

---

## 10. Resources

### SimpleFIN
- [SimpleFIN Bridge](https://bridge.simplefin.org/)
- [Developer Guide](https://bridge.simplefin.org/info/developers)
- [Protocol Specification](https://www.simplefin.org/protocol.html)

### Apple Technologies
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)

---

## Appendix A: SimpleFIN API Quick Reference

### Token Exchange
```bash
# Decode setup token and claim access URL
CLAIM_URL=$(echo "$SETUP_TOKEN" | base64 --decode)
ACCESS_URL=$(curl -X POST "$CLAIM_URL")
```

### Fetch Accounts
```bash
# GET with Basic Auth
curl "${ACCESS_URL}/accounts"
```

### Rate Limits
- 24 requests per day
- 60-day date range limit
- Warnings appear in `errors` array

### Response Structure
```json
{
  "errors": [],
  "accounts": [{
    "id": "...",
    "name": "Checking",
    "balance": "1234.56",
    "transactions": [...]
  }]
}
```
