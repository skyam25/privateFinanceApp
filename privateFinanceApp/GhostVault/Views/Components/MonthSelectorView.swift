//
//  MonthSelectorView.swift
//  GhostVault
//
//  Shared month navigation selector for category views
//

import SwiftUI

struct MonthSelectorView: View {
    @Binding var selectedMonth: Date
    let monthDisplayString: String
    let canGoForward: Bool

    var body: some View {
        HStack {
            Button {
                withAnimation {
                    selectedMonth = MonthlyIncomeCalculator.previousMonth(from: selectedMonth)
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.accent)
            }

            Spacer()

            Text(monthDisplayString)
                .font(.headline)

            Spacer()

            Button {
                withAnimation {
                    selectedMonth = MonthlyIncomeCalculator.nextMonth(from: selectedMonth)
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canGoForward ? .accent : .secondary.opacity(0.3))
            }
            .disabled(!canGoForward)
        }
    }
}
