//
//  RulesManagementView.swift
//  GhostVault
//
//  Manage transaction classification rules
//

import SwiftUI
import SwiftData

// MARK: - Shared Category Color Mapping

private let categoryColorMap: [String: Color] = [
    "dining": .orange, "food & dining": .orange, "restaurants": .orange,
    "groceries": .green,
    "shopping": .purple,
    "transportation": .blue,
    "bills & utilities": .yellow, "utilities": .yellow,
    "entertainment": .pink,
    "health & fitness": .red, "health": .red,
    "travel": .cyan,
    "subscriptions": .indigo,
    "personal care": .mint,
    "education": .brown,
    "insurance": .gray,
    "pets": .orange,
    "income": .green, "salary": .green,
    "transfer": .blue
]

private func categoryColor(for category: String) -> Color {
    categoryColorMap[category.lowercased()] ?? .secondary
}

struct RulesManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClassificationRule.createdAt, order: .reverse) private var rules: [ClassificationRule]

    @State private var showAddRule = false
    @State private var selectedRule: ClassificationRule?
    @State private var showDeleteConfirmation = false
    @State private var ruleToDelete: ClassificationRule?

    var body: some View {
        List {
            if rules.isEmpty {
                ContentUnavailableView {
                    Label("No Rules", systemImage: "list.bullet.rectangle")
                } description: {
                    Text("Transaction rules let you automatically categorize transactions from specific payees.")
                } actions: {
                    Button("Add Rule") {
                        showAddRule = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                // User-created rules section
                let userRules = rules.filter { $0.isUserCreated }
                if !userRules.isEmpty {
                    Section("Your Rules") {
                        ForEach(userRules) { rule in
                            RuleRowView(rule: rule, onToggle: { toggleRule(rule) })
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedRule = rule
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        ruleToDelete = rule
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }

                // Auto-generated rules section
                let autoRules = rules.filter { !$0.isUserCreated }
                if !autoRules.isEmpty {
                    Section {
                        ForEach(autoRules) { rule in
                            RuleRowView(rule: rule, onToggle: { toggleRule(rule) })
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedRule = rule
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        ruleToDelete = rule
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        Text("Auto-Generated")
                    } footer: {
                        Text("These rules were created automatically based on your categorization patterns.")
                    }
                }
            }
        }
        .navigationTitle("Transaction Rules")
        .toolbar {
            if !rules.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddRule = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddRule) {
            RuleEditorSheet(rule: nil) { payee, category, classificationType in
                addRule(payee: payee, category: category, classificationType: classificationType)
            }
        }
        .sheet(item: $selectedRule) { rule in
            RuleEditorSheet(rule: rule) { payee, category, classificationType in
                updateRule(rule, payee: payee, category: category, classificationType: classificationType)
            }
        }
        .confirmationDialog(
            "Delete Rule?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let rule = ruleToDelete {
                    deleteRule(rule)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let rule = ruleToDelete {
                Text("Delete the rule for \"\(rule.payee)\"? This cannot be undone.")
            }
        }
    }

    // MARK: - Actions

    private func toggleRule(_ rule: ClassificationRule) {
        rule.isActive.toggle()
    }

    private func addRule(payee: String, category: String, classificationType: String) {
        let rule = ClassificationRule(
            payee: payee,
            category: category,
            classificationType: classificationType,
            isUserCreated: true
        )
        modelContext.insert(rule)
    }

    private func updateRule(_ rule: ClassificationRule, payee: String, category: String, classificationType: String) {
        rule.payee = payee
        rule.category = category
        rule.classificationType = classificationType
    }

    private func deleteRule(_ rule: ClassificationRule) {
        modelContext.delete(rule)
        ruleToDelete = nil
    }
}

// MARK: - Rule Row View

struct RuleRowView: View {
    let rule: ClassificationRule
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            categoryIcon
                .frame(width: 40, height: 40)
                .background(categoryColor(for: rule.category).opacity(0.15))
                .clipShape(Circle())

            // Rule info
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.payee)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Category badge
                    Text(rule.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Type badge
                    Text(rule.classificationType.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor.opacity(0.15))
                        .foregroundStyle(typeColor)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            // Active toggle
            Toggle("", isOn: .init(
                get: { rule.isActive },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
        .opacity(rule.isActive ? 1.0 : 0.5)
    }

    // MARK: - Computed Properties

    private var categoryIcon: some View {
        Image(systemName: TransactionCategory.icon(for: rule.category))
            .font(.system(size: 18))
            .foregroundStyle(categoryColor(for: rule.category))
    }

    private var typeColor: Color {
        switch rule.classificationType.lowercased() {
        case "income":
            return .green
        case "expense":
            return .red
        case "transfer":
            return .blue
        case "ignored":
            return .gray
        default:
            return .primary
        }
    }
}

// MARK: - Rule Editor Sheet

struct RuleEditorSheet: View {
    let rule: ClassificationRule?
    let onSave: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var payee: String = ""
    @State private var selectedCategory: String = "Other"
    @State private var selectedType: String = "expense"

    private let categories = [
        "Dining", "Groceries", "Shopping", "Transportation",
        "Bills & Utilities", "Entertainment", "Health & Fitness",
        "Travel", "Subscriptions", "Personal Care", "Education",
        "Insurance", "Pets", "Income", "Transfer", "Other"
    ]

    private let types = ["expense", "income", "transfer", "ignored"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Payee Name", text: $payee)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Match Pattern")
                } footer: {
                    Text("Transactions with this payee in their description will be categorized automatically.")
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            HStack {
                                Image(systemName: TransactionCategory.icon(for: category))
                                    .foregroundStyle(categoryColor(for: category))
                                Text(category)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Type") {
                    Picker("Classification Type", selection: $selectedType) {
                        ForEach(types, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(rule == nil ? "New Rule" : "Edit Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(payee, selectedCategory, selectedType)
                        dismiss()
                    }
                    .disabled(payee.isEmpty)
                }
            }
            .onAppear {
                if let rule = rule {
                    payee = rule.payee
                    selectedCategory = rule.category
                    selectedType = rule.classificationType
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("With Rules") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ClassificationRule.self, configurations: config)

    // Add sample rules
    let context = container.mainContext

    let rule1 = ClassificationRule(
        payee: "Chipotle",
        category: "Dining",
        classificationType: "expense",
        isUserCreated: true
    )
    context.insert(rule1)

    let rule2 = ClassificationRule(
        payee: "Amazon",
        category: "Shopping",
        classificationType: "expense",
        isUserCreated: true
    )
    context.insert(rule2)

    let rule3 = ClassificationRule(
        payee: "ACME Corp",
        category: "Income",
        classificationType: "income",
        isUserCreated: false
    )
    context.insert(rule3)

    return NavigationStack {
        RulesManagementView()
    }
    .modelContainer(container)
}

#Preview("Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ClassificationRule.self, configurations: config)

    return NavigationStack {
        RulesManagementView()
    }
    .modelContainer(container)
}
