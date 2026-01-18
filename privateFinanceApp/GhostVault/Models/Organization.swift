//
//  Organization.swift
//  GhostVault
//
//  Data model for financial institutions/organizations
//

import Foundation
import SwiftData

@Model
final class Organization {
    @Attribute(.unique) var id: String
    var name: String
    var domain: String?
    var url: String?

    init(id: String, name: String, domain: String? = nil, url: String? = nil) {
        self.id = id
        self.name = name
        self.domain = domain
        self.url = url
    }

    // Initialize from SimpleFIN API response
    convenience init(from apiOrg: SimpleFINOrganization) {
        self.init(
            id: apiOrg.sfin_url,
            name: apiOrg.name,
            domain: apiOrg.domain,
            url: apiOrg.url
        )
    }
}
