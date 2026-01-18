# Project Canvas: "GhostVault" (Working Title)

**Concept:** A simple, private net worth and income tracker
**Core Promise:** See your net worth and monthly income at a glance, with complete privacy.

---

## 1. Executive Summary

**The Problem:** Users want a simple way to see their net worth and monthly income without complex budgeting tools or giving up their financial privacy.

**The Solution:** A focused mobile app that connects to your bank accounts via SimpleFIN and shows you two key numbers: your **net worth** and your **net monthly income**. All data stays on your device and in your private iCloud container.

**Core Requirement:** SimpleFIN connection is mandatory. This app requires a SimpleFIN subscription to function.

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

## 4. UX Strategy: Streamlined Onboarding

SimpleFIN is required to use this app. The onboarding flow guides users through setup quickly.

### Onboarding Flow

**Step 1: Welcome**
- Brief intro to GhostVault
- Explain that SimpleFIN connection is required
- "Get Started" button

**Step 2: SimpleFIN Setup**
- Explain what SimpleFIN is (secure bank connection bridge)
- Two paths:
  - "I have a SimpleFIN token" → Go to token entry
  - "I need a SimpleFIN account" → Open SimpleFIN.org in browser
- Token entry field with paste support
- Validate and claim token
- **Success:** "Connected! Syncing your accounts..."

**Step 3: Account Setup**
- Display list of accounts found from SimpleFIN
- User can see account names, types, and balances
- Option to hide/exclude accounts from totals
- "Continue to Dashboard" button

**Step 4: Dashboard**
- User lands on main dashboard showing:
  - **Net Worth** (total assets minus liabilities)
  - **Net Monthly Income** (income minus expenses for current month)

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

Keep it simple. Focus on two key metrics: **Net Worth** and **Net Monthly Income**.

### MVP Features

#### 1. Onboarding Flow
- [ ] Welcome screen explaining SimpleFIN requirement
- [ ] SimpleFIN token entry with validation
- [ ] Account discovery and setup
- [ ] Smooth transition to dashboard

#### 2. The Dashboard (Primary Focus)
- [ ] **Net Worth** - Total assets minus liabilities, prominently displayed
- [ ] **Net Monthly Income** - Income minus expenses for current month
- [ ] Last sync timestamp
- [ ] Manual refresh button

#### 3. Account Management
- [ ] List of all connected accounts from SimpleFIN
- [ ] Account balance and type display
- [ ] Ability to hide/exclude accounts from calculations

#### 4. Transaction View
- [ ] Simple transaction list from all accounts
- [ ] Basic search functionality

#### 5. Settings
- [ ] SimpleFIN connection status
- [ ] Reconnect/update token capability

### Future Phases (Post-MVP)

#### Phase 2: Enhanced Views
- [ ] Monthly income/expense trends
- [ ] Account grouping by institution
- [ ] Transaction categorization

#### Phase 3: Additional Features
- [ ] Manual asset tracking (real estate, vehicles)
- [ ] Export functionality
- [ ] Spending insights

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
- [ ] User can complete SimpleFIN onboarding in under 5 minutes
- [ ] Net worth displays correctly (assets - liabilities)
- [ ] Net monthly income calculates correctly (income - expenses)
- [ ] Accounts sync successfully from SimpleFIN
- [ ] Data persists across app restarts
- [ ] Data syncs across devices via iCloud

### Key Performance Indicators
- Onboarding completion rate
- Daily active users checking net worth
- Sync success rate
- App Store rating

---

## 9. Open Questions

1. **Pricing Model:** Subscription vs. one-time purchase?
2. **App Name:** "GhostVault" or something else?
3. **Widgets:** iOS home screen widgets for net worth display in future phase?

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
