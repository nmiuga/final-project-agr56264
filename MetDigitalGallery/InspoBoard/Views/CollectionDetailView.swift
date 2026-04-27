//
//  CollectionDetailView.swift
//  MetDigitalGallery — Inspo Board feature
//
//  Grid view of every SavedBoard inside a single BoardCollection (or the
//  synthetic "Ungrouped" bucket). Tapping a tile pushes
//  SavedBoardDetailView for the full moodboard.
//
//  Passing collection == nil + a pre-filtered array is how we render the
//  "Ungrouped" pseudo-collection from CollectionListView.
//

import SwiftUI
import SwiftData

// MARK: - CollectionDetailView

struct CollectionDetailView: View {

    /// The collection to display. Nil means we're showing ungrouped boards.
    let collection: BoardCollection?

    /// Pre-resolved list of boards (only used when collection == nil).
    /// For real collections we read from collection.boards directly.
    let ungroupedBoards: [SavedBoard]

    @Environment(\.modelContext) private var modelContext

    init(collection: BoardCollection?, ungroupedBoards: [SavedBoard] = []) {
        self.collection = collection
        self.ungroupedBoards = ungroupedBoards
    }

    // MARK: - Derived

    private var title: String {
        collection?.name ?? "Ungrouped"
    }

    private var boards: [SavedBoard] {
        let all = collection?.boards ?? ungroupedBoards
        return all.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12),
                          GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(boards) { board in
                    NavigationLink(value: board) {
                        SavedBoardThumb(board: board)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(board)
                        } label: {
                            Label("Delete Board", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.cream.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: SavedBoard.self) { board in
            SavedBoardDetailView(board: board)
        }
    }
}

// MARK: - SavedBoardThumb

/// Small card shown in the collection grid. Image on top, poetic name
/// + mood pill below. Falls back to color swatches if the image can't
/// be rendered (e.g., Met URL is down and we have no cached Data).
private struct SavedBoardThumb: View {
    let board: SavedBoard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            boardImage
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(board.paletteName)
                    .font(.galleryHeadline(14))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(board.paletteMood.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(Color.terracotta)
            }
        }
    }

    // MARK: - Image

    @ViewBuilder
    private var boardImage: some View {
        if let data = board.imageData, let ui = UIImage(data: data) {
            // Personal photo — display stored bytes.
            Image(uiImage: ui).resizable().scaledToFill()
        } else if let urlString = board.imageURL, let url = URL(string: urlString) {
            // Met artwork — re-fetch via AsyncImage.
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    swatchFallback
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    swatchFallback
                @unknown default:
                    swatchFallback
                }
            }
        } else {
            swatchFallback
        }
    }

    /// Thin vertical bars in the board's own colors. Used when no image
    /// is available — keeps the card from looking broken.
    private var swatchFallback: some View {
        HStack(spacing: 0) {
            ForEach(board.colorHexes, id: \.self) { hex in
                Rectangle().fill(Color(hex: hex))
            }
        }
    }
}
