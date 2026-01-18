//
//  Category.swift
//  GhostVault
//
//  Data model for transaction categories and auto-categorization rules
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var rules: [CategoryRule]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "tag",
        colorHex: String = "#808080",
        rules: [CategoryRule] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.rules = rules
    }

    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
}

// MARK: - Category Rule

struct CategoryRule: Codable, Hashable {
    var pattern: String
    var field: MatchField
    var matchType: MatchType

    enum MatchField: String, Codable, CaseIterable {
        case description
        case payee
        case memo
    }

    enum MatchType: String, Codable, CaseIterable {
        case contains
        case startsWith
        case endsWith
        case regex
    }

    func matches(transaction: Transaction) -> Bool {
        let value: String
        switch field {
        case .description:
            value = transaction.transactionDescription
        case .payee:
            value = transaction.payee ?? ""
        case .memo:
            value = transaction.memo ?? ""
        }

        let lowercasedValue = value.lowercased()
        let lowercasedPattern = pattern.lowercased()

        switch matchType {
        case .contains:
            return lowercasedValue.contains(lowercasedPattern)
        case .startsWith:
            return lowercasedValue.hasPrefix(lowercasedPattern)
        case .endsWith:
            return lowercasedValue.hasSuffix(lowercasedPattern)
        case .regex:
            return (try? NSRegularExpression(pattern: pattern, options: .caseInsensitive))
                .map { $0.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) != nil } ?? false
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
