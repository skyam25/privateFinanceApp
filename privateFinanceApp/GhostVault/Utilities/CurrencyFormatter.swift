//
//  CurrencyFormatter.swift
//  GhostVault
//
//  Shared currency formatting utilities
//

import Foundation

enum CurrencyFormatter {
    static func format(_ value: Decimal, maximumFractionDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }

    static func formatCompact(_ value: Decimal) -> String {
        let doubleValue = NSDecimalNumber(decimal: abs(value)).doubleValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"

        let prefix = value < 0 ? "-" : ""

        if doubleValue >= 1_000_000 {
            formatter.maximumFractionDigits = 1
            return "\(prefix)\(formatter.string(from: NSNumber(value: doubleValue / 1_000_000)) ?? "$0")M"
        } else if doubleValue >= 1_000 {
            formatter.maximumFractionDigits = 0
            return "\(prefix)\(formatter.string(from: NSNumber(value: doubleValue / 1_000)) ?? "$0")K"
        } else {
            formatter.maximumFractionDigits = 0
            return formatter.string(from: value as NSDecimalNumber) ?? "$0"
        }
    }
}
