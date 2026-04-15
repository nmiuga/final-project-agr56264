//
//  ProfileView.swift
//  MetDigitalGallery
//
//  Created by Allison Ramirez on 4/1/26.
//
//  PROFILE tab — user profile placeholder.
//

import SwiftUI

struct ProfileView: View {

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text("MET Inspo")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                Spacer()
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.cream)

            Divider().opacity(0.3)

            ScrollView {
                VStack(spacing: 24) {
                    // Avatar placeholder
                    Circle()
                        .fill(Color.creamDark)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.terracotta.opacity(0.6))
                        )
                        .padding(.top, 40)

                    VStack(spacing: 6) {
                        Text("Art Enthusiast")
                            .font(.galleryDisplay(22))
                            .foregroundStyle(.primary)
                        Text("Metropolitan Museum Member")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider().padding(.horizontal, 40)

                    VStack(alignment: .leading, spacing: 0) {
                        ProfileRow(icon: "heart", label: "Saved Artworks")
                        ProfileRow(icon: "clock", label: "Recently Viewed")
                        ProfileRow(icon: "square.and.arrow.up", label: "Share Collection")
                        ProfileRow(icon: "gear", label: "Settings")
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .background(Color.cream)
        .navigationBarHidden(true)
    }
}

private struct ProfileRow: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.terracotta)
                .frame(width: 28)
            Text(label)
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 16)
        Divider().opacity(0.35)
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
