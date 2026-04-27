//
//  ArtworkListView.swift — contains HomeView
//  MetDigitalGallery
//
//  HOME tab — Scrapbook / Digital Camera Collage
//  Polaroid-style cards, slightly rotated, staggered 2-column layout.
//  Each card shows the artwork photo + extracted color dots beneath it.
//

import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    @StateObject private var viewModel = ArtworkViewModel()

    // Two independently-offset columns for a staggered collage feel
    private var leftArtworks:  [ArtObject] { stride(from: 0, to: viewModel.artworks.count, by: 2).map { viewModel.artworks[$0] } }
    private var rightArtworks: [ArtObject] { stride(from: 1, to: viewModel.artworks.count, by: 2).map { viewModel.artworks[$0] } }

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Color.terracotta.opacity(0.1)).frame(height: 0.5)

            if viewModel.isLoading {
                Spacer()
                VStack(spacing: 10) {
                    ProgressView().scaleEffect(1.2)
                    Text("Developing…")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    HStack(alignment: .top, spacing: 12) {
                        // Left column — offset slightly down for stagger
                        VStack(spacing: 16) {
                            ForEach(leftArtworks)  { art in PolaroidCard(artwork: art) }
                        }
                        .padding(.top, 28)

                        // Right column — starts higher
                        VStack(spacing: 16) {
                            ForEach(rightArtworks) { art in PolaroidCard(artwork: art) }
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color.cream)
        .navigationBarHidden(true)
        .onAppear {
            if viewModel.artworks.isEmpty { viewModel.loadArtworks() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 1) {
                Text("VisionBoard")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                Text("color inspiration")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.terracotta.opacity(0.7))
            }
            Spacer()
            // Film counter — digital camera aesthetic
            Text("⬤ REC")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.terracotta)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.terracotta.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.cream)
    }
}

// MARK: - PolaroidCard

private struct PolaroidCard: View {

    let artwork: ArtObject
    @State private var colors: [DominantColor] = []

    // Deterministic tilt seeded from objectID — never re-randomizes
    private var tilt: Double {
        let seed = artwork.objectID % 9
        return Double(seed - 4) * 0.6   // range: -2.4° to +2.4°
    }

    var body: some View {
        NavigationLink(destination: ArtworkDetailView(artwork: artwork)) {
            cardBody
        }
        .buttonStyle(.plain)
        .rotationEffect(.degrees(tilt))
        .task { await extractColors() }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Photo area ─────────────────────────────────────────────
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: artwork.primaryImageSmall)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                    case .empty:
                        Color.creamDark.overlay(
                            Image(systemName: "camera")
                                .font(.system(size: 20))
                                .foregroundStyle(.tertiary)
                        )
                    default:
                        Color.creamDark
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.04))

                // Date stamp — digital camera watermark feel
                if !artwork.objectDate.isEmpty {
                    Text(artwork.objectDate)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.35))
                        .padding(6)
                }
            }

            // ── White polaroid bottom ──────────────────────────────────
            VStack(alignment: .leading, spacing: 8) {

                // Color dot strip
                HStack(spacing: 5) {
                    if colors.isEmpty {
                        ForEach(0..<5, id: \.self) { _ in
                            Circle().fill(Color.creamDark).frame(width: 14, height: 14)
                        }
                    } else {
                        ForEach(colors) { c in
                            Circle()
                                .fill(c.color)
                                .frame(width: 14, height: 14)
                                .shadow(color: c.color.opacity(0.4), radius: 2)
                        }
                    }
                    Spacer()
                }

                // Title — small, handwritten feel
                Text(artwork.displayTitle)
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .foregroundStyle(.primary.opacity(0.75))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !artwork.displayArtist.isEmpty {
                    Text(artwork.displayArtist)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(Color.white)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .shadow(color: .black.opacity(0.13), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
    }

    private func extractColors() async {
        guard colors.isEmpty else { return }
        guard let img = await ImageLoader.shared.load(from: artwork.primaryImageSmall) else { return }
        colors = await PaletteExtractor.shared.extract(from: img, count: 5)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { HomeView() }
}
