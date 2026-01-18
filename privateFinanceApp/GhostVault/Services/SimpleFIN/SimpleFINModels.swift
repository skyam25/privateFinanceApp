//
//  SimpleFINModels.swift
//  GhostVault
//
//  API response models for SimpleFIN Bridge
//  Based on SimpleFIN Protocol specification
//

import Foundation

// MARK: - Account Set Response

struct SimpleFINAccountSet: Codable {
    let errors: [String]
    let accounts: [SimpleFINAccount]
}

// MARK: - Account

struct SimpleFINAccount: Codable {
    let id: String
    let org: SimpleFINOrganization?
    let name: String
    let currency: String
    let balance: String
    let available_balance: String?
    let balance_date: Int?
    let transactions: [SimpleFINTransaction]

    // Extra fields that may be present
    let holdings: [SimpleFINHolding]?

    // Computed property to determine account type (not provided by API)
    var accountTypeRaw: String {
        // SimpleFIN doesn't provide account type directly
        // Infer from name or other heuristics
        let nameLower = name.lowercased()
        if nameLower.contains("checking") { return "checking" }
        if nameLower.contains("saving") { return "savings" }
        if nameLower.contains("credit") { return "credit card" }
        if nameLower.contains("investment") || nameLower.contains("brokerage") { return "investment" }
        if nameLower.contains("loan") { return "loan" }
        if nameLower.contains("mortgage") { return "mortgage" }
        return "unknown"
    }
}

// MARK: - Organization

struct SimpleFINOrganization: Codable {
    let sfin_url: String
    let name: String
    let domain: String?
    let url: String?
}

// MARK: - Transaction

struct SimpleFINTransaction: Codable {
    let id: String
    let posted: Int
    let amount: String
    let description: String
    let payee: String?
    let memo: String?
    let pending: Bool?
    let transacted_at: Int?
}

// MARK: - Holding (for investment accounts)

struct SimpleFINHolding: Codable {
    let id: String
    let created: Int
    let currency: String
    let cost_basis: String?
    let description: String?
    let market_value: String?
    let purchase_price: String?
    let shares: String?
    let symbol: String?
}
