//
//  CustomDatePickerSheet.swift
//  GhostVault
//
//  Shared date picker sheet for chart timeframe selection
//

import SwiftUI

struct CustomDatePickerSheet: View {
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date
    @Binding var selectedTimeframe: ChartTimeframe
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker(
                        "Start Date",
                        selection: $customStartDate,
                        in: ...customEndDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        "End Date",
                        selection: $customEndDate,
                        in: customStartDate...,
                        displayedComponents: .date
                    )
                }

                Section {
                    Button("Apply") {
                        selectedTimeframe = .custom
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Custom Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
