//
//  ExploreView.swift
//  MetDigitalGallery
//
//  Created by Allison Ramirez on 4/1/26.
//
//  EXPLORE tab — 2-column image grid of artworks.
//  Fetches its own set of artworks (default query: "painting").
//

import SwiftUI

struct ExploreView: View {

    @StateObject private var viewModel = ArtworkViewModel()
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

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
                VStack(alignment: .leading, spacing: 0) {
                    Text("Explore the Collection")
                        .font(.galleryDisplay(32))
                        .foregroundStyle(Color.terracotta)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    // ── Search Bar ────────────────────────────────────
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.terracotta.opacity(0.7))
                        TextField("Search paintings, sculptures…", text: $searchText)
                            .font(.subheadline)
                            .submitLabel(.search)
                            .onSubmit {
                                let query = searchText.trimmingCharacters(in: .whitespaces)
                                viewModel.loadArtworks(query: query.isEmpty ? "painting" : query)
                            }
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                viewModel.loadArtworks(query: "painting")
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.creamDark, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView().scaleEffect(1.3)
                            Text("Loading collection…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(Color.terracotta)
                            Text(error)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 40)
                            Button("Try Again") { viewModel.loadArtworks(query: "painting") }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.terracotta)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                    } else {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(viewModel.artworks) { artwork in
                                NavigationLink(destination: ArtworkDetailView(artwork: artwork)) {
                                    AsyncImage(url: URL(string: artwork.primaryImageSmall)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().scaledToFill()
                                        case .empty:
                                            Color.creamDark.overlay(ProgressView())
                                        case .failure:
                                            Color.creamDark.overlay(
                                                Image(systemName: "photo.slash").foregroundStyle(.tertiary)
                                            )
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .clipped()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.cream)
        .navigationBarHidden(true)
        .onAppear {
            if viewModel.artworks.isEmpty {
                viewModel.loadArtworks(query: "painting")
            }
        }
    }
}

#Preview {
    NavigationStack { ExploreView() }
}
