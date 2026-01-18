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

## 4. Sync Strategy

### Background Sync

| Trigger | Behavior |
|---------|----------|
| **iOS Background App Refresh** | Once daily automatic sync |
| **App Foreground** | Sync if >4 hours since last sync |
| **Manual Refresh** | Always available (with rate limit awareness) |

### Rate Limit Handling

SimpleFIN allows 24 requests per day. The app manages this intelligently:

| Threshold | Action |
|-----------|--------|
| **0-19 requests** | Normal operation |
| **20 requests** | Warning shown to user |
| **23 requests** | Block auto-sync, preserve 1 for manual |
| **24 requests** | Hard limit reached, wait for reset |

**Implementation:**
- Track daily request count locally
- Reset count at midnight UTC
- Display remaining requests in Settings
- Block auto-sync at 23 requests to preserve emergency manual refresh

### Multi-Device Sync

When user installs on a second device:

| Scenario | Behavior |
|----------|----------|
| **Fresh Install** | App detects existing CloudKit data, skips onboarding, downloads all data |
| **Data Conflict** | CloudKit handles merge; most recent write wins for user settings |
| **Token Storage** | SimpleFIN token syncs via CloudKit (encrypted), not Keychain |
| **Request Count** | Shared via CloudKit to prevent double-counting across devices |

**First Launch on Second Device:**
1. Check for existing CloudKit container data
2. If found: "Welcome back! Syncing your data..." → Download accounts, transactions, rules
3. Skip SimpleFIN setup (token already available)
4. Land on Dashboard with existing data

---

## 5. UX Strategy: Streamlined Onboarding

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
  - "I need a SimpleFIN account" → **In-app webview** to SimpleFIN.org (keeps user in app)
- In-app webview flow:
  - User completes SimpleFIN signup and bank linking within webview
  - Webview monitors for setup token in URL/page content
  - Auto-extract token when available, or prompt user to copy/paste
  - Dismiss webview and proceed to token validation
- Token entry field with paste support (fallback)
- Validate and claim token
- **Success:** "Connected! Syncing your accounts..."

**Step 3: Account Setup**
- Display list of accounts found from SimpleFIN
- User can see account names, types, and balances
- Option to hide/exclude accounts from totals
- "Continue" button

**Step 4: Initial Classification Review**
- Show transactions from the past month after accounts sync
- Highlight auto-detected patterns:
  - Paychecks (detected via PAYROLL, DIRECT DEP, etc.)
  - Transfers (matched amounts across accounts)
  - Credit card payments (payments to linked credit cards)
- User can confirm or adjust classifications
- "Apply to all from [payee]" option for bulk corrections
- "Continue to Dashboard" button

**Step 5: Dashboard**
- User lands on main dashboard showing:
  - **Net Worth** (total assets minus liabilities)
  - **Net Monthly Income** (income minus expenses for current month)

---

## 6. Business Model: "Bring Your Own Key"

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

## 7. MVP Roadmap (Phase 1)

Keep it simple. Focus on two key metrics: **Net Worth** and **Net Monthly Income**.

### MVP Features

#### 1. Onboarding Flow
- [ ] Welcome screen explaining SimpleFIN requirement
- [ ] SimpleFIN token entry with validation
- [ ] Account discovery and setup
- [ ] Initial classification review (Step 4 from onboarding)
- [ ] Smooth transition to dashboard

#### 2. The Dashboard (Primary Focus)
- [ ] **Net Worth Card**
  - Large number display of total net worth
  - **Delta indicator**: "+$1,234 (↑2.3%) this month" with green/red coloring
  - Tap to expand assets vs liabilities breakdown
  - Tap-through to Net Worth trend chart
- [ ] **Net Monthly Income Card**
  - Large number display of net income for selected month
  - **Month selector**: Swipe or tap arrows to navigate months (← Jan 2025 →)
  - Income and expense breakdown below (e.g., "$8,500 in · $7,200 out")
  - Tap-through to detailed transaction view for that month
- [ ] **Sync Status Bar**
  - Last sync timestamp
  - Pull-to-refresh gesture (standard iOS pattern)
  - "Sync Now" button with loading state
  - Remaining daily syncs indicator (subtle: "22/24")

#### 3. Trend Charts
- [ ] **Net Worth Line Chart**
  - Daily data points (or per-sync snapshots)
  - Timeframe selector: 1M, 3M, YTD, 1Y, Custom
  - Custom date picker for flexible date ranges
- [ ] **Net Monthly Income Bar Chart** (toggle between two views)
  - View 1: Income vs Expenses - Side-by-side bars per month
  - View 2: Net Income - Single bar per month (green = positive, red = negative)
  - Same timeframe selectors as Net Worth chart
- [ ] Store historical snapshots for chart data (DailySnapshot, MonthlySnapshot)

#### 4. Account Management
- [ ] **Account List View**
  - All connected accounts grouped by institution
  - Balance and account type for each
  - Visual indicator for assets (green) vs liabilities (red)
  - Drag-to-reorder accounts within groups
- [ ] **Account Detail View** (tap into any account)
  - Account balance with delta since last sync
  - Mini balance trend chart (sparkline)
  - Transaction list for that account only
  - Account settings (nickname, hide/show)
- [ ] **Account Customization**
  - Custom nicknames (rename "CHECKING ...4829" to "Main Checking")
  - Hide/exclude from net worth calculations
  - Mark as "tracking only" (visible but excluded from totals)

#### 5. Transaction View
- [ ] **Transaction List**
  - Chronological list with date headers
  - Classification labels (income/expense/transfer/ignore) as colored badges
  - Visual indicator showing classification reason (rule name, "Auto-detected", or "Default")
  - **Pending transactions** shown with dashed border/opacity, grouped at top
- [ ] **Transaction Detail Sheet** (tap any transaction)
  - Full payee name and description
  - Amount, date, account
  - Current classification with change option
  - "Apply to all from [payee]" toggle when changing
  - "Ignore this transaction" option
- [ ] **Search & Filter**
  - Search by payee, description, or amount
  - Filter by: account, classification, date range
  - Quick filters: "This month", "Last month", "Income only", "Expenses only"

#### 6. Spending Categories
- [ ] **Category Breakdown View** (accessible from Net Monthly Income card)
  - Donut/pie chart showing expense distribution
  - List view sorted by amount (highest first)
  - Categories: Dining, Shopping, Groceries, Transportation, Entertainment, Bills, Healthcare, Other
- [ ] **Auto-Categorization**
  - Pattern matching on payee names (similar to income detection)
  - Common merchant mapping (e.g., "UBER EATS" → Dining, "SHELL" → Transportation)
  - User corrections create persistent rules
- [ ] **Category Detail**
  - Tap category to see all transactions in that category
  - Month-over-month comparison ("Dining: $450 vs $380 last month")

#### 7. Settings
- [ ] SimpleFIN connection status
- [ ] Reconnect/update token capability
- [ ] Daily sync request counter (X/24 remaining)
- [ ] **Transaction Rules Management**
  - View all payee-based rules
  - Edit/delete existing rules
  - See which rules are auto-generated vs user-created
  - Toggle auto-generated rules on/off

#### 8. Error & Empty States
- [ ] **First Launch (No Data)**
  - Welcoming empty state with clear CTA to complete SimpleFIN setup
  - Progress indicator showing onboarding steps
- [ ] **Sync in Progress**
  - Loading skeleton UI while fetching data
  - "Syncing accounts..." with progress indication
- [ ] **Sync Errors**
  - SimpleFIN unreachable: "Couldn't connect. Check your internet and try again."
  - Token expired: "Your SimpleFIN connection needs to be refreshed." → Re-auth flow
  - Rate limited: "Daily sync limit reached. Resets at midnight."
- [ ] **Account Connection Issues**
  - Bank connection stale in SimpleFIN: Guide user to SimpleFIN dashboard to fix
  - Partial sync (some accounts failed): Show which accounts have issues
- [ ] **No Transactions for Period**
  - "No transactions this month" with suggestion to check date range

### Future Phases (Post-MVP)

#### Phase 2: Smart Analysis
- [ ] **50/30/20 Smart Lens** - Analytical overlay for spending balance
  - Toggle on Dashboard to transform Income vs Expenses view
  - Auto-categorize into Needs (50%), Wants (30%), Savings/Debt (20%)
  - Visual indicator when ratios are off-balance
- [ ] **Recurring Payment Detector** - Subscription and fixed cost monitor
  - Pattern matching for 28-31 day intervals
  - Next charge date prediction
  - Total monthly recurring cost summary
- [ ] Account grouping by institution
- [ ] Transaction categorization (beyond income/expense/transfer)

#### Phase 3: Additional Features
- [ ] Manual asset tracking (real estate, vehicles)
- [ ] Export functionality (CSV, PDF reports)
- [ ] Spending insights and budgeting

#### Phase 4: Ghost-Safe LLM Export (iOS 26+)
- [ ] **Anonymized Financial Export** - Create "Context-Rich, Identity-Poor" documents
  - Account name anonymization (e.g., "Chase Sapphire ...4829" → "Liability_A (Credit Card)")
  - Payee scrubbing (e.g., "Shell Gas Station #492" → "Category: Fuel/Transportation")
  - Relative date conversion (e.g., "2024-01-15" → "Month 1, Day 15" or "T-Minus 14 Days")
  - Optional precision scaling (e.g., $1,245.67 → $1,250)
- [ ] **On-Device AI Processing** via Apple Intelligence Foundation Models
  - Structured generation with `@Generable` for anonymized report output
  - Local narrative summarization (financial trends without PII)
  - Semantic search for manual review/filtering before export
- [ ] Export formats: Markdown, JSON

---

## 8. Business Logic

This section documents the calculation rules and classification logic used throughout the app.

### Net Worth Calculation

```
Net Worth = Sum(Asset Accounts) - Sum(Liability Accounts)
```

| Account Type | Classification |
|--------------|----------------|
| Checking | Asset |
| Savings | Asset |
| Investment | Asset |
| Brokerage | Asset |
| Credit Card | Liability |
| Loan | Liability |
| Mortgage | Liability |

**Notes:**
- Investment accounts use SimpleFIN-reported balances
- No distinction between "liquid" vs "total" net worth for MVP

### Net Monthly Income Calculation

```
Net Monthly Income = Sum(Income) - Sum(Expenses)
```

**Where:**
- **Income** = Positive transactions NOT classified as transfers
- **Expenses** = Negative transactions NOT classified as (transfers OR credit card payments)
- **Period** = Calendar month (Jan 1-31, Feb 1-28, etc.)

**Credit Card Payment Handling:**
- Exclude CC payments from Net Monthly Income (treat as internal transfers)
- The original purchases on the credit card already counted as expenses when posted

### Transfer Detection Logic

Transactions are auto-detected as transfers when ALL conditions are met:

| Condition | Requirement |
|-----------|-------------|
| Amount Match | Two transactions with equal and opposite amounts |
| Time Window | Within 3 calendar days of each other |
| Account Scope | Across different accounts |
| Status | Neither transaction is pending |

**User Override:**
- Users can manually mark any transaction as a transfer
- Manual markings create a persistent payee rule

### Transaction Classification Rules

Classifications are applied in priority order (first match wins):

| Priority | Rule Type | Description |
|----------|-----------|-------------|
| 1 | User-defined payee rules | Highest priority - user corrections persist |
| 2 | User manual override | Single transaction override |
| 3 | Auto-detected transfers | Matched amount pairs across accounts |
| 4 | Auto-detected CC payments | Payments to linked credit cards |
| 5 | Pattern-based income detection | Regex matching (see below) |
| 6 | Default | positive = income, negative = expense |

### Income Pattern Detection

Auto-detect income transactions using these patterns (case-insensitive):

```
PAYROLL
DIRECT DEP
DIR DEP
DIRECT DEPOSIT
EMPLOYER.*DEPOSIT
SALARY
WAGE
ACH.*PAYROLL
```

**Transparency:**
- Show users which rule matched each transaction
- Display as "Matched: [rule name]" or "Default" in transaction view

### Classification Enum

Transactions can be classified as:

| Classification | Description | Counted In |
|----------------|-------------|------------|
| `income` | Money received | Net Monthly Income (positive) |
| `expense` | Money spent | Net Monthly Income (negative) |
| `transfer` | Movement between own accounts | Neither (excluded) |
| `ignore` | User wants to exclude | Neither (excluded) |

### Spending Category System

Expenses are further categorized to answer "where did my money go?"

#### Category Enum

| Category | Description | Example Merchants |
|----------|-------------|-------------------|
| `dining` | Restaurants, food delivery, coffee | Starbucks, DoorDash, Chipotle |
| `groceries` | Supermarkets, food stores | Safeway, Whole Foods, Trader Joe's |
| `transportation` | Gas, rideshare, parking, transit | Shell, Uber, BART |
| `shopping` | Retail, online shopping | Amazon, Target, Apple |
| `entertainment` | Movies, games, events, streaming | Netflix, AMC, Spotify |
| `bills` | Utilities, phone, internet | PG&E, Verizon, Comcast |
| `healthcare` | Medical, pharmacy, fitness | CVS, Kaiser, Planet Fitness |
| `travel` | Hotels, flights, vacation | Marriott, United, Airbnb |
| `other` | Uncategorized expenses | Default bucket |

#### Auto-Categorization Patterns

```
Dining:
- *DOORDASH*, *UBER EATS*, *GRUBHUB* → Dining
- *STARBUCKS*, *COFFEE*, *CAFE* → Dining
- *RESTAURANT*, *GRILL*, *PIZZA*, *BURGER* → Dining

Groceries:
- *SAFEWAY*, *KROGER*, *WHOLE FOODS*, *TRADER JOE* → Groceries
- *GROCERY*, *MARKET*, *SUPERMARKET* → Groceries
- *COSTCO*, *WALMART* (food items) → Groceries

Transportation:
- *SHELL*, *CHEVRON*, *EXXON*, *GAS* → Transportation
- *UBER*, *LYFT* (rides, not Eats) → Transportation
- *PARKING*, *TRANSIT*, *BART*, *METRO* → Transportation

Shopping:
- *AMAZON*, *TARGET*, *WALMART* → Shopping
- *APPLE.COM*, *BEST BUY* → Shopping

Entertainment:
- *NETFLIX*, *SPOTIFY*, *HULU*, *DISNEY* → Entertainment
- *AMC*, *REGAL*, *CINEMA* → Entertainment
- *STEAM*, *PLAYSTATION*, *XBOX* → Entertainment

Bills:
- *ELECTRIC*, *POWER*, *ENERGY* → Bills
- *WATER*, *SEWER* → Bills
- *VERIZON*, *AT&T*, *T-MOBILE* → Bills
- *COMCAST*, *XFINITY*, *SPECTRUM* → Bills

Healthcare:
- *CVS*, *WALGREENS*, *PHARMACY* → Healthcare
- *MEDICAL*, *DOCTOR*, *HOSPITAL*, *CLINIC* → Healthcare
- *GYM*, *FITNESS*, *PLANET FITNESS* → Healthcare

Travel:
- *AIRLINE*, *UNITED*, *DELTA*, *SOUTHWEST* → Travel
- *HOTEL*, *MARRIOTT*, *HILTON*, *AIRBNB* → Travel
```

#### Categorization Priority

| Priority | Rule Type |
|----------|-----------|
| 1 | User-defined category rule for payee |
| 2 | Single transaction category override |
| 3 | Auto-detected pattern match |
| 4 | Default: `other` |

---

## 9. 50/30/20 Smart Lens (Phase 2 Specification)

This feature provides an analytical overlay for the Net Monthly Income dashboard, answering the question: **"Is my spending balanced?"**

### Design Philosophy

Instead of a rigid budget that users must build and maintain, this is a passive analysis tool. Users simply toggle it on to see if their actual behavior matches the 50/30/20 ideal—no setup required.

### Visual Presentation

When enabled, the "Income vs Expenses" view transforms into:
- **Tripartite Progress Bar** - Three stacked segments showing actual percentages
- **Donut Chart** (alternative) - Visual breakdown with percentage labels

Each segment shows:
- Actual percentage vs. target percentage
- Dollar amount in that category
- Color coding: Green (on target), Yellow (slightly off), Red (significantly off)

### Category Classification

| Category | Target | Auto-Detection Logic |
|----------|--------|---------------------|
| **Needs (50%)** | Essential expenses | Mortgage/Loan payments, Utilities, Groceries, Insurance, Healthcare, Minimum debt payments |
| **Savings/Debt (20%)** | Wealth building | Transfers to savings/investment accounts, Extra debt payments beyond minimums |
| **Wants (30%)** | Discretionary | Everything else (dining, entertainment, shopping, subscriptions) |

### Auto-Classification Rules

#### Needs Detection
```
Account Types:
- Mortgage payments → Need
- Loan payments → Need

Payee Patterns (case-insensitive):
- *ELECTRIC*, *POWER*, *ENERGY* → Need (Utilities)
- *WATER*, *SEWER* → Need (Utilities)
- *GAS COMPANY*, *NATURAL GAS* → Need (Utilities)
- *GROCERY*, *SAFEWAY*, *KROGER*, *TRADER JOE* → Need (Groceries)
- *INSURANCE* → Need
- *PHARMACY*, *CVS*, *WALGREENS* → Need (Healthcare)
- *MEDICAL*, *DOCTOR*, *HOSPITAL* → Need (Healthcare)
```

#### Savings/Debt Detection
```
Transaction Types:
- Transfers to accounts with type = "savings" or "investment" → Savings
- Transfers to accounts with type = "brokerage" → Savings
- Payments exceeding minimum to loan accounts → Extra Debt Payment
```

#### Wants (Default)
- All expenses not classified as Needs or Savings/Debt

### Imbalance Indicators

| Actual Ratio | Display | Message |
|--------------|---------|---------|
| Needs > 55% | Red "Needs" segment | "Needs are eating into your Wants/Savings" |
| Savings < 15% | Yellow "Savings" segment | "Consider increasing your savings rate" |
| Wants > 35% | Yellow "Wants" segment | "Discretionary spending is elevated" |
| Balanced (±5%) | All green | "Your spending is well-balanced" |

### User Customization

- **Override Classifications** - Tap any transaction to reclassify (Need/Want/Savings)
- **Create Rules** - "Always classify [payee] as [category]"
- **Adjust Targets** - Some users may prefer 60/20/20 or other ratios

### Data Model Addition

```swift
enum SpendingCategory {
    case need
    case want
    case savingsDebt
}

// Extension to Transaction
extension Transaction {
    var spendingCategory: SpendingCategory?  // nil for income/transfers
    var spendingCategoryRule: SpendingCategoryRule?
}

SpendingCategoryRule {
    id: UUID
    payeePattern: String
    category: SpendingCategory
    isAutoGenerated: Bool
    isEnabled: Bool
}

// Monthly aggregation
MonthlySpendingBreakdown {
    year: Int
    month: Int
    needsTotal: Decimal
    wantsTotal: Decimal
    savingsDebtTotal: Decimal
    needsPercentage: Double
    wantsPercentage: Double
    savingsDebtPercentage: Double
}
```

---

## 10. Recurring Payment Detector (Phase 2 Specification)

This feature acts as a "leakage" monitor, identifying fixed costs that hit every month. It helps users distinguish between one-time "Wants" and permanent "Needs."

### Design Philosophy

Surface the "Oh, I forgot I was paying for that" moment. By showing the total monthly cost of all recurring items, users realize that multiple $15/month subscriptions add up to a significant chunk of their budget.

### Visual Presentation

A dedicated **"Recurring"** tab or section accessible from:
- Dashboard (quick summary card)
- Account view (detailed list)

Displays:
- List of detected subscriptions and fixed bills
- Total monthly recurring cost (prominent)
- Expected next charge date for each item
- Category tag (Need/Want) for 50/30/20 integration

### Detection Algorithm

#### Pattern Matching Criteria

| Criterion | Requirement |
|-----------|-------------|
| **Same Payee** | Normalized payee name matches |
| **Similar Amount** | Within 10% variance (accounts for price changes) |
| **Regular Interval** | 28-31 days apart (monthly) OR 13-15 days (bi-weekly) OR 6-8 days (weekly) |
| **Minimum Occurrences** | At least 2 matches to confirm pattern |
| **Recency** | Most recent occurrence within last 45 days |

#### Confidence Scoring

```
Confidence = (occurrences × 20) + (amount_consistency × 30) + (timing_consistency × 50)

Where:
- occurrences: Number of detected recurring instances (capped at 5)
- amount_consistency: 100 - (variance_percentage × 2)
- timing_consistency: 100 - (days_off_from_expected × 10)

Display Thresholds:
- High Confidence (80+): Show as confirmed recurring
- Medium Confidence (50-79): Show with "Likely recurring" label
- Low Confidence (<50): Don't display (or show in "Possible" section)
```

### Prediction Engine

Once a pattern is confirmed:

```swift
func predictNextCharge(from recurringItem: RecurringItem) -> Date {
    let averageInterval = recurringItem.transactions
        .sorted(by: { $0.posted < $1.posted })
        .adjacentPairs()
        .map { Calendar.current.dateComponents([.day], from: $0.posted, to: $1.posted).day! }
        .average()

    return Calendar.current.date(
        byAdding: .day,
        value: Int(averageInterval.rounded()),
        to: recurringItem.lastTransaction.posted
    )!
}
```

### 50/30/20 Integration

Recurring payments auto-classify for the Smart Lens:

| Recurring Type | Default Category | Examples |
|----------------|------------------|----------|
| **Utilities** | Need | Electric, Water, Gas, Internet |
| **Insurance** | Need | Car, Health, Home, Life |
| **Subscriptions** | Want | Netflix, Spotify, Gym, News |
| **Loan Payments** | Need | Mortgage, Car loan, Student loan |
| **Savings Transfers** | Savings/Debt | Auto-transfer to savings account |

Users can override any classification.

### Data Model Addition

```swift
RecurringItem {
    id: UUID
    payeeName: String                    // Normalized payee
    averageAmount: Decimal               // Average across occurrences
    frequency: RecurringFrequency        // monthly, biweekly, weekly
    confidence: Double                   // 0-100 confidence score
    lastChargeDate: Date
    predictedNextDate: Date
    spendingCategory: SpendingCategory   // For 50/30/20 integration
    isConfirmedByUser: Bool              // User verified this is recurring
    isHidden: Bool                       // User dismissed this item
    transactionIds: [String]             // Linked transactions
}

enum RecurringFrequency {
    case weekly      // 6-8 days
    case biweekly    // 13-15 days
    case monthly     // 28-31 days
    case quarterly   // 88-95 days
    case annual      // 360-370 days
}
```

### User Interface

#### Recurring Summary Card (Dashboard)
```
┌─────────────────────────────────────┐
│ 🔄 Recurring Payments               │
│                                     │
│ Monthly Total: $847                 │
│ 12 active subscriptions             │
│                                     │
│ Next up: Netflix ($15) - Jan 22     │
│                                     │
│ [View All →]                        │
└─────────────────────────────────────┘
```

#### Recurring List View
```
┌─────────────────────────────────────┐
│ Monthly Recurring: $847             │
├─────────────────────────────────────┤
│ NEEDS                        $612   │
│ ├─ Mortgage              $1,850     │
│ ├─ Car Insurance           $125     │
│ ├─ Electric Co.             $95     │
│ └─ Internet                 $75     │
├─────────────────────────────────────┤
│ WANTS                        $235   │
│ ├─ Netflix                  $15     │
│ ├─ Spotify                  $11     │
│ ├─ Gym Membership           $50     │
│ └─ + 5 more...                      │
└─────────────────────────────────────┘
```

### User Actions

- **Confirm** - Mark detected pattern as definitely recurring
- **Dismiss** - "This isn't recurring" (hides from list)
- **Reclassify** - Change Need/Want category
- **Set Reminder** - Get notified before next charge
- **Cancel Tracking** - Stop tracking (e.g., cancelled subscription)

---

## 11. Technical Decisions

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
    id: String              // SimpleFIN ID
    name: String            // Original name from SimpleFIN
    nickname: String?       // User-defined display name
    displayName: String     // Computed: nickname ?? name
    type: AccountType       // checking, savings, credit, investment, loan, brokerage, mortgage
    balance: Decimal
    previousBalance: Decimal?   // Balance from last sync (for delta display)
    currency: String
    organization: String
    lastSynced: Date
    isHidden: Bool          // User can hide from calculations
    isTrackingOnly: Bool    // Visible but excluded from totals
    isAsset: Bool           // Computed: true for checking/savings/investment/brokerage
    sortOrder: Int          // User-defined ordering within institution group
}

Transaction {
    id: String              // SimpleFIN ID
    accountId: String
    amount: Decimal
    description: String
    payee: String?
    posted: Date
    pending: Bool           // Pending transactions shown differently in UI

    // Classification fields
    classification: Classification      // income | expense | transfer | ignore
    appliedRule: TransactionRule?       // Which rule classified this (for transparency)
    userOverride: Classification?       // Manual override (if any)
    matchedTransferId: String?          // ID of matching transfer transaction (if transfer)

    // Spending category fields (for expenses only)
    category: SpendingCategory?         // nil for income/transfers
    categoryRule: CategoryRule?         // Which rule categorized this
    userCategoryOverride: SpendingCategory?  // Manual category override
}

// Spending categories
enum SpendingCategory: String {
    case dining, groceries, transportation, shopping
    case entertainment, bills, healthcare, travel, other
}

CategoryRule {
    id: UUID
    payeePattern: String            // Pattern to match
    category: SpendingCategory
    isAutoGenerated: Bool
    isEnabled: Bool
}

// Classification system (new)
enum Classification {
    case income             // Counted as positive in Net Monthly Income
    case expense            // Counted as negative in Net Monthly Income
    case transfer           // Excluded from Net Monthly Income
    case ignore             // User-excluded from all calculations
}

TransactionRule {
    id: UUID
    payeeName: String               // Payee/institution pattern to match
    classification: Classification  // What to classify matching transactions as
    createdAt: Date
    isAutoGenerated: Bool           // True if system-created, false if user-created
    isEnabled: Bool                 // User can toggle rules on/off
}

// Historical data for trend charts (new)
DailySnapshot {
    id: UUID
    date: Date                      // Date of snapshot
    netWorth: Decimal               // Total net worth on this date
    totalAssets: Decimal            // Sum of asset accounts
    totalLiabilities: Decimal       // Sum of liability accounts
}

MonthlySnapshot {
    id: UUID
    year: Int                       // e.g., 2024
    month: Int                      // 1-12
    totalIncome: Decimal            // Sum of income transactions
    totalExpenses: Decimal          // Sum of expense transactions (absolute value)
    netIncome: Decimal              // totalIncome - totalExpenses
}

// Sync tracking (new)
SyncMetadata {
    id: UUID
    lastSyncDate: Date
    dailyRequestCount: Int          // Reset at midnight UTC
    lastRequestCountReset: Date     // When count was last reset
}
```

### Security Considerations

1. **Access Token Storage:** iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
2. **Data at Rest:** Protected by iOS Data Protection (encrypted when locked)
3. **Network:** All API calls over HTTPS
4. **No Logging:** Never log transaction data or access tokens

---

## 12. Success Metrics

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

## 13. Open Questions

1. **Pricing Model:** Subscription vs. one-time purchase?
2. **App Name:** "GhostVault" or something else?
3. **Widgets:** iOS home screen widgets for net worth display in future phase?

---

## 14. Ghost-Safe LLM Export (Phase 4 Specification)

This feature enables users to export their financial data in a format optimized for LLM consumption while stripping all personally identifiable information. The result is a **Context-Rich, Identity-Poor** document.

### Design Philosophy

The export provides enough numerical "signal" for an LLM to offer intelligent financial insights, without the "noise" of PII (Personally Identifiable Information). Raw sensitive data never leaves the device—all anonymization happens locally via Apple Intelligence.

### Anonymization Components

| Component | Transformation | Purpose |
|-----------|---------------|---------|
| **Account Names** | "Chase Sapphire ...4829" → "Liability_A (Credit Card)" | Prevents LLM from knowing which institutions you use |
| **Payee Scrubbing** | "Shell Gas Station #492" → "Category: Fuel/Transportation" | Masks specific locations and habits |
| **Relative Dates** | "2024-01-15" → "Month 1, Day 15" or "T-Minus 14 Days" | Prevents pinpointing specific rent cycles or paydays |
| **Precision Scaling** | $1,245.67 → $1,250 (optional) | Hides the exact "digital fingerprint" of the account |

### Apple Intelligence Integration (iOS 26+)

Leveraging the Foundation Models framework, all processing happens entirely on-device. This means raw, sensitive data never touches a server—even a Private Cloud Compute (PCC) one.

#### A. Structured Generation with `@Generable`

Define a Swift struct for the "Anonymized Report" and use the on-device model to populate it.

```swift
@Generable
struct AnonymizedFinancialReport {
    let accountSummaries: [AnonymizedAccount]
    let transactionCategories: [CategorySummary]
    let periodCovered: RelativeDateRange
    let incomeToExpenseRatio: Double
    let topSpendingCategories: [String]
}
```

**How it works:**
1. Pass the raw transaction list to the `SystemLanguageModel`
2. The AI uses its reasoning to categorize and redact payees into the "Ghost-Safe" format
3. Output is a perfectly formatted JSON or Markdown string

#### B. Local Narrative Summarization

Instead of just exporting a table, use Apple Intelligence to write a **Financial Narrative** for LLM context.

**On-Device Prompt Example:**
> "Summarize the core trends in this transaction list. Identify the top 3 spending categories and the income-to-expense ratio, but remove all specific store names and account numbers."

**Example Output:**
> "In Month 1, your primary income grew by 5%, while 'Category: Dining' spiked by 20% due to several weekend transactions. Your largest liability account decreased by 8%, indicating debt paydown."

This narrative format is easier for an external LLM to digest than raw CSV data.

#### C. Semantic Search for Manual Reviews

Use local NLP to help users find transactions to "Ignore" or "Reclassify" during export preparation.

**Example Interaction:**
- User says: "Find all those weird Venmo transfers from the trip"
- On-device model flags matching transactions for the "Ignore" list
- User reviews and confirms before export is generated

### Export Format Options

#### Markdown Export
```markdown
# Financial Summary (Month 1-3)

## Account Overview
- Asset_A (Checking): $X,XXX
- Asset_B (Savings): $XX,XXX
- Liability_A (Credit Card): -$X,XXX

## Income vs Expenses
- Total Income: $X,XXX
- Total Expenses: $X,XXX
- Net: +$XXX

## Top Spending Categories
1. Category: Housing (35%)
2. Category: Transportation (18%)
3. Category: Dining (12%)

## Narrative
[AI-generated summary paragraph]
```

#### JSON Export
```json
{
  "period": { "start": "Month 1, Day 1", "end": "Month 3, Day 31" },
  "accounts": [
    { "alias": "Asset_A", "type": "Checking", "balance": 5250 },
    { "alias": "Liability_A", "type": "Credit Card", "balance": -2100 }
  ],
  "summary": {
    "totalIncome": 8500,
    "totalExpenses": 7200,
    "netIncome": 1300,
    "incomeToExpenseRatio": 1.18
  },
  "categories": [
    { "name": "Housing", "amount": 2520, "percentage": 35 },
    { "name": "Transportation", "amount": 1296, "percentage": 18 }
  ],
  "narrative": "In Month 1, your primary income grew by 5%..."
}
```

### User Flow

1. **Export Initiation** - User taps "Export for LLM" in Settings or Dashboard
2. **Date Range Selection** - Choose period to include
3. **Anonymization Preview** - Review how accounts/payees will be transformed
4. **Manual Review** - Semantic search to flag/exclude sensitive transactions
5. **Format Selection** - Choose Markdown or JSON
6. **Precision Options** - Toggle amount rounding on/off
7. **Generate & Share** - Export via share sheet (copy, AirDrop, Files, etc.)

### Integration with Smart Analysis Features

When Phase 2 features (50/30/20 Smart Lens, Recurring Payment Detector) are active, the Ghost-Safe Export gains additional contextual signal:

#### Enhanced Export Data
```json
{
  "recurringCommitments": {
    "monthlyTotal": 847,
    "needsRecurring": 612,
    "wantsRecurring": 235,
    "itemCount": 12
  },
  "budgetStatus": {
    "needsPercentage": 55,
    "wantsPercentage": 28,
    "savingsPercentage": 17,
    "status": "Needs slightly elevated",
    "targetDeviation": {
      "needs": "+5%",
      "wants": "-2%",
      "savings": "-3%"
    }
  }
}
```

#### Example Narrative Enhancement
> "Total Recurring Commitments: $847/month (12 items). 50/30/20 Status: Needs are currently at 55% of net income, 5% above target. Recurring Needs ($612) account for 72% of your total Needs spending."

**User Benefit:** This allows an external AI to give much more tailored advice without ever seeing a single raw bank transaction. The LLM understands spending patterns, budget balance, and fixed vs. variable costs—all anonymized.

### Security Guarantees

- All processing via Apple's on-device Foundation Models
- No data sent to external servers during anonymization
- Original data unchanged in local database
- Export file contains zero PII when properly configured

---

## 15. Resources

### SimpleFIN
- [SimpleFIN Bridge](https://bridge.simplefin.org/)
- [Developer Guide](https://bridge.simplefin.org/info/developers)
- [Protocol Specification](https://www.simplefin.org/protocol.html)

### Apple Technologies
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [Foundation Models Framework](https://developer.apple.com/documentation/foundationmodels) (iOS 26+)

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
