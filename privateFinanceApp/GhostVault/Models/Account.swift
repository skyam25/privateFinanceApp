//
//  Account.swift
//  GhostVault
//
//  Data model for financial accounts from SimpleFIN
//

import Foundation
import SwiftData

@Model
final class Account {
    @Attribute(.unique) var id: String
    var organizationId: String?
    var organizationName: String?
    var name: String
    var currency: String?
    var balance: String // Store as string to preserve precision
    var availableBalance: String?
    var balanceDate: Date?
    var accountTypeRaw: String
    var isHidden: Bool // Whether to exclude from totals

    // Computed properties
    var balanceValue: Decimal {
        Decimal(string: balance) ?? 0
    }

    var availableBalanceValue: Decimal? {
        guard let available = availableBalance else { return nil }
        return Decimal(string: available)
    }

    var accountType: AccountType {
        AccountType(rawValue: accountTypeRaw) ?? .unknown
    }

    // MARK: - Initialization

    init(
        id: String,
        organizationId: String? = nil,
        organizationName: String? = nil,
        name: String,
        currency: String? = "USD",
        balance: String,
        availableBalance: String? = nil,
        balanceDate: Date? = nil,
        accountTypeRaw: String = "unknown",
        isHidden: Bool = false
    ) {
        self.id = id
        self.organizationId = organizationId
        self.organizationName = organizationName
        self.name = name
        self.currency = currency
        self.balance = balance
        self.availableBalance = availableBalance
        self.balanceDate = balanceDate
        self.accountTypeRaw = accountTypeRaw
        self.isHidden = isHidden
    }

    // Initialize from SimpleFIN API response
    convenience init(from apiAccount: SimpleFINAccount) {
        self.init(
            id: apiAccount.id,
            organizationId: apiAccount.org?.sfin_url,
            organizationName: apiAccount.org?.name,
            name: apiAccount.name,
            currency: apiAccount.currency,
            balance: apiAccount.balance,
            availableBalance: apiAccount.available_balance,
            balanceDate: apiAccount.balance_date.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            accountTypeRaw: apiAccount.accountTypeRaw
        )
    }

    // Update from SimpleFIN API response
    func update(from apiAccount: SimpleFINAccount) {
        self.organizationId = apiAccount.org?.sfin_url
        self.organizationName = apiAccount.org?.name
        self.name = apiAccount.name
        self.currency = apiAccount.currency
        self.balance = apiAccount.balance
        self.availableBalance = apiAccount.available_balance
        self.balanceDate = apiAccount.balance_date.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        self.accountTypeRaw = apiAccount.accountTypeRaw
    }
}

// MARK: - Account Type

enum AccountType: String, CaseIterable, Codable {
    case checking
    case savings
    case creditCard = "credit card"
    case investment
    case loan
    case mortgage
    case unknown

    var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .creditCard: return "Credit Card"
        case .investment: return "Investment"
        case .loan: return "Loan"
        case .mortgage: return "Mortgage"
        case .unknown: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .checking: return "banknote"
        case .savings: return "building.columns"
        case .creditCard: return "creditcard"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .loan: return "doc.text"
        case .mortgage: return "house"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .checking: return .blue
        case .savings: return .green
        case .creditCard: return .orange
        case .investment: return .purple
        case .loan: return .red
        case .mortgage: return .brown
        case .unknown: return .gray
        }
    }
}

import SwiftUI
