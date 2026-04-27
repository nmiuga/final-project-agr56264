//
//  CollectionListView.swift
//  MetDigitalGallery — Inspo Board feature
//
//  The user's library of inspo-board collections. Used as a section in
//  the rewritten ProfileView. Each card shows the collection name, the
//  board count, and a 4-color preview strip pulled from its latest board.
//
//  Users can:
//    • Tap a collection → push CollectionDetailView (grid of its boards)
//    • Create a new empty collection via toolbar "+"
//    • Swipe-to-delete a collection (boards survive as ungrouped)
//

import SwiftUI
import SwiftData

// MARK: - CollectionListView

struct CollectionListView: View {

    @Query(sort: \BoardCollection.createdAt, order: .reverse)
    private var collections: [BoardCollection]

    // Ungrouped boards — boards with no collection assigned.
    @Query(
        filter: #Predicate<SavedBoard> { $0.collection == nil },
        sort: \SavedBoard.createdAt,
        order: .reverse
    )
    private var ungroupedBoards: [SavedBoard]

    @Environment(\.modelContext) private var modelContext

    @State private var isCreatingCollection = false
    @State private var newCollectionName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header row with + button.
                HStack {
                    Text("Your Collections")
                        .font(.galleryHeadline(20))
                    Spacer()
                    Button {
                        isCreatingCollection = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.terracotta)
                    }
                }
                .padding(.horizontal, 20)

                // Empty state.
                if collections.isEmpty && ungroupedBoards.isEmpty {
                    EmptyLibraryView()
                } else {
                    // Collection cards.
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12),
                                  GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(collections) { collection in
                            NavigationLink(value: collection) {
                                CollectionCard(collection: collection)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(collection)
                                } label: {
                                    Label("Delete Collection", systemImage: "trash")
                                }
                            }
                        }

                        // "Ungrouped" pseudo-card if any boards exist outside a collection.
                        if !ungroupedBoards.isEmpty {
                            NavigationLink(value: UngroupedSentinel.shared) {
                                UngroupedCard(count: ungroupedBoards.count,
                                              previewHexes: Array(ungroupedBoards.first?.colorHexes.prefix(4) ?? []))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color.cream)
        .navigationDestination(for: BoardCollection.self) { collection in
            CollectionDetailView(collection: collection)
        }
        .navigationDestination(for: UngroupedSentinel.self) { _ in
            CollectionDetailView(collection: nil, ungroupedBoards: ungroupedBoards)
        }
        .alert("New Collection", isPresented: $isCreatingCollection) {
            TextField("Name (e.g., Autumn Palettes)", text: $newCollectionName)
            Button("Create") {
                let name = newCollectionName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                let collection = BoardCollection(name: name)
                modelContext.insert(collection)
                newCollectionName = ""
            }
            Button("Cancel", role: .cancel) {
                newCollectionName = ""
            }
        }
    }
}

// MARK: - CollectionCard

private struct CollectionCard: View {
    let collection: BoardCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 4-tile preview strip. Even spacing, regardless of how many
            // hexes are available — empty slots are cream-dark.
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(fillColor(for: i))
                        .frame(height: 72)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(collection.name)
                    .font(.galleryHeadline(14))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(collection.boardCount == 1 ? "1 board" : "\(collection.boardCount) boards")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func fillColor(for index: Int) -> Color {
        let hexes = collection.previewHexes
        guard index < hexes.count else { return Color.creamDark }
        return Color(hex: hexes[index])
    }
}

// MARK: - UngroupedCard

private struct UngroupedCard: View {
    let count: Int
    let previewHexes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(i < previewHexes.count ? Color(hex: previewHexes[i]) : Color.creamDark)
                        .frame(height: 72)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Ungrouped")
                    .font(.galleryHeadline(14))
                    .foregroundStyle(.primary)
                Text(count == 1 ? "1 board" : "\(count) boards")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Empty state

private struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "paintpalette")
                .font(.system(size: 40))
                .foregroundStyle(Color.terracotta.opacity(0.6))
            Text("No boards yet")
                .font(.galleryHeadline(16))
            Text("Pick an artwork or a photo and tap \"Save\" on its inspo board to start building your library.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - UngroupedSentinel

/// Hashable sentinel so navigationDestination can disambiguate "the
/// ungrouped folder" from real BoardCollection rows.
struct UngroupedSentinel: Hashable {
    static let shared = UngroupedSentinel()
    private init() {}
}
