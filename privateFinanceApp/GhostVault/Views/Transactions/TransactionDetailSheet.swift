//
//  TransactionDetailSheet.swift
//  GhostVault
//
//  Transaction detail bottom sheet with classification editing
//

import SwiftUI
import SwiftData

struct TransactionDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var transaction: Transaction

    @Query private var accounts: [Account]

    @State private var showCategoryPicker = false
    @State private var applyToAllFromPayee = false

    var body: some View {
        NavigationStack {
            List {
                // Transaction header
                Section {
                    transactionHeader
                }

                // Amount and date info
                Section {
                    amountRow
                    dateRow
                    accountRow
                }

                // Classification section
                Section {
                    classificationRow
                    ignoreToggle
                } header: {
                    Text("Classification")
                }

                // Apply to payee section
                if let payee = transaction.payee, !payee.isEmpty {
                    Section {
                        applyToPayeeToggle
                    } footer: {
                        Text("When enabled, all transactions from \"\(payee)\" will use this classification")
                    }
                }

                // Description and memo
                if hasAdditionalDetails {
                    Section {
                        if transaction.transactionDescription != transaction.payee {
                            LabeledContent("Description") {
                                Text(transaction.transactionDescription)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let memo = transaction.memo, !memo.isEmpty {
                            LabeledContent("Memo") {
                                Text(memo)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Details")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(transaction: transaction)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Transaction Header

    private var transactionHeader: some View {
        VStack(spacing: 16) {
            // Classification icon
            ZStack {
                Circle()
                    .fill(transaction.classificationType.color.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: transaction.classificationType.iconName)
                    .font(.title)
                    .foregroundStyle(transaction.classificationType.color)
            }

            // Payee name
            Text(transaction.payee ?? transaction.transactionDescription)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            // Amount
            Text(formattedAmount)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(amountColor)

            // Status badges
            HStack(spacing: 8) {
                // Classification badge
                Text(transaction.classificationType.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(transaction.classificationType.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(transaction.classificationType.color.opacity(0.1))
                    .clipShape(Capsule())

                // Pending badge
                if transaction.pending {
                    Text("Pending")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Info Rows

    private var amountRow: some View {
        LabeledContent {
            Text(formattedAmount)
                .font(.body.monospacedDigit())
                .foregroundStyle(amountColor)
        } label: {
            Label("Amount", systemImage: "dollarsign.circle")
        }
    }

    private var dateRow: some View {
        LabeledContent {
            VStack(alignment: .trailing) {
                Text(transaction.posted, style: .date)
                Text(transaction.posted, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("Date", systemImage: "calendar")
        }
    }

    private var accountRow: some View {
        LabeledContent {
            if let account = accountForTransaction {
                Text(account.displayName)
            } else {
                Text("Unknown Account")
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("Account", systemImage: "building.columns")
        }
    }

    // MARK: - Classification Section

    private var classificationRow: some View {
        Button {
            showCategoryPicker = true
        } label: {
            HStack {
                Label {
                    Text("Category")
                } icon: {
                    Image(systemName: transaction.categoryIcon)
                }

                Spacer()

                Text(transaction.category ?? "Uncategorized")
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
    }

    private var ignoreToggle: some View {
        Toggle(isOn: $transaction.isIgnored) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ignore Transaction")
                    Text("Exclude from calculations and reports")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "minus.circle")
            }
        }
        .onChange(of: transaction.isIgnored) { _, newValue in
            if newValue {
                transaction.classificationReason = "Manual"
            }
        }
    }

    private var applyToPayeeToggle: some View {
        Toggle(isOn: $applyToAllFromPayee) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apply to All from \"\(transaction.payee ?? "")\"")
                    Text("Use this classification for all matching transactions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "arrow.triangle.branch")
            }
        }
        .onChange(of: applyToAllFromPayee) { _, newValue in
            if newValue {
                applyClassificationToAllFromPayee()
            }
        }
    }

    // MARK: - Helpers

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: transaction.amountValue as NSDecimalNumber) ?? "$0.00"
    }

    private var amountColor: Color {
        if transaction.isIgnored {
            return .secondary
        }
        return transaction.amountValue >= 0 ? .green : .primary
    }

    private var accountForTransaction: Account? {
        accounts.first { $0.id == transaction.accountId }
    }

    private var hasAdditionalDetails: Bool {
        (transaction.transactionDescription != transaction.payee) ||
        (transaction.memo != nil && !transaction.memo!.isEmpty)
    }

    private func applyClassificationToAllFromPayee() {
        guard let payee = transaction.payee else { return }

        // Fetch all transactions with this payee
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { txn in
                txn.payee == payee
            }
        )

        do {
            let matchingTransactions = try modelContext.fetch(descriptor)
            for txn in matchingTransactions {
                txn.category = transaction.category
                txn.isIgnored = transaction.isIgnored
                txn.classificationReason = "Payee Rule: \(payee)"
            }
        } catch {
            print("Error applying classification to payee: \(error)")
        }
    }
}

// MARK: - Category Picker Sheet

struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var transaction: Transaction

    private let categories = [
        "Income",
        "Transfer",
        "Groceries",
        "Dining",
        "Shopping",
        "Transportation",
        "Bills & Utilities",
        "Entertainment",
        "Health & Fitness",
        "Travel",
        "Subscriptions",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.self) { category in
                    Button {
                        transaction.category = category
                        transaction.classificationReason = "Manual"
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: TransactionCategory.icon(for: category))
                                .foregroundStyle(categoryColor(for: category))
                                .frame(width: 24)

                            Text(category)
                                .foregroundStyle(.primary)

                            Spacer()

                            if transaction.category == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "income": return .green
        case "transfer": return .blue
        case "groceries": return .teal
        case "dining": return .orange
        case "shopping": return .purple
        case "transportation": return .indigo
        case "bills & utilities": return .yellow
        case "entertainment": return .pink
        case "health & fitness": return .red
        case "travel": return .cyan
        case "subscriptions": return .mint
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview("Transaction Detail") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, Account.self, configurations: config)

    let transaction = Transaction(
        id: "t1",
        accountId: "acc1",
        posted: Date(),
        amount: "-85.32",
        transactionDescription: "TRADER JOES #123 SAN FRANCISCO CA",
        payee: "Trader Joe's",
        memo: "Weekly groceries",
        category: "Groceries",
        classificationReason: "Default"
    )

    let account = Account(
        id: "acc1",
        organizationName: "Chase Bank",
        name: "Checking ****1234",
        balance: "5000.00"
    )

    return TransactionDetailSheet(transaction: transaction)
        .modelContainer(container)
        .onAppear {
            container.mainContext.insert(account)
            container.mainContext.insert(transaction)
        }
}

#Preview("Income Transaction") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, Account.self, configurations: config)

    let transaction = Transaction(
        id: "t2",
        accountId: "acc1",
        posted: Date(),
        amount: "2500.00",
        transactionDescription: "PAYROLL DEPOSIT ACME INC",
        payee: "ACME Inc",
        category: "Income",
        classificationReason: "Payee Rule: Payroll"
    )

    return TransactionDetailSheet(transaction: transaction)
        .modelContainer(container)
}
