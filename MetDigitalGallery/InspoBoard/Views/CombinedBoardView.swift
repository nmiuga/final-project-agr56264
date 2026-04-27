//
//  CombinedBoardView.swift
//  MetDigitalGallery — VisionBoard feature
//
//  The dual-source moodboard. Accepts one Met artwork and one personal
//  photo, extracts colors concurrently from both, then asks the LLM to
//  name the blended palette as if it were a UX design direction.
//
//  UI signature: a side-by-side hero strip (artwork 60% / photo 40%)
//  above a split swatch row with a thin terracotta separator between the
//  two source groups.
//

import SwiftUI
import SwiftData

// MARK: - CombinedBoardView

struct CombinedBoardView: View {

    // ── Inputs ─────────────────────────────────────────────────────────────
    let artwork: ArtObject
    let photo: UIImage

    // ── State ──────────────────────────────────────────────────────────────
    @State private var artworkImage: UIImage?
    @State private var artworkColors: [DominantColor] = []
    @State private var photoColors:   [DominantColor] = []
    @State private var board: PaletteBoard?
    @State private var isLoading = true
    @State private var isSaveSheetPresented = false
    @State private var didSave = false
    @State private var unavailableReason: String?
    @State private var errorMessage: String?

    // Configurable split (artwork + photo must total 5).
    @State private var artworkColorCount = 3
    @State private var photoColorCount   = 2

    @Environment(\.modelContext) private var modelContext

    var allColors: [DominantColor] { artworkColors + photoColors }

    var body: some View {
        Group {
            if let reason = unavailableReason {
                AvailabilityGateView(reason: reason)
            } else {
                content
            }
        }
        .background(Color.cream.ignoresSafeArea())
        .navigationTitle("Combined VisionBoard")
        .navigationBarTitleDisplayMode(.inline)
        .task { await bootstrap() }
        .sheet(isPresented: $isSaveSheetPresented) { saveSheet }
        .toolbar {
            if didSave {
                ToolbarItem(placement: .topBarTrailing) {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Color.terracotta)
                }
            }
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Artwork image (full-width) ─────────────────────────────
                Group {
                    if let artworkImage {
                        Image(uiImage: artworkImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.creamDark.overlay(ProgressView())
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()

                // Source label between images
                HStack {
                    Text("Your Photo")
                        .galleryLabelStyle()
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 10)

                // ── Personal photo (full-width) ────────────────────────────
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipped()

                // ── Board content ─────────────────────────────────────────
                VStack(alignment: .leading, spacing: 20) {

                    // Section label
                    Text("Combined VisionBoard")
                        .galleryLabelStyle()
                        .padding(.top, 24)

                    // Board name
                    if let name = board?.name {
                        Text(name)
                            .font(.galleryDisplay(30))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        placeholderRect(height: 32, width: 200)
                    }

                    // Mood pill
                    if let mood = board?.mood {
                        Text(mood.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(1.5)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.terracotta, in: Capsule())
                    } else if isLoading {
                        placeholderRect(height: 22, width: 80)
                    }

                    // Combined swatch row (split by source)
                    if !allColors.isEmpty {
                        CombinedSwatchRow(
                            artworkColors: artworkColors,
                            photoColors: photoColors,
                            names: board?.colorNames
                        )
                    } else {
                        placeholderRect(height: 100, width: .infinity)
                    }

                    // Description
                    if let description = board?.description {
                        Text(description)
                            .font(.system(size: 15, weight: .regular, design: .serif))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if isLoading {
                        placeholderRect(height: 18, width: .infinity)
                    }

                    // Error surface
                    if let error = errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }

                    // ── Color split adjuster ───────────────────────────────
                    splitAdjuster

                    // ── Action buttons ─────────────────────────────────────
                    HStack(spacing: 12) {
                        Button {
                            Task { await runNamer() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Regenerate")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(Color.terracotta)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.creamDark, in: Capsule())
                            .overlay(Capsule().stroke(Color.terracotta.opacity(0.3), lineWidth: 1))
                        }
                        .disabled(isLoading || allColors.isEmpty)

                        Button {
                            isSaveSheetPresented = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bookmark")
                                Text("Save Board")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                board != nil ? Color.terracotta : Color.terracotta.opacity(0.4),
                                in: Capsule()
                            )
                        }
                        .disabled(board == nil || isLoading)
                    }

                    // ── Source attribution ─────────────────────────────────
                    sourceAttribution

                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Split Adjuster

    private var splitAdjuster: some View {
        DisclosureGroup {
            VStack(spacing: 12) {
                HStack {
                    Label("Artwork swatches: \(artworkColorCount)", systemImage: "building.columns")
                        .font(.subheadline)
                    Spacer()
                    Stepper("", value: $artworkColorCount, in: 1...4)
                        .labelsHidden()
                        .onChange(of: artworkColorCount) { _, new in
                            photoColorCount = 5 - new
                        }
                }
                HStack {
                    Label("Photo swatches: \(photoColorCount)", systemImage: "photo")
                        .font(.subheadline)
                    Spacer()
                }
                .foregroundStyle(.secondary)

                Button {
                    Task { await reextract() }
                } label: {
                    Text("Re-extract with this split")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.terracotta)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.creamDark, in: RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isLoading)
            }
            .padding(.top, 8)
        } label: {
            Label("Adjust color split", systemImage: "slider.horizontal.3")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .tint(Color.terracotta)
    }

    // MARK: - Source Attribution

    private var sourceAttribution: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            Text("Sources")
                .galleryLabelStyle()
                .padding(.top, 4)

            HStack(spacing: 10) {
                Image(systemName: "building.columns")
                    .foregroundStyle(Color.terracotta)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(artwork.displayTitle)
                        .font(.galleryHeadline(13))
                        .lineLimit(1)
                    if !artwork.displayArtist.isEmpty {
                        Text(artwork.displayArtist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "photo")
                    .foregroundStyle(Color.terracotta)
                    .frame(width: 20)
                Text("Your photo")
                    .font(.galleryHeadline(13))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Save Sheet

    private var saveSheet: some View {
        SaveBoardSheet(
            source: .combined,
            metArtworkID: artwork.objectID,
            imageURL: artwork.primaryImageSmall.isEmpty ? nil : artwork.primaryImageSmall,
            imageData: nil,
            photoImageData: photo.jpegData(compressionQuality: 0.85),
            artworkColorCount: artworkColorCount,
            photoColorCount: photoColorCount,
            artworkTitle: artwork.displayTitle,
            artworkArtist: artwork.displayArtist.isEmpty ? nil : artwork.displayArtist,
            palette: board!,
            colorHexes: allColors.map(\.hex)
        ) {
            didSave = true
            isSaveSheetPresented = false
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    // MARK: - Placeholder

    private func placeholderRect(height: CGFloat, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.creamDark)
            .frame(maxWidth: width == .infinity ? .infinity : width)
            .frame(height: height)
            .shimmering()
    }

    // MARK: - Generation Flow

    private func bootstrap() async {
        // Load the Met artwork image from its URL.
        let imageURLString = artwork.primaryImage.isEmpty
            ? artwork.primaryImageSmall
            : artwork.primaryImage
        artworkImage = await ImageLoader.shared.load(from: imageURLString)

        guard let artworkImage else {
            errorMessage = "Couldn't load the artwork image. Check your connection."
            isLoading = false
            return
        }

        // Extract colors from both images concurrently.
        let combined = await PaletteExtractor.shared.extractCombined(
            artworkImage: artworkImage,
            photoImage: photo,
            artworkCount: artworkColorCount,
            photoCount: photoColorCount
        )
        artworkColors = Array(combined.prefix(artworkColorCount))
        photoColors   = Array(combined.suffix(photoColorCount))

        await runNamer()
    }

    private func runNamer() async {
        guard !artworkColors.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            board = try await PaletteNamer.shared.generateCombined(
                artworkHexes: artworkColors.map(\.hex),
                photoHexes:   photoColors.map(\.hex),
                artworkTitle: artwork.displayTitle.isEmpty ? nil : artwork.displayTitle,
                artist:       artwork.displayArtist.isEmpty ? nil : artwork.displayArtist
            )
        } catch PaletteNamerError.modelUnavailable(let reason) {
            unavailableReason = reason
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reextract() async {
        guard let artworkImage else { return }
        isLoading = true
        let combined = await PaletteExtractor.shared.extractCombined(
            artworkImage: artworkImage,
            photoImage: photo,
            artworkCount: artworkColorCount,
            photoCount: photoColorCount
        )
        artworkColors = Array(combined.prefix(artworkColorCount))
        photoColors   = Array(combined.suffix(photoColorCount))
        await runNamer()
    }
}

// MARK: - CombinedSwatchRow

/// Two groups of swatches separated by a thin terracotta divider line.
/// Labels above each group identify its source.
private struct CombinedSwatchRow: View {
    let artworkColors: [DominantColor]
    let photoColors:   [DominantColor]
    let names: [String]?

    @State private var copiedIndex: Int? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 8) {

            // Artwork group
            VStack(alignment: .leading, spacing: 6) {
                Text("Artwork")
                    .font(.system(size: 8, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(Color.terracotta.opacity(0.8))

                HStack(spacing: 4) {
                    ForEach(Array(artworkColors.enumerated()), id: \.1.id) { (i, color) in
                        swatchTile(color: color, name: names?[safe: i], globalIndex: i)
                    }
                }
            }

            // Separator
            VStack {
                Spacer().frame(height: 14) // align with swatches
                Rectangle()
                    .fill(Color.terracotta.opacity(0.35))
                    .frame(width: 1, height: 88)
            }

            // Photo group
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Photo")
                    .font(.system(size: 8, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(Color.terracotta.opacity(0.8))

                HStack(spacing: 4) {
                    ForEach(Array(photoColors.enumerated()), id: \.1.id) { (i, color) in
                        let globalIndex = artworkColors.count + i
                        swatchTile(color: color, name: names?[safe: globalIndex], globalIndex: globalIndex)
                    }
                }
            }

            Spacer()
        }
    }

    private func swatchTile(color: DominantColor, name: String?, globalIndex: Int) -> some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color.color)
                    .frame(width: 50, height: 66)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                    )

                if copiedIndex == globalIndex {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 50, height: 66)
                        .overlay(
                            Text("Copied!")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                }
            }
            .onTapGesture {
                UIPasteboard.general.string = color.hex
                withAnimation(.easeIn(duration: 0.1)) { copiedIndex = globalIndex }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { copiedIndex = nil }
                }
            }

            Text(name ?? color.hex)
                .font(.system(size: 9, weight: .medium, design: .serif))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 50)
        }
    }
}

// MARK: - Shimmering modifier (simple loading animation)

private extension View {
    func shimmering() -> some View {
        self.opacity(0.6)
    }
}

// MARK: - Safe subscript

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CombinedBoardView(
            artwork: ArtObject(
                objectID: 436535,
                title: "Wheat Field with Cypresses",
                artistDisplayName: "Vincent van Gogh",
                artistDisplayBio: "Dutch, 1853–1890",
                artistNationality: "Dutch",
                objectDate: "1889",
                objectBeginDate: 1889,
                culture: "French",
                period: "",
                dynasty: "",
                medium: "Oil on canvas",
                dimensions: "73 × 93.4 cm",
                department: "European Paintings",
                classification: "Paintings",
                primaryImage: "",
                primaryImageSmall: "",
                objectURL: "",
                isHighlight: true,
                isPublicDomain: true
            ),
            photo: UIImage(systemName: "photo")!
        )
    }
    .modelContainer(for: [SavedBoard.self, BoardCollection.self], inMemory: true)
}

