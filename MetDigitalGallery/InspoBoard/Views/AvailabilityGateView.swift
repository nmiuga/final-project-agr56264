//
//  AvailabilityGateView.swift
//  MetDigitalGallery — Inspo Board feature
//
//  Graceful fallback shown when Foundation Models isn't available —
//  most commonly because the device isn't Apple Intelligence-eligible,
//  the OS is below iOS 26, or Apple Intelligence is disabled.
//

import SwiftUI

// MARK: - AvailabilityGateView

struct AvailabilityGateView: View {
    /// Reason surfaced by SystemLanguageModel.default.availability.
    let reason: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Color.terracotta)

            Text("Apple Intelligence Required")
                .font(.galleryDisplay(22))

            Text(reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link("Open Settings", destination: url)
                    .font(.subheadline)
                    .foregroundStyle(Color.terracotta)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cream)
    }
}

#Preview {
    AvailabilityGateView(
        reason: "This device doesn't support Apple Intelligence. The inspo board feature needs an A17 Pro or M-series chip running iOS 26 or later."
    )
}
