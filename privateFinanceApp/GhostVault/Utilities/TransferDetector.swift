//
//  TransferDetector.swift
//  GhostVault
//
//  Utility for detecting and matching transfer transactions across accounts
//

import Foundation

/// Detects and matches transfer transactions across different accounts
struct TransferDetector {

    // MARK: - Configuration

    /// Maximum number of days between matched transfer transactions
    static let maxDaysDifference: Int = 3

    // MARK: - Transfer Detection

    /// Represents a matched pair of transfer transactions
    struct TransferMatch {
        let outgoing: Transaction
        let incoming: Transaction
    }

    /// Detect all transfer matches in a list of transactions
    /// - Parameter transactions: All transactions to analyze
    /// - Returns: Array of matched transfer pairs
    static func detectTransfers(in transactions: [Transaction]) -> [TransferMatch] {
        // Filter to eligible transactions (not pending, not already matched)
        let eligible = transactions.filter { !$0.pending && $0.matchedTransferId == nil }

        // Separate into outgoing (negative) and incoming (positive)
        let outgoing = eligible.filter { $0.amountValue < 0 }
        let incoming = eligible.filter { $0.amountValue > 0 }

        var matches: [TransferMatch] = []
        var matchedOutgoingIds: Set<String> = []
        var matchedIncomingIds: Set<String> = []

        // For each outgoing transaction, find a matching incoming
        for out in outgoing {
            // Skip if already matched
            if matchedOutgoingIds.contains(out.id) { continue }

            // Look for matching incoming transaction
            if let match = findMatch(for: out, in: incoming, excludedIds: matchedIncomingIds) {
                matches.append(TransferMatch(outgoing: out, incoming: match))
                matchedOutgoingIds.insert(out.id)
                matchedIncomingIds.insert(match.id)
            }
        }

        return matches
    }

    /// Find a matching incoming transaction for an outgoing transaction
    /// - Parameters:
    ///   - outgoing: The outgoing (negative amount) transaction
    ///   - candidates: Potential matching incoming transactions
    ///   - excludedIds: IDs of already matched transactions to exclude
    /// - Returns: The best matching transaction, or nil if none found
    static func findMatch(
        for outgoing: Transaction,
        in candidates: [Transaction],
        excludedIds: Set<String>
    ) -> Transaction? {
        let outgoingAmount = abs(outgoing.amountValue)

        return candidates.first { incoming in
            // Skip if already matched
            guard !excludedIds.contains(incoming.id) else { return false }

            // Must be from a different account
            guard incoming.accountId != outgoing.accountId else { return false }

            // Amounts must match (absolute values)
            guard incoming.amountValue == outgoingAmount else { return false }

            // Must be within date range
            guard isWithinDateRange(outgoing.posted, incoming.posted) else { return false }

            return true
        }
    }

    /// Check if two dates are within the allowed range
    static func isWithinDateRange(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let daysDifference = abs(calendar.dateComponents([.day], from: date1, to: date2).day ?? 0)
        return daysDifference <= maxDaysDifference
    }

    // MARK: - Apply Transfer Matches

    /// Apply transfer matches by updating the matched transactions
    /// - Parameters:
    ///   - matches: The detected transfer matches
    ///   - completion: Closure called after all updates are applied
    static func applyMatches(_ matches: [TransferMatch]) {
        for match in matches {
            // Link the transactions
            match.outgoing.matchedTransferId = match.incoming.id
            match.incoming.matchedTransferId = match.outgoing.id

            // Update category and classification reason
            match.outgoing.category = "Transfer"
            match.outgoing.classificationReason = "Auto-Transfer"

            match.incoming.category = "Transfer"
            match.incoming.classificationReason = "Auto-Transfer"
        }
    }

    /// Process transactions to detect and apply transfer matches
    /// - Parameter transactions: All transactions to process
    /// - Returns: Number of transfer pairs matched
    @discardableResult
    static func processTransfers(_ transactions: [Transaction]) -> Int {
        let matches = detectTransfers(in: transactions)
        applyMatches(matches)
        return matches.count
    }

    // MARK: - Transfer Validation

    /// Check if a transaction looks like an internal transfer based on description
    /// - Parameter transaction: The transaction to check
    /// - Returns: True if the transaction appears to be an internal transfer
    static func looksLikeTransfer(_ transaction: Transaction) -> Bool {
        let description = transaction.transactionDescription.lowercased()
        let payee = transaction.payee?.lowercased() ?? ""

        let transferKeywords = [
            "transfer",
            "xfer",
            "tfr",
            "move money",
            "internal",
            "between accounts"
        ]

        return transferKeywords.contains { keyword in
            description.contains(keyword) || payee.contains(keyword)
        }
    }

    /// Unmatch a previously matched transfer pair
    /// - Parameters:
    ///   - transaction1: First transaction in the pair
    ///   - transaction2: Second transaction in the pair
    static func unmatchTransfer(transaction1: Transaction, transaction2: Transaction) {
        // Clear the match links
        transaction1.matchedTransferId = nil
        transaction2.matchedTransferId = nil

        // Reset classification if it was auto-transfer
        if transaction1.classificationReason == "Auto-Transfer" {
            transaction1.category = nil
            transaction1.classificationReason = "Default"
        }
        if transaction2.classificationReason == "Auto-Transfer" {
            transaction2.category = nil
            transaction2.classificationReason = "Default"
        }
    }

    // MARK: - Statistics

    /// Count unmatched potential transfers
    /// - Parameter transactions: All transactions to analyze
    /// - Returns: Count of transactions that look like transfers but aren't matched
    static func countUnmatchedTransfers(in transactions: [Transaction]) -> Int {
        transactions.filter { looksLikeTransfer($0) && $0.matchedTransferId == nil }.count
    }

    /// Get all matched transfer pairs from a list of transactions
    /// - Parameter transactions: All transactions
    /// - Returns: Array of transaction IDs that are matched transfers
    static func matchedTransferIds(in transactions: [Transaction]) -> Set<String> {
        var ids: Set<String> = []
        for transaction in transactions {
            if let matchId = transaction.matchedTransferId {
                ids.insert(transaction.id)
                ids.insert(matchId)
            }
        }
        return ids
    }
}
