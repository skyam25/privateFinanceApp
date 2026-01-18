//
//  SyncStatusBar.swift
//  GhostVault
//
//  Dashboard component showing sync status and controls
//

import SwiftUI

struct SyncStatusBar: View {
    @Binding var rateLimiter: SyncRateLimiter
    let onSync: () async -> Void

    @State private var isSyncing = false

    var body: some View {
        HStack(spacing: 16) {
            // Last sync info
            VStack(alignment: .leading, spacing: 2) {
                Text("Last synced")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(rateLimiter.formattedLastSyncTime)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            // Rate limit indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text("Daily syncs")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text(rateLimiter.formattedRemainingSyncs)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(rateLimitColor)

                    if !rateLimiter.canSync, let resetTime = rateLimiter.formattedTimeUntilReset {
                        Text("(\(resetTime))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Sync button
            Button {
                Task {
                    await performSync()
                }
            } label: {
                Group {
                    if isSyncing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isSyncing || !rateLimiter.canSync)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Computed Properties

    private var rateLimitColor: Color {
        if rateLimiter.remainingSyncs == 0 {
            return .red
        } else if rateLimiter.remainingSyncs <= 5 {
            return .orange
        } else {
            return .primary
        }
    }

    // MARK: - Actions

    private func performSync() async {
        guard rateLimiter.canSync, !isSyncing else { return }

        isSyncing = true
        rateLimiter.recordSync()

        await onSync()

        isSyncing = false
    }
}

// MARK: - Preview

#Preview("Available Syncs") {
    PreviewWrapper(remainingSyncs: 18)
}

#Preview("Low Syncs") {
    PreviewWrapper(remainingSyncs: 3)
}

#Preview("No Syncs Left") {
    PreviewWrapper(remainingSyncs: 0)
}

private struct PreviewWrapper: View {
    @State var limiter: SyncRateLimiter

    init(remainingSyncs: Int) {
        var limiter = SyncRateLimiter()
        let syncsUsed = SyncRateLimiter.maxDailySyncs - remainingSyncs
        for _ in 0..<syncsUsed {
            limiter.recordSync()
        }
        _limiter = State(initialValue: limiter)
    }

    var body: some View {
        VStack {
            SyncStatusBar(rateLimiter: $limiter) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            Spacer()
        }
    }
}
