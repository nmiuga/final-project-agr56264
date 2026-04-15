//
//  ArtworkListView.swift — contains HomeView
//  MetDigitalGallery
//
//  Created by Allison Ramirez on 4/1/26.
//
//  PROJECT 2 — Home Feed (matches Figma "Home Feed" screen)
//
//  Layout:
//    • Custom nav header: ☰  MET Inspo  🔍
//    • "Curated Visions" large serif headline in terracotta
//    • Tagline subtitle in gray
//    • Vertical scroll of artwork cards:
//        [Full-width image]
//        DEPARTMENT LABEL  ← small caps, terracotta, tracked (galleryLabelStyle)
//        Artwork Title     ← large serif bold (galleryDisplay)
//        Artist, Year      ← small gray
//        ─────────────── ← thin divider
//
//  Data: ArtworkViewModel fetches live data from the Met Museum API via URLSession.
//  Each card is a NavigationLink → ArtworkDetailView.
//

import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    // @StateObject keeps the ViewModel alive for this view's full lifetime.
    // Using @ObservedObject instead would risk the ViewModel being destroyed
    // when the parent re-renders.
    @StateObject private var viewModel = ArtworkViewModel()

    var body: some View {
        VStack(spacing: 0) {

            // Custom top bar — replaces the default SwiftUI NavigationStack bar
            HomeNavBar()
            Divider().opacity(0.3)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // "Curated Visions" hero text block
                    heroBanner

                    // Switch on ViewModel state to show the right UI
                    if viewModel.isLoading {
                        loadingBlock
                    } else if let error = viewModel.errorMessage {
                        errorBlock(message: error)
                    } else if viewModel.artworks.isEmpty {
                        emptyBlock
                    } else {
                        artworkCards
                    }
                }
            }
        }
        .background(Color.cream)
        // We use HomeNavBar, so hide SwiftUI's default navigation chrome
        .navigationBarHidden(true)
        .onAppear {
            // Only fetch on first appearance; preserve data when navigating back
            if viewModel.artworks.isEmpty {
                viewModel.loadArtworks()
            }
        }
    }

    // MARK: - Hero Banner

    // "Curated Visions" + tagline — always visible above the card list.
    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Curated Visions")
                .font(.galleryDisplay(42))
                .foregroundStyle(Color.terracotta)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    // MARK: - Artwork Cards

    // LazyVStack renders each row on demand as the user scrolls — efficient for long lists.
    // Each row is a NavigationLink so tapping pushes ArtworkDetailView onto the stack.
    private var artworkCards: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.artworks) { artwork in
                NavigationLink(destination: ArtworkDetailView(artwork: artwork)) {
                    ArtworkCardView(artwork: artwork)
                }
                // .plain prevents NavigationLink from applying its default blue tint
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - State Blocks

    // Loading spinner shown while URLSession requests are in flight
    private var loadingBlock: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.3)
            Text("Loading collection…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // Empty state before the first load completes
    private var emptyBlock: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns")
                .font(.system(size: 48))
                .foregroundStyle(Color.terracotta.opacity(0.4))
            Text("No artworks yet")
                .font(.galleryHeadline(18))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // Error state with retry button
    private func errorBlock(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Color.terracotta)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            Button("Try Again") { viewModel.loadArtworks() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.terracotta)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

// MARK: - HomeNavBar

// Custom top bar matching the Figma header exactly:
//   ☰   MET Inspo   🔍
private struct HomeNavBar: View {
    var body: some View {
        HStack {
            // Hamburger / menu icon
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 18, weight: .medium))
            Spacer()
            // App name centered in serif
            Text("MET Inspo")
                .font(.system(size: 17, weight: .semibold, design: .serif))
            Spacer()
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.cream)
    }
}

// MARK: - ArtworkCardView

// One card in the home feed — matches the Figma card layout:
//
//   ┌─────────────────────────────┐
//   │      [Full-width image]     │  height: 260
//   ├─────────────────────────────┤
//   │  EUROPEAN PAINTINGS         │  ← galleryLabelStyle (terracotta, tracked)
//   │  The Harvesters             │  ← galleryDisplay (serif bold)
//   │  Pieter Bruegel, 1565       │  ← subheadline gray
//   └─────────────────────────────┘
//   ─────────────────────────────── ← thin divider
//
private struct ArtworkCardView: View {
    let artwork: ArtObject

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Full-width artwork image.
            AsyncImage(url: URL(string: artwork.primaryImageSmall)) { phase in
                switch phase {
                case .empty:
                    Color.creamDark
                        .overlay(ProgressView())

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .failure:
                    Color.creamDark
                        .overlay(
                            Image(systemName: "photo.slash")
                                .foregroundStyle(.tertiary)
                        )

                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .clipped()

            // Text block below the image
            VStack(alignment: .leading, spacing: 6) {

                // Department label — small caps terracotta
                if !artwork.department.isEmpty {
                    Text(artwork.department)
                        .galleryLabelStyle()
                }

                // Artwork title — large serif bold (~26pt)
                Text(artwork.displayTitle)
                    .font(.galleryDisplay(26))
                    .foregroundStyle(.primary)
                    .lineLimit(3)

                // "Artist Name, Year" — small gray text
                let artistParts = [artwork.displayArtist, artwork.objectDate]
                    .filter { !$0.isEmpty && $0 != "Unknown Artist" }
                if !artistParts.isEmpty {
                    Text(artistParts.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Thin separator between cards
            Divider().opacity(0.35)
        }
        .background(Color.cream)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { HomeView() }
}

