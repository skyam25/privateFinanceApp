//
//  TransactionFilterSheet.swift
//  GhostVault
//
//  Filter sheet for transactions with account, classification, and date range options
//

import SwiftUI
import SwiftData

struct TransactionFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var options: TransactionFilter.Options
    let accounts: [Account]

    @State private var selectedAccounts: Set<String> = []
    @State private var selectedClassifications: Set<ClassificationType> = []
    @State private var selectedDateRange: TransactionFilter.DateRange = .all

    var body: some View {
        NavigationStack {
            List {
                // Quick Filters Section
                Section("Quick Filters") {
                    ForEach(TransactionFilter.QuickFilter.allCases, id: \.self) { filter in
                        Button {
                            options.quickFilter = filter
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if options.quickFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                // Classification Filter Section
                Section("Classification") {
                    ForEach(ClassificationType.allCases, id: \.self) { type in
                        Button {
                            toggleClassification(type)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(type.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: type.iconName)
                                            .foregroundStyle(type.color)
                                    )

                                Text(type.displayName)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedClassifications.contains(type) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                // Account Filter Section
                if !accounts.isEmpty {
                    Section("Accounts") {
                        ForEach(accounts) { account in
                            Button {
                                toggleAccount(account.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(account.displayName)
                                            .foregroundStyle(.primary)
                                        if let org = account.organizationName {
                                            Text(org)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if selectedAccounts.contains(account.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }

                // Date Range Section
                Section("Date Range") {
                    Button {
                        selectedDateRange = .all
                    } label: {
                        HStack {
                            Text("All Time")
                                .foregroundStyle(.primary)
                            Spacer()
                            if case .all = selectedDateRange {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    Button {
                        selectedDateRange = .thisMonth
                    } label: {
                        HStack {
                            Text("This Month")
                                .foregroundStyle(.primary)
                            Spacer()
                            if case .thisMonth = selectedDateRange {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    Button {
                        selectedDateRange = .lastMonth
                    } label: {
                        HStack {
                            Text("Last Month")
                                .foregroundStyle(.primary)
                            Spacer()
                            if case .lastMonth = selectedDateRange {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                // Clear Filters
                if !options.isEmpty || !selectedAccounts.isEmpty || !selectedClassifications.isEmpty || selectedDateRange != .all {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            clearFilters()
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCurrentFilters()
            }
        }
    }

    // MARK: - Actions

    private func toggleClassification(_ type: ClassificationType) {
        if selectedClassifications.contains(type) {
            selectedClassifications.remove(type)
        } else {
            selectedClassifications.insert(type)
        }
    }

    private func toggleAccount(_ accountId: String) {
        if selectedAccounts.contains(accountId) {
            selectedAccounts.remove(accountId)
        } else {
            selectedAccounts.insert(accountId)
        }
    }

    private func loadCurrentFilters() {
        selectedAccounts = options.accountIds
        selectedClassifications = options.classificationTypes
        selectedDateRange = options.dateRange
    }

    private func applyFilters() {
        options.accountIds = selectedAccounts
        options.classificationTypes = selectedClassifications
        options.dateRange = selectedDateRange
    }

    private func clearFilters() {
        selectedAccounts = []
        selectedClassifications = []
        selectedDateRange = .all
        options = TransactionFilter.Options()
    }
}

// MARK: - Preview

#Preview("Filter Sheet") {
    @Previewable @State var options = TransactionFilter.Options()

    let accounts = [
        Account(
            id: "acc1",
            organizationName: "Chase Bank",
            name: "Checking",
            currency: "USD",
            balance: "5000.00",
            availableBalance: "4500.00",
            balanceDate: Date(),
            accountTypeRaw: "checking"
        ),
        Account(
            id: "acc2",
            organizationName: "Chase Bank",
            name: "Savings",
            currency: "USD",
            balance: "10000.00",
            availableBalance: "10000.00",
            balanceDate: Date(),
            accountTypeRaw: "savings"
        )
    ]

    TransactionFilterSheet(options: $options, accounts: accounts)
}

#Preview("With Selections") {
    @Previewable @State var options: TransactionFilter.Options = {
        var opts = TransactionFilter.Options()
        opts.quickFilter = .thisMonth
        opts.classificationTypes = [.income, .expense]
        return opts
    }()

    TransactionFilterSheet(options: $options, accounts: [])
}
