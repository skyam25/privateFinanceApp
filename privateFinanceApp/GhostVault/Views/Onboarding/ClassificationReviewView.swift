//
//  ClassificationReviewView.swift
//  GhostVault
//
//  Initial transaction classification review (Page 4 of onboarding)
//  Shows transactions from past month with auto-detected patterns
//  Allows users to confirm or adjust classifications
//

import SwiftUI
import SwiftData

struct ClassificationReviewView: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var transactions: [ReviewableTransaction] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingApplyAllSheet = false
    @State private var selectedTransaction: ReviewableTransaction?

    private let simpleFINService = SimpleFINService()
    private let classifier = TransactionClassifier()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.accent)

                Text("Review Classifications")
                    .font(.title2.bold())

                Text("We've auto-classified your recent transactions. Tap to adjust if needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()

            // Content
            if isLoading {
                Spacer()
                ProgressView("Loading transactions...")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Continue Anyway") {
                        onComplete()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                Spacer()
            } else if transactions.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No transactions found")
                        .font(.headline)
                    Text("We couldn't find any transactions from the past month. You can classify them later as they appear.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else {
                transactionsList
            }

            // Bottom button
            Button {
                saveAndComplete()
            } label: {
                Text("Continue to Dashboard")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .sheet(isPresented: $showingApplyAllSheet) {
            if let transaction = selectedTransaction {
                ApplyAllSheet(
                    transaction: transaction,
                    onApply: { category in
                        applyToAll(payee: transaction.payee ?? transaction.description, category: category)
                    }
                )
            }
        }
        .task {
            await fetchTransactions()
        }
    }

    // MARK: - Transactions List

    private var transactionsList: some View {
        List {
            // Highlighted section for detected patterns
            let highlighted = highlightedTransactions
            if !highlighted.isEmpty {
                Section {
                    ForEach(Array(transactions.enumerated()).filter { $0.element.isHighlighted }, id: \.element.id) { index, _ in
                        TransactionRow(
                            transaction: $transactions[index],
                            onApplyAll: {
                                selectedTransaction = transactions[index]
                                showingApplyAllSheet = true
                            }
                        )
                    }
                } header: {
                    Label("Detected Patterns", systemImage: "wand.and.stars")
                }
            }

            // Regular transactions
            Section {
                ForEach(Array(transactions.enumerated()).filter { !$0.element.isHighlighted }, id: \.element.id) { index, _ in
                    TransactionRow(
                        transaction: $transactions[index],
                        onApplyAll: {
                            selectedTransaction = transactions[index]
                            showingApplyAllSheet = true
                        }
                    )
                }
            } header: {
                if !highlighted.isEmpty {
                    Label("Other Transactions", systemImage: "list.bullet")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var highlightedTransactions: [ReviewableTransaction] {
        transactions.filter { $0.isHighlighted }
    }

    // MARK: - Data Fetching

    private func fetchTransactions() async {
        isLoading = true
        errorMessage = nil

        // Get transactions from past month
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!

        do {
            let accountSet = try await simpleFINService.fetchAccounts(startDate: startDate, endDate: endDate)

            await MainActor.run {
                var allTransactions: [ReviewableTransaction] = []

                for account in accountSet.accounts {
                    for apiTransaction in account.transactions {
                        let classification = classifier.classify(apiTransaction)
                        allTransactions.append(ReviewableTransaction(
                            id: apiTransaction.id,
                            accountId: account.id,
                            date: Date(timeIntervalSince1970: TimeInterval(apiTransaction.posted)),
                            amount: apiTransaction.amount,
                            description: apiTransaction.description,
                            payee: apiTransaction.payee,
                            category: classification.category,
                            isHighlighted: classification.isHighConfidence,
                            pattern: classification.pattern
                        ))
                    }
                }

                // Sort by date, newest first
                transactions = allTransactions.sorted { $0.date > $1.date }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    // MARK: - Apply to All

    private func applyToAll(payee: String, category: String) {
        for i in 0..<transactions.count {
            if transactions[i].payee == payee || transactions[i].description == payee {
                transactions[i].category = category
            }
        }
        showingApplyAllSheet = false
    }

    // MARK: - Save and Complete

    private func saveAndComplete() {
        // Save transactions to SwiftData
        for reviewable in transactions {
            let transaction = Transaction(
                id: reviewable.id,
                accountId: reviewable.accountId,
                posted: reviewable.date,
                amount: reviewable.amount,
                transactionDescription: reviewable.description,
                payee: reviewable.payee,
                memo: nil,
                pending: false,
                category: reviewable.category
            )
            modelContext.insert(transaction)
        }

        try? modelContext.save()
        onComplete()
    }
}

// MARK: - Reviewable Transaction

struct ReviewableTransaction: Identifiable, Equatable {
    let id: String
    let accountId: String
    let date: Date
    let amount: String
    let description: String
    let payee: String?
    var category: String?
    let isHighlighted: Bool
    let pattern: String?

    static func == (lhs: ReviewableTransaction, rhs: ReviewableTransaction) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Transaction Row

private struct TransactionRow: View {
    @Binding var transaction: ReviewableTransaction
    let onApplyAll: () -> Void

    @State private var showingCategoryPicker = false

    private let categories = ["Income", "Groceries", "Dining", "Shopping", "Transportation", "Bills", "Entertainment", "Health", "Travel", "Transfer", "Other"]

    var body: some View {
        HStack {
            // Category icon
            Image(systemName: categoryIcon(for: transaction.category))
                .font(.title2)
                .foregroundStyle(transaction.isHighlighted ? .yellow : .accent)
                .frame(width: 40)

            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.payee ?? transaction.description)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Text(transaction.date, style: .date)
                    if let pattern = transaction.pattern {
                        Text("•")
                        Text(pattern)
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount and category
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatAmount(transaction.amount))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(amountColor(transaction.amount))

                Button {
                    showingCategoryPicker = true
                } label: {
                    Text(transaction.category ?? "Uncategorized")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                onApplyAll()
            } label: {
                Label("Apply to all from \(transaction.payee ?? transaction.description)", systemImage: "arrow.2.squarepath")
            }
        }
        .confirmationDialog("Select Category", isPresented: $showingCategoryPicker) {
            ForEach(categories, id: \.self) { category in
                Button(category) {
                    transaction.category = category
                }
            }
        }
    }

    private func categoryIcon(for category: String?) -> String {
        switch category?.lowercased() {
        case "income": return "arrow.down.circle.fill"
        case "groceries": return "cart.fill"
        case "dining": return "fork.knife"
        case "shopping": return "bag.fill"
        case "transportation": return "car.fill"
        case "bills": return "doc.text.fill"
        case "entertainment": return "tv.fill"
        case "health": return "heart.fill"
        case "travel": return "airplane"
        case "transfer": return "arrow.left.arrow.right"
        default: return "questionmark.circle"
        }
    }

    private func formatAmount(_ amount: String) -> String {
        guard let value = Decimal(string: amount) else { return amount }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSDecimalNumber) ?? amount
    }

    private func amountColor(_ amount: String) -> Color {
        guard let value = Decimal(string: amount) else { return .primary }
        return value >= 0 ? .green : .primary
    }
}

// MARK: - Apply All Sheet

private struct ApplyAllSheet: View {
    let transaction: ReviewableTransaction
    let onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private let categories = ["Income", "Groceries", "Dining", "Shopping", "Transportation", "Bills", "Entertainment", "Health", "Travel", "Transfer", "Other"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.self) { category in
                    Button {
                        onApply(category)
                        dismiss()
                    } label: {
                        HStack {
                            Text(category)
                            Spacer()
                            if transaction.category == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Apply to all from \(transaction.payee ?? transaction.description)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Transaction Classifier

struct TransactionClassifier {
    struct Classification {
        let category: String?
        let isHighConfidence: Bool
        let pattern: String?
    }

    func classify(_ transaction: SimpleFINTransaction) -> Classification {
        let description = transaction.description.lowercased()
        let payee = transaction.payee?.lowercased() ?? ""
        let amount = Decimal(string: transaction.amount) ?? 0

        // Payroll detection
        if containsAny(in: description + payee, patterns: ["payroll", "salary", "direct deposit", "wage", "paycheck"]) {
            return Classification(category: "Income", isHighConfidence: true, pattern: "Payroll")
        }

        // Transfer detection
        if containsAny(in: description + payee, patterns: ["transfer", "xfer", "zelle", "venmo", "paypal", "cash app"]) {
            return Classification(category: "Transfer", isHighConfidence: true, pattern: "Transfer")
        }

        // Grocery detection
        if containsAny(in: description + payee, patterns: ["grocery", "safeway", "trader joe", "whole foods", "kroger", "walmart grocery", "costco"]) {
            return Classification(category: "Groceries", isHighConfidence: false, pattern: nil)
        }

        // Dining detection
        if containsAny(in: description + payee, patterns: ["restaurant", "doordash", "uber eats", "grubhub", "mcdonald", "starbucks", "cafe"]) {
            return Classification(category: "Dining", isHighConfidence: false, pattern: nil)
        }

        // Gas/Transportation
        if containsAny(in: description + payee, patterns: ["shell", "chevron", "exxon", "uber", "lyft", "gas"]) {
            return Classification(category: "Transportation", isHighConfidence: false, pattern: nil)
        }

        // Subscriptions/Bills
        if containsAny(in: description + payee, patterns: ["netflix", "spotify", "amazon prime", "hulu", "electric", "water", "internet", "phone"]) {
            return Classification(category: "Bills", isHighConfidence: false, pattern: nil)
        }

        // Income by positive amount
        if amount > 100 {
            return Classification(category: "Income", isHighConfidence: false, pattern: nil)
        }

        return Classification(category: nil, isHighConfidence: false, pattern: nil)
    }

    private func containsAny(in text: String, patterns: [String]) -> Bool {
        patterns.contains { text.contains($0) }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ClassificationReviewView(
            onComplete: { print("Complete") },
            onBack: { print("Back") }
        )
    }
    .modelContainer(for: [Account.self, Transaction.self], inMemory: true)
}
