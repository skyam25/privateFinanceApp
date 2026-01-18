//
//  ExpandableCardContainer.swift
//  GhostVault
//
//  Shared expandable card container for dashboard cards
//

import SwiftUI

struct ExpandableCardContainer<MainContent: View, ExpandedContent: View>: View {
    @Binding var isExpanded: Bool
    @ViewBuilder let mainContent: () -> MainContent
    @ViewBuilder let expandedContent: () -> ExpandedContent

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                mainContent()
            }
            .buttonStyle(.plain)

            // Expanded breakdown
            if isExpanded {
                Divider()
                    .padding(.horizontal)

                expandedContent()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}
