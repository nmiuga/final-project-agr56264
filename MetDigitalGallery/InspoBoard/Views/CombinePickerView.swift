//
//  CombinePickerView.swift
//  MetDigitalGallery — VisionBoard feature
//
//  Two-step picker for building a Combined VisionBoard:
//    Step 1 — choose a Met artwork (search + grid)
//    Step 2 — choose a personal photo (PhotosPicker)
//
//  Entry points:
//    • COMBINE tab root → CombinePickerView() (no preselection)
//    • ArtworkDetailView "Combine" button → CombinePickerView(preselectedArtwork:)
//      which skips step 1 entirely and lands on the photo picker.
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - CombinePickerView

struct CombinePickerView: View {

    // If an artwork is pre-selected (coming from ArtworkDetailView), we
    // skip the artwork-selection step and jump straight to photo picking.
    var preselectedArtwork: ArtObject? = nil

    @StateObject private var viewModel = ArtworkViewModel()

    // Step tracking: 1 = pick artwork, 2 = pick photo.
    @State private var step: Int
    @State private var selectedArtwork: ArtObject?

    // Photo picker state.
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedPhoto: UIImage?
    @State private var isNavigatingToBoard = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    init(preselectedArtwork: ArtObject? = nil) {
        self.preselectedArtwork = preselectedArtwork
        // If artwork already chosen, skip straight to step 2.
        _step = State(initialValue: preselectedArtwork != nil ? 2 : 1)
        _selectedArtwork = State(initialValue: preselectedArtwork)
    }

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
            Divider().opacity(0.3)

            if step == 1 {
                artworkPickerStep
            } else {
                photoPickerStep
            }
        }
        .background(Color.cream.ignoresSafeArea())
        .navigationTitle("Combined VisionBoard")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isNavigatingToBoard) {
            if let artwork = selectedArtwork, let photo = selectedPhoto {
                CombinedBoardView(artwork: artwork, photo: photo)
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    selectedPhoto = ui
                    isNavigatingToBoard = true
                }
            }
        }
        .onAppear {
            if viewModel.artworks.isEmpty {
                viewModel.loadArtworks(query: "painting")
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 16) {
            stepPill(number: 1, label: "Artwork", isActive: step == 1, isDone: step > 1)
            Rectangle()
                .fill(Color.terracotta.opacity(0.3))
                .frame(height: 1)
                .frame(maxWidth: 32)
            stepPill(number: 2, label: "Photo", isActive: step == 2, isDone: false)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.cream)
    }

    private func stepPill(number: Int, label: String, isActive: Bool, isDone: Bool) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.terracotta : (isDone ? Color.terracotta.opacity(0.5) : Color.creamDark))
                    .frame(width: 24, height: 24)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isActive ? .white : .secondary)
                }
            }
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(isActive ? Color.terracotta : .secondary)
        }
    }

    // MARK: - Step 1: Artwork Picker

    private var artworkPickerStep: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.terracotta.opacity(0.7))
                TextField("Search the Met collection…", text: $viewModel.searchQuery)
                    .font(.subheadline)
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.loadArtworks(query: viewModel.searchQuery)
                    }
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = "painting"
                        viewModel.loadArtworks(query: "painting")
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.creamDark, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            if viewModel.isLoading {
                Spacer()
                ProgressView("Searching…").scaleEffect(1.2)
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle).foregroundStyle(Color.terracotta)
                    Text(error).font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                    Button("Try Again") { viewModel.loadArtworks(query: viewModel.searchQuery) }
                        .foregroundStyle(Color.terracotta)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(viewModel.artworks) { artwork in
                            ArtworkPickerTile(
                                artwork: artwork,
                                isSelected: selectedArtwork?.objectID == artwork.objectID
                            ) {
                                selectedArtwork = artwork
                                withAnimation(.spring(duration: 0.3)) { step = 2 }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    // MARK: - Step 2: Photo Picker

    private var photoPickerStep: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Selected artwork reminder strip
                if let artwork = selectedArtwork {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: artwork.primaryImageSmall)) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(width: 56, height: 56).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            default:
                                RoundedRectangle(cornerRadius: 8).fill(Color.creamDark)
                                    .frame(width: 56, height: 56)
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Selected Artwork")
                                .galleryLabelStyle()
                            Text(artwork.displayTitle)
                                .font(.galleryHeadline(14))
                                .lineLimit(1)
                            if !artwork.displayArtist.isEmpty {
                                Text(artwork.displayArtist)
                                    .font(.caption).foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        // Allow going back to change artwork
                        Button {
                            withAnimation(.spring(duration: 0.3)) { step = 1 }
                        } label: {
                            Text("Change")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.terracotta)
                        }
                    }
                    .padding(16)
                    .background(Color.creamDark, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                }

                // Instruction
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.terracotta.opacity(0.7))
                    Text("Now pick your photo")
                        .font(.galleryDisplay(22))
                    Text("We'll extract colors from both sources\nand blend them into one VisionBoard.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Photo picker button
                PhotosPicker(
                    selection: $pickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                        Text("Choose from Library")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.terracotta, in: Capsule())
                    .padding(.horizontal, 40)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 60)
        }
    }
}

// MARK: - ArtworkPickerTile

private struct ArtworkPickerTile: View {
    let artwork: ArtObject
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                AsyncImage(url: URL(string: artwork.primaryImageSmall)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .empty:
                        Color.creamDark.overlay(ProgressView())
                    default:
                        Color.creamDark.overlay(
                            Image(systemName: "photo.slash").foregroundStyle(.tertiary)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .clipped()

                // Title overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .overlay(
                    Text(artwork.displayTitle)
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8),
                    alignment: .bottom
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color.terracotta : Color.clear,
                        lineWidth: 3
                    )
            )
            .overlay(
                isSelected ?
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                : nil
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { CombinePickerView() }
        .modelContainer(for: [SavedBoard.self, BoardCollection.self], inMemory: true)
}
