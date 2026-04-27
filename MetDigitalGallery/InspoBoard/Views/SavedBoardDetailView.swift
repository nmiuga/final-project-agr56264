//
//  SavedBoardDetailView.swift
//  MetDigitalGallery — Inspo Board feature
//
//  Read-only moodboard view for a board pulled out of SwiftData. Mirrors
//  the live PaletteBoardView layout but doesn't run extraction or the
//  Foundation Models namer — everything was persisted when the user
//  originally tapped "Save".
//
//  Supports deleting and moving between collections.
//

import SwiftUI
import SwiftData

// MARK: - SavedBoardDetailView

struct SavedBoardDetailView: View {

    @Bindable var board: SavedBoard

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \BoardCollection.createdAt, order: .reverse)
    private var allCollections: [BoardCollection]

    @State private var isMoveSheetPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Hero image — photo or Met artwork.
                heroImage

                VStack(alignment: .leading, spacing: 20) {
                    // Source label (Met artwork or personal photo).
                    Text(sourceLabel)
                        .galleryLabelStyle()

                    // Palette name — same big serif as live board.
                    Text(board.paletteName)
                        .font(.galleryDisplay(32))

                    // Mood pill.
                    Text(board.paletteMood.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(1.5)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.terracotta.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.terracotta)

                    // Swatches (static — no DominantColor objects).
                    StaticSwatchRowView(hexes: board.colorHexes, names: board.colorNames)

                    // One-sentence description.
                    Text(board.paletteDescription)
                        .font(.galleryHeadline(16))
                        .fixedSize(horizontal: false, vertical: true)

                    // Artwork metadata, if present.
                    if board.source == .artwork,
                       let title = board.artworkTitle {
                        Divider().padding(.vertical, 8)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.galleryHeadline(15))
                            if let artist = board.artworkArtist {
                                Text(artist)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Saved date.
                    Text("Saved \(board.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.cream.ignoresSafeArea())
        .navigationTitle(board.paletteName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Move to Collection…", systemImage: "folder") {
                        isMoveSheetPresented = true
                    }
                    Divider()
                    Button("Delete Board", systemImage: "trash", role: .destructive) {
                        modelContext.delete(board)
                        dismiss()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isMoveSheetPresented) {
            MoveCollectionSheet(board: board, collections: allCollections)
        }
    }

    // MARK: - Hero image

    @ViewBuilder
    private var heroImage: some View {
        if let data = board.imageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .background(Color.black)
        } else if let urlString = board.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Rectangle().fill(Color.creamDark).frame(height: 280).overlay(ProgressView())
                case .success(let image):
                    image.resizable().scaledToFit().frame(maxWidth: .infinity).background(Color.black)
                case .failure:
                    Rectangle().fill(Color.creamDark).frame(height: 280)
                        .overlay(Image(systemName: "photo.slash").font(.largeTitle).foregroundStyle(.tertiary))
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Rectangle()
                .fill(Color.creamDark)
                .frame(height: 280)
                .overlay(
                    Image(systemName: "paintpalette")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                )
        }
    }

    // MARK: - Source label

    private var sourceLabel: String {
        switch board.source {
        case .artwork:   return "From Met Collection"
        case .photo:     return "From Your Photos"
        case .combined:  return "Combined VisionBoard"
        }
    }
}

// MARK: - MoveCollectionSheet

/// Small sheet that lets the user re-assign a board to a different
/// collection (or to Ungrouped).
private struct MoveCollectionSheet: View {
    @Bindable var board: SavedBoard
    let collections: [BoardCollection]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    board.collection = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("Ungrouped")
                        Spacer()
                        if board.collection == nil {
                            Image(systemName: "checkmark").foregroundStyle(Color.terracotta)
                        }
                    }
                }
                ForEach(collections) { collection in
                    Button {
                        board.collection = collection
                        dismiss()
                    } label: {
                        HStack {
                            Text(collection.name)
                            Spacer()
                            if board.collection?.id == collection.id {
                                Image(systemName: "checkmark").foregroundStyle(Color.terracotta)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
