//
//  CategoryMatcher.swift
//  GhostVault
//
//  Utility for auto-categorizing transactions using merchant pattern matching
//

import Foundation
import SwiftData

/// Auto-categorizes transactions based on merchant patterns
struct CategoryMatcher {

    // MARK: - Category Definitions

    /// All spending categories with their associated patterns
    static let categoryPatterns: [String: [String]] = [
        // Dining & Restaurants
        "Dining": [
            "mcdonald", "mcdonalds", "burger king", "wendy's", "wendys",
            "taco bell", "chipotle", "subway", "panera", "chick-fil-a",
            "starbucks", "dunkin", "panda express", "five guys", "in-n-out",
            "olive garden", "applebee", "chili's", "outback", "red lobster",
            "cheesecake factory", "ihop", "denny", "waffle house",
            "domino", "pizza hut", "papa john", "little caesar",
            "doordash", "uber eats", "grubhub", "postmates", "seamless",
            "restaurant", "cafe", "bistro", "grill", "diner", "eatery",
            "tavern", "steakhouse", "sushi", "thai", "chinese", "mexican",
            "italian", "indian", "korean", "japanese", "vietnamese", "greek"
        ],

        // Groceries
        "Groceries": [
            "whole foods", "trader joe", "safeway", "kroger", "publix",
            "albertson", "vons", "ralph's", "ralphs", "giant", "shoprite",
            "stop & shop", "food lion", "harris teeter", "h-e-b", "heb",
            "aldi", "lidl", "wegman", "costco", "sam's club", "bj's",
            "sprouts", "natural grocers", "fresh market", "grocery outlet",
            "food 4 less", "food4less", "winco", "meijer", "piggly wiggly",
            "grocery", "supermarket", "market basket", "hannaford"
        ],

        // Shopping
        "Shopping": [
            "amazon", "walmart", "target", "best buy", "costco",
            "home depot", "lowe's", "lowes", "ikea", "bed bath",
            "kohls", "kohl's", "macy's", "macys", "nordstrom", "jcpenney",
            "ross", "tjmaxx", "tj maxx", "marshalls", "burlington",
            "old navy", "gap", "banana republic", "h&m", "zara", "forever 21",
            "foot locker", "nike", "adidas", "dick's sporting",
            "bath & body", "sephora", "ulta", "cvs", "walgreens", "rite aid",
            "dollar tree", "dollar general", "five below", "big lots",
            "michaels", "hobby lobby", "joann", "craft", "office depot",
            "staples", "apple store", "microsoft store", "gamestop",
            "wayfair", "overstock", "pier 1", "crate & barrel", "pottery barn"
        ],

        // Transportation
        "Transportation": [
            "shell", "chevron", "exxon", "mobil", "bp", "arco",
            "76", "valero", "marathon", "speedway", "wawa", "sheetz",
            "quiktrip", "kwik trip", "racetrac", "circle k", "pilot",
            "loves", "love's", "flying j", "ta travel",
            "uber trip", "uber *trip", "lyft", "taxi", "cab",
            "dmv", "toll", "parking", "garage",
            "jiffy lube", "firestone", "midas", "pep boys", "autozone",
            "o'reilly", "napa auto", "advance auto", "carwash",
            "enterprise", "hertz", "avis", "budget rent", "national rent"
        ],

        // Bills & Utilities
        "Bills & Utilities": [
            "electric", "power", "energy", "water", "sewer", "gas company",
            "pg&e", "pge", "con edison", "coned", "duke energy", "dominion",
            "xcel", "national grid", "entergy", "aep", "dte energy",
            "at&t", "verizon", "t-mobile", "tmobile", "sprint", "comcast",
            "xfinity", "spectrum", "cox", "frontier", "centurylink",
            "optimum", "dish", "directv", "internet", "cable", "phone bill",
            "waste management", "republic services", "garbage", "trash",
            "homeowner", "hoa", "condo association"
        ],

        // Entertainment
        "Entertainment": [
            "netflix", "hulu", "disney+", "disney plus", "hbo", "max",
            "amazon prime", "apple tv", "peacock", "paramount+", "paramount plus",
            "spotify", "apple music", "pandora", "tidal", "youtube premium",
            "audible", "kindle unlimited", "playstation", "xbox", "nintendo",
            "steam", "epic games", "twitch", "patreon",
            "amc", "regal", "cinemark", "movie theater", "cinema",
            "bowling", "arcade", "dave & buster", "escape room",
            "museum", "zoo", "aquarium", "theme park", "amusement",
            "concert", "ticketmaster", "stubhub", "vivid seats", "eventbrite"
        ],

        // Health & Fitness
        "Health & Fitness": [
            "gym", "fitness", "planet fitness", "la fitness", "24 hour fitness",
            "equinox", "orangetheory", "crossfit", "peloton", "soulcycle",
            "yoga", "pilates", "martial arts",
            "pharmacy", "cvs", "walgreens", "rite aid", "prescription",
            "doctor", "physician", "dentist", "orthodontist", "optometrist",
            "hospital", "clinic", "urgent care", "lab", "labcorp", "quest",
            "therapist", "chiropractor", "physical therapy", "massage",
            "vitamin", "gnc", "supplement", "wellness"
        ],

        // Travel
        "Travel": [
            "airline", "delta", "united", "american airlines", "southwest",
            "jetblue", "spirit", "frontier", "alaska air",
            "hotel", "marriott", "hilton", "hyatt", "ihg", "wyndham",
            "best western", "holiday inn", "hampton inn", "courtyard",
            "airbnb", "vrbo", "booking.com", "expedia", "kayak", "orbitz",
            "priceline", "hotels.com", "tripadvisor", "travelocity",
            "tsa", "airport", "amtrak", "greyhound", "cruise"
        ],

        // Subscriptions
        "Subscriptions": [
            "subscription", "monthly", "annual",
            "netflix", "spotify", "hulu", "disney+", "hbo", "apple music",
            "adobe", "microsoft 365", "office 365", "google one", "icloud",
            "dropbox", "evernote", "notion", "slack", "zoom",
            "linkedin premium", "dating app", "tinder", "bumble", "hinge",
            "newspaper", "new york times", "washington post", "wall street journal",
            "magazine", "membership"
        ],

        // Personal Care
        "Personal Care": [
            "salon", "barber", "hair", "spa", "massage", "nail",
            "manicure", "pedicure", "waxing", "facial", "skincare",
            "sephora", "ulta", "beauty", "cosmetic", "makeup"
        ],

        // Education
        "Education": [
            "tuition", "college", "university", "school", "course",
            "udemy", "coursera", "linkedin learning", "skillshare",
            "masterclass", "brilliant", "book", "textbook", "tutoring",
            "student loan", "education"
        ],

        // Insurance
        "Insurance": [
            "geico", "progressive", "state farm", "allstate", "liberty mutual",
            "farmers", "usaa", "nationwide", "travelers", "amica",
            "insurance", "premium", "coverage"
        ],

        // Pets
        "Pets": [
            "petco", "petsmart", "pet supplies plus", "chewy",
            "veterinary", "vet", "animal hospital", "pet",
            "dog", "cat", "grooming"
        ]
    ]

    // MARK: - Pattern Matching

    /// Detect the category for a transaction based on merchant patterns
    /// - Parameter transaction: The transaction to categorize
    /// - Returns: The matched category and reason, or nil if no match
    static func detectCategory(_ transaction: Transaction) -> (category: String, reason: String)? {
        // Skip if already classified manually or by payee rule
        let priority = ClassificationPriority.from(reason: transaction.classificationReason)
        if priority >= .manual {
            return nil
        }

        // Skip transfers and income
        if let cat = transaction.category?.lowercased() {
            if cat == "transfer" || cat == "income" || cat == "salary" {
                return nil
            }
        }

        // Skip positive amounts (likely income/refunds)
        guard transaction.amountValue < 0 else { return nil }

        // Check description and payee
        let textToCheck = [
            transaction.transactionDescription,
            transaction.payee ?? "",
            transaction.memo ?? ""
        ].joined(separator: " ").lowercased()

        // Find matching category
        for (category, patterns) in categoryPatterns {
            for pattern in patterns {
                if textToCheck.contains(pattern.lowercased()) {
                    return (category, "Pattern: \(pattern.capitalized)")
                }
            }
        }

        return nil
    }

    // MARK: - Classification

    /// Apply category to a transaction
    /// - Parameters:
    ///   - transaction: The transaction to classify
    ///   - category: The category to apply
    ///   - reason: The reason for classification
    static func applyCategory(to transaction: Transaction, category: String, reason: String) {
        transaction.category = category
        transaction.classificationReason = reason
    }

    /// Process a transaction and categorize if it matches any pattern
    /// - Parameter transaction: The transaction to process
    /// - Returns: True if the transaction was categorized
    @discardableResult
    static func processTransaction(_ transaction: Transaction) -> Bool {
        guard let (category, reason) = detectCategory(transaction) else {
            return false
        }

        applyCategory(to: transaction, category: category, reason: reason)
        return true
    }

    /// Process multiple transactions
    /// - Parameter transactions: The transactions to process
    /// - Returns: Count of transactions categorized
    @discardableResult
    static func processTransactions(_ transactions: [Transaction]) -> Int {
        var count = 0
        for transaction in transactions {
            if processTransaction(transaction) {
                count += 1
            }
        }
        return count
    }

    // MARK: - User Rule Creation

    /// Create a classification rule from a user correction
    /// - Parameters:
    ///   - payee: The payee to match
    ///   - category: The category to assign
    ///   - modelContext: SwiftData context for persistence
    /// - Returns: The created rule
    @discardableResult
    static func createRuleFromCorrection(
        payee: String,
        category: String,
        classificationType: String = "expense",
        in modelContext: ModelContext
    ) -> ClassificationRule {
        // Check if rule already exists
        let lowercasedPayee = payee.lowercased()
        let predicate = #Predicate<ClassificationRule> { rule in
            rule.payee.localizedStandardContains(lowercasedPayee)
        }

        let descriptor = FetchDescriptor<ClassificationRule>(predicate: predicate)

        if let existingRules = try? modelContext.fetch(descriptor),
           let existing = existingRules.first {
            // Update existing rule
            existing.category = category
            existing.classificationType = classificationType
            existing.isActive = true
            return existing
        }

        // Create new rule
        let rule = ClassificationRule(
            payee: payee,
            category: category,
            classificationType: classificationType
        )
        modelContext.insert(rule)
        return rule
    }

    /// Apply user rules to a transaction
    /// - Parameters:
    ///   - transaction: The transaction to check
    ///   - rules: Active classification rules
    /// - Returns: True if a rule was applied
    @discardableResult
    static func applyUserRules(to transaction: Transaction, rules: [ClassificationRule]) -> Bool {
        for rule in rules where rule.isActive {
            if rule.matches(transaction) {
                rule.apply(to: transaction)
                return true
            }
        }
        return false
    }

    // MARK: - Statistics

    /// Count uncategorized transactions
    /// - Parameter transactions: All transactions
    /// - Returns: Count of transactions without a category
    static func countUncategorized(in transactions: [Transaction]) -> Int {
        transactions.filter { transaction in
            !transaction.isIgnored &&
            (transaction.category == nil || transaction.category?.isEmpty == true) &&
            transaction.amountValue < 0
        }.count
    }

    /// Get all category names
    static var allCategories: [String] {
        Array(categoryPatterns.keys).sorted()
    }

    /// Get patterns for a specific category
    static func patterns(for category: String) -> [String]? {
        categoryPatterns[category]
    }

    /// Check if a specific pattern matches text
    static func patternMatches(_ pattern: String, in text: String) -> Bool {
        text.lowercased().contains(pattern.lowercased())
    }
}
