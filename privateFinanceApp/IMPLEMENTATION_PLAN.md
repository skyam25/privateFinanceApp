# GhostVault Ralph Loop Execution Plan

## Overview

Break down the PRD MVP into iterative Ralph Loop tasks with built-in testing and validation feedback loops. Each task executes one-at-a-time with clear completion criteria.

---

## Execution Strategy

### Ralph Loop Configuration
```bash
/ralph-loop "<task prompt>" --max-iterations 15 --completion-promise "TASK_COMPLETE"
```

### Feedback Mechanisms (Backpressure)
1. **Build validation** - `xcodebuild` must succeed after each task
2. **Unit tests** - Tests must pass before marking complete
3. **SwiftUI Previews** - Visual verification for UI components
4. **progress.txt** - Track completed work across iterations

### Task Structure (JSON format for PRD items)
```json
{
  "id": "P0-T1",
  "category": "infrastructure",
  "description": "Task description",
  "acceptance": ["Criteria 1", "Criteria 2"],
  "passes": false
}
```

---

## Phase 0: Test Infrastructure (Foundation)

**Why First:** Enables TDD for all subsequent phases. No feedback loop = no quality assurance.

### P0-T1: Create XCTest Target
```json
{
  "id": "P0-T1",
  "description": "Add XCTest unit test target to GhostVault project",
  "acceptance": [
    "GhostVaultTests target exists in Xcode project",
    "Sample test file compiles and runs",
    "Test target can import @testable GhostVault"
  ],
  "passes": true
}
```

### P0-T2: Model Unit Tests
```json
{
  "id": "P0-T2",
  "description": "Write unit tests for existing models (Account, Transaction, Category)",
  "acceptance": [
    "AccountTests: test balance calculations, account type classification",
    "TransactionTests: test amount parsing, category assignment",
    "CategoryTests: test pattern matching (contains, regex, etc.)",
    "All tests pass"
  ],
  "passes": true
}
```

### P0-T3: SimpleFIN Service Tests
```json
{
  "id": "P0-T3",
  "description": "Write unit tests for SimpleFINService with mocked responses",
  "acceptance": [
    "Test token claiming with mock URL response",
    "Test account fetching with mock JSON data",
    "Test error handling for all SimpleFINError cases",
    "All tests pass"
  ],
  "passes": true
}
```

---

## Phase 1: Onboarding Flow

**Dependency:** Phase 0 complete (test infrastructure exists)

### P1-T1: Welcome Screen UI
```json
{
  "id": "P1-T1",
  "description": "Build welcome screen (Page 1 of onboarding)",
  "acceptance": [
    "App name and tagline displayed",
    "Privacy value proposition text",
    "SimpleFIN requirement explanation",
    "'Get Started' button navigates to next page",
    "SwiftUI preview renders correctly"
  ],
  "passes": true
}
```

### P1-T2: SimpleFIN Token Entry Screen
```json
{
  "id": "P1-T2",
  "description": "Build SimpleFIN token entry screen (Page 2)",
  "acceptance": [
    "Text field for token paste with paste button",
    "'I have a token' and 'I need an account' paths",
    "Token validation on submit (format check)",
    "Loading state during token claim",
    "Error display for invalid tokens",
    "Unit test for token format validation"
  ],
  "passes": true
}
```

### P1-T3: SimpleFIN WebView Integration
```json
{
  "id": "P1-T3",
  "description": "In-app WebView for SimpleFIN signup flow",
  "acceptance": [
    "WKWebView loads SimpleFIN.org",
    "Monitors for setup token in URL/content",
    "Auto-extracts token when available",
    "Dismiss WebView and proceed to validation",
    "Fallback to manual paste if auto-detect fails"
  ],
  "passes": true
}
```

### P1-T4: Account Discovery Screen
```json
{
  "id": "P1-T4",
  "description": "Build account discovery screen (Page 3)",
  "acceptance": [
    "Fetches accounts from SimpleFIN after token claim",
    "Displays list of accounts with name, type, balance",
    "Toggle to hide/exclude accounts from totals",
    "'Continue' button saves preferences and proceeds",
    "Unit test for account filtering logic"
  ],
  "passes": true
}
```

### P1-T5: Initial Classification Review
```json
{
  "id": "P1-T5",
  "description": "Build initial transaction classification review (Page 4)",
  "acceptance": [
    "Shows transactions from past month",
    "Highlights auto-detected patterns (payroll, transfers)",
    "User can confirm or adjust classifications",
    "'Apply to all from [payee]' option for bulk corrections",
    "'Continue to Dashboard' completes onboarding"
  ],
  "passes": true
}
```

---

## Phase 2: Dashboard (Core Feature)

**Dependency:** Phase 1 complete (can fetch and store account data)

### P2-T1: Net Worth Card
```json
{
  "id": "P2-T1",
  "description": "Build Net Worth card component",
  "acceptance": [
    "Large number display of total net worth",
    "Delta indicator with green/red coloring",
    "Tap to expand assets vs liabilities breakdown",
    "Unit test for net worth calculation (assets - liabilities)"
  ],
  "passes": true
}
```

### P2-T2: Net Monthly Income Card
```json
{
  "id": "P2-T2",
  "description": "Build Net Monthly Income card component",
  "acceptance": [
    "Large number display of net income for selected month",
    "Month selector (swipe or tap arrows)",
    "Income and expense breakdown below",
    "Unit test for net income calculation (income - expenses, excluding transfers)"
  ],
  "passes": true
}
```

### P2-T3: Sync Status Bar
```json
{
  "id": "P2-T3",
  "description": "Build sync status bar component",
  "acceptance": [
    "Last sync timestamp display",
    "Pull-to-refresh gesture triggers sync",
    "'Sync Now' button with loading state",
    "Remaining daily syncs indicator (X/24)",
    "Unit test for rate limit tracking logic"
  ],
  "passes": true
}
```

### P2-T4: Dashboard Assembly
```json
{
  "id": "P2-T4",
  "description": "Assemble Dashboard view with all components",
  "acceptance": [
    "Net Worth card at top",
    "Net Monthly Income card below",
    "Sync status bar at bottom",
    "Pull-to-refresh works on entire view",
    "SwiftUI preview shows complete dashboard"
  ],
  "passes": true
}
```

---

## Phase 3: Account Management

### P3-T1: Account List View
```json
{
  "id": "P3-T1",
  "description": "Build account list grouped by institution",
  "acceptance": [
    "Accounts grouped by organization/institution",
    "Balance and account type for each",
    "Visual indicator: green for assets, red for liabilities",
    "Tap navigates to account detail",
    "SwiftUI preview with sample data"
  ],
  "passes": true
}
```

### P3-T2: Account Detail View
```json
{
  "id": "P3-T2",
  "description": "Build account detail view",
  "acceptance": [
    "Account balance with delta since last sync",
    "Mini balance trend chart (sparkline)",
    "Transaction list filtered to this account",
    "Account settings (nickname, hide/show)",
    "Unit test for delta calculation"
  ],
  "passes": true
}
```

### P3-T3: Account Customization
```json
{
  "id": "P3-T3",
  "description": "Implement account customization features",
  "acceptance": [
    "Custom nickname editing and persistence",
    "Hide/exclude toggle with persistence",
    "'Tracking only' option (visible but excluded)",
    "Drag-to-reorder accounts within groups",
    "Unit test for nickname persistence"
  ],
  "passes": true
}
```

---

## Phase 4: Transaction View

### P4-T1: Transaction List
```json
{
  "id": "P4-T1",
  "description": "Build transaction list with date headers",
  "acceptance": [
    "Chronological list with date section headers",
    "Classification badges (income/expense/transfer/ignore)",
    "Pending transactions with dashed border at top",
    "Shows classification reason (rule name or 'Default')",
    "SwiftUI preview with sample transactions"
  ],
  "passes": true
}
```

### P4-T2: Transaction Detail Sheet
```json
{
  "id": "P4-T2",
  "description": "Build transaction detail bottom sheet",
  "acceptance": [
    "Full payee name and description",
    "Amount, date, account info",
    "Current classification with change option",
    "'Apply to all from [payee]' toggle",
    "'Ignore this transaction' option",
    "Changes persist to SwiftData"
  ],
  "passes": true
}
```

### P4-T3: Search and Filter
```json
{
  "id": "P4-T3",
  "description": "Implement transaction search and filtering",
  "acceptance": [
    "Search by payee, description, or amount",
    "Filter by account, classification, date range",
    "Quick filters: This month, Last month, Income only, Expenses only",
    "Unit test for filter logic combinations"
  ],
  "passes": true
}
```

---

## Phase 5: Business Logic (Classification Engine)

### P5-T1: Transfer Detection
```json
{
  "id": "P5-T1",
  "description": "Implement automatic transfer detection",
  "acceptance": [
    "Detect matching amounts within 3 days across accounts",
    "Link matched transactions via matchedTransferId",
    "Exclude pending transactions from matching",
    "Unit tests for all detection edge cases"
  ],
  "passes": true
}
```

### P5-T2: Income Pattern Detection
```json
{
  "id": "P5-T2",
  "description": "Implement income pattern regex matching",
  "acceptance": [
    "Regex patterns: PAYROLL, DIRECT DEP, SALARY, etc.",
    "Case-insensitive matching",
    "Applied during transaction sync",
    "Unit tests for all income patterns"
  ],
  "passes": true
}
```

### P5-T3: Transaction Rule Engine
```json
{
  "id": "P5-T3",
  "description": "Implement classification rule priority system",
  "acceptance": [
    "Priority order: user payee rules > manual override > auto-transfer > auto-CC payment > pattern income > default",
    "Rules persisted in SwiftData",
    "Rule creation from 'Apply to all' action",
    "Unit tests for priority resolution"
  ],
  "passes": false
}
```

---

## Phase 6: Trend Charts

### P6-T1: Historical Snapshot Storage
```json
{
  "id": "P6-T1",
  "description": "Implement DailySnapshot and MonthlySnapshot models",
  "acceptance": [
    "DailySnapshot: date, netWorth, totalAssets, totalLiabilities",
    "MonthlySnapshot: year, month, totalIncome, totalExpenses, netIncome",
    "Snapshots created/updated on each sync",
    "Unit tests for snapshot creation"
  ],
  "passes": false
}
```

### P6-T2: Net Worth Line Chart
```json
{
  "id": "P6-T2",
  "description": "Build net worth trend line chart",
  "acceptance": [
    "Swift Charts line graph with daily data points",
    "Timeframe selector: 1M, 3M, YTD, 1Y, Custom",
    "Custom date picker for flexible ranges",
    "Accessible from Dashboard Net Worth card",
    "SwiftUI preview with sample data"
  ],
  "passes": false
}
```

### P6-T3: Net Monthly Income Bar Chart
```json
{
  "id": "P6-T3",
  "description": "Build net monthly income bar chart",
  "acceptance": [
    "Toggle between Income vs Expenses and Net Income views",
    "Side-by-side bars or single bar per month",
    "Green = positive, Red = negative",
    "Same timeframe selectors as Net Worth chart",
    "SwiftUI preview with sample data"
  ],
  "passes": false
}
```

---

## Phase 7: Spending Categories

### P7-T1: Category Breakdown View
```json
{
  "id": "P7-T1",
  "description": "Build category breakdown donut/pie chart",
  "acceptance": [
    "Donut chart showing expense distribution",
    "List view sorted by amount (highest first)",
    "Categories: Dining, Shopping, Groceries, etc.",
    "Accessible from Net Monthly Income card",
    "SwiftUI preview with sample data"
  ],
  "passes": false
}
```

### P7-T2: Auto-Categorization Engine
```json
{
  "id": "P7-T2",
  "description": "Implement merchant pattern auto-categorization",
  "acceptance": [
    "Pattern matching per PRD merchant lists",
    "User corrections create persistent CategoryRule",
    "Category assigned during transaction sync",
    "Unit tests for all category patterns"
  ],
  "passes": false
}
```

### P7-T3: Category Detail View
```json
{
  "id": "P7-T3",
  "description": "Build category detail with month-over-month comparison",
  "acceptance": [
    "List all transactions in selected category",
    "Month-over-month comparison display",
    "Tap category from breakdown to navigate here"
  ],
  "passes": false
}
```

---

## Phase 8: Settings

### P8-T1: SimpleFIN Connection Status
```json
{
  "id": "P8-T1",
  "description": "Build SimpleFIN connection settings section",
  "acceptance": [
    "Connection status indicator (connected/disconnected)",
    "Reconnect/update token capability",
    "Daily sync request counter (X/24 remaining)",
    "Last sync timestamp"
  ],
  "passes": false
}
```

### P8-T2: Transaction Rules Management
```json
{
  "id": "P8-T2",
  "description": "Build transaction rules management UI",
  "acceptance": [
    "List all payee-based rules",
    "Edit/delete existing rules",
    "Distinguish auto-generated vs user-created",
    "Toggle rules on/off"
  ],
  "passes": false
}
```

---

## Phase 9: Error & Empty States

### P9-T1: Empty State Screens
```json
{
  "id": "P9-T1",
  "description": "Implement empty state UI for all views",
  "acceptance": [
    "First launch: welcoming empty state with CTA",
    "No transactions for period: suggestion to check date range",
    "Loading skeleton UI during sync",
    "SwiftUI previews for all empty states"
  ],
  "passes": false
}
```

### P9-T2: Error Handling UI
```json
{
  "id": "P9-T2",
  "description": "Implement error state UI and recovery flows",
  "acceptance": [
    "SimpleFIN unreachable: retry message",
    "Token expired: re-auth flow trigger",
    "Rate limited: reset time message",
    "Partial sync: show which accounts failed",
    "Unit test for error state transitions"
  ],
  "passes": false
}
```

---

## Ralph Loop Prompt Template

Use this template for each task:

```markdown
# Task: [TASK_ID] - [Description]

## Context
@progress.txt
@GhostVault/

## Requirements
[Copy acceptance criteria from task JSON]

## Approach
1. Write failing unit test(s) first (if applicable)
2. Implement the feature
3. Run tests: `xcodebuild test -scheme GhostVault -destination 'platform=iOS Simulator,name=iPhone 16'`
4. Fix any failures
5. Verify SwiftUI preview renders correctly
6. Update progress.txt with completion notes

## Completion Criteria
- All acceptance criteria met
- Build succeeds: `xcodebuild build -scheme GhostVault`
- Tests pass (if applicable)
- No compiler warnings related to this task

When complete, output: <promise>TASK_COMPLETE</promise>

If blocked after 10 iterations:
- Document blocker in progress.txt
- List attempted approaches
- Output: <promise>TASK_BLOCKED</promise>
```

---

## Execution Order Summary

| Phase | Tasks | Focus |
|-------|-------|-------|
| P0 | 3 tasks | Test infrastructure |
| P1 | 5 tasks | Onboarding flow |
| P2 | 4 tasks | Dashboard (core) |
| P3 | 3 tasks | Account management |
| P4 | 3 tasks | Transaction view |
| P5 | 3 tasks | Classification engine |
| P6 | 3 tasks | Trend charts |
| P7 | 3 tasks | Spending categories |
| P8 | 2 tasks | Settings |
| P9 | 2 tasks | Error states |

**Total: 31 tasks**

---

## Files to Create/Modify

### New Files (by phase)
- `GhostVaultTests/` - Test target (P0)
- `Views/Onboarding/WelcomeView.swift` - (P1)
- `Views/Onboarding/TokenEntryView.swift` - (P1)
- `Views/Onboarding/SimpleFINWebView.swift` - (P1)
- `Views/Onboarding/AccountDiscoveryView.swift` - (P1)
- `Views/Onboarding/ClassificationReviewView.swift` - (P1)
- `Views/Dashboard/NetWorthCard.swift` - (P2)
- `Views/Dashboard/NetMonthlyIncomeCard.swift` - (P2)
- `Views/Dashboard/SyncStatusBar.swift` - (P2)
- `Views/Accounts/AccountDetailView.swift` - (P3)
- `Views/Transactions/TransactionDetailSheet.swift` - (P4)
- `Views/Charts/NetWorthChartView.swift` - (P6)
- `Views/Charts/IncomeExpenseChartView.swift` - (P6)
- `Views/Categories/CategoryBreakdownView.swift` - (P7)
- `Views/Categories/CategoryDetailView.swift` - (P7)
- `Models/DailySnapshot.swift` - (P6)
- `Models/MonthlySnapshot.swift` - (P6)
- `Services/Classification/TransferDetector.swift` - (P5)
- `Services/Classification/IncomeDetector.swift` - (P5)
- `Services/Classification/ClassificationEngine.swift` - (P5)

### Existing Files to Modify
- `Views/Dashboard/DashboardView.swift` - Replace placeholder (P2)
- `Views/Accounts/AccountsView.swift` - Replace placeholder (P3)
- `Views/Transactions/TransactionsView.swift` - Replace placeholder (P4)
- `Views/Settings/SettingsView.swift` - Replace placeholder (P8)
- `Views/Onboarding/OnboardingView.swift` - Multi-page flow (P1)
