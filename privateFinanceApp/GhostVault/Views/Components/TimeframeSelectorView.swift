//
//  TimeframeSelectorView.swift
//  GhostVault
//
//  Shared timeframe selector for chart views
//

import SwiftUI

struct TimeframeSelectorView: View {
    @Binding var selectedTimeframe: ChartTimeframe
    @Binding var showCustomDatePicker: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChartTimeframe.allCases) { timeframe in
                    Button {
                        if timeframe == .custom {
                            showCustomDatePicker = true
                        } else {
                            selectedTimeframe = timeframe
                        }
                    } label: {
                        Text(timeframe.displayName)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedTimeframe == timeframe
                                    ? Color.accentColor
                                    : Color(.systemGray5)
                            )
                            .foregroundStyle(
                                selectedTimeframe == timeframe
                                    ? .white
                                    : .primary
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
