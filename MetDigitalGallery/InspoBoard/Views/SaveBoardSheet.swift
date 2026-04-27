//
//  SaveBoardSheet.swift
//  MetDigitalGallery — Inspo Board feature
//
//  Modal sheet presented when the user taps "Save" on PaletteBoardView.
//  Lets them either:
//    - pick an existing BoardCollection to add this board to, or
//    - create a brand-new collection on the fly
//
//  Writes a SavedBoard into SwiftData and dismisses.
//

import SwiftUI
import SwiftData

// MARK: - SaveBoardSheet

struct SaveBoardSheet: View {

    // ── Inputs passed from PaletteBoardView / CombinedBoardView ──────
    let source: BoardSourceType
    let metArtworkID: Int?
    let imageURL: String?
    let imageData: Data?
    // Combined-board extras (nil for single-source boards)
    let photoImageData: Data?
    let artworkColorCount: Int?
    let photoColorCount: Int?
    let artworkTitle: String?
    let artworkArtist: String?
    let palette: PaletteBoard
    let colorHexes: [String]

    /// Called after a successful save so the parent can update UI.
    var onSaved: () -> Void

    // ── Environment ───────────────────────────────────────────────────
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Existing collections, newest first — powers the picker.
    @Query(sort: \BoardCollection.createdAt, order: .reverse)
    private var collections: [BoardCollection]

    // ── State ─────────────────────────────────────────────────────────
    @State private var selectedCollectionID: UUID?
    @State private var isCreatingNewCollection = false
    @State private var newCollectionName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // ── Board preview summary ─────────────────────────────
                Section("Board") {
                    LabeledRow(label: "Name", value: palette.name)
                    LabeledRow(label: "Mood", value: palette.mood)
                    LabeledRow(label: "Colors", value: "\(colorHexes.count) swatches")
                }

                // ── Destination collection ────────────────────────────
                Section("Add to a collection") {
                    if !collections.isEmpty {
                        Picker("Collection", selection: $selectedCollectionID) {
                            Text("Ungrouped").tag(UUID?.none)
                            ForEach(collections) { collection in
                                Text(collection.name).tag(Optional(collection.id))
                            }
                        }
                    } else {
                        Text("No collections yet — create one below.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Create a new collection", isOn: $isCreatingNewCollection.animation())

                    if isCreatingNewCollection {
                        TextField("Collection name (e.g., Autumn Palettes)",
                                  text: $newCollectionName)
                    }
                }
            }
            .navigationTitle("Save Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: performSave)
                        .disabled(isCreatingNewCollection && newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Save

    private func performSave() {
        // Resolve destination collection.
        var destination: BoardCollection?
        if isCreatingNewCollection {
            let name = newCollectionName.trimmingCharacters(in: .whitespaces)
            let newCollection = BoardCollection(name: name)
            modelContext.insert(newCollection)
            destination = newCollection
        } else if let id = selectedCollectionID {
            destination = collections.first(where: { $0.id == id })
        }

        // Build and insert the SavedBoard.
        let saved = SavedBoard(
            source: source,
            metArtworkID: metArtworkID,
            imageURL: imageURL,
            artworkTitle: artworkTitle,
            artworkArtist: artworkArtist,
            imageData: imageData,
            photoImageData: photoImageData,
            artworkColorCount: artworkColorCount,
            photoColorCount: photoColorCount,
            palette: palette,
            colorHexes: colorHexes,
            collection: destination
        )
        modelContext.insert(saved)

        // SwiftData auto-saves on context change, but we explicitly try
        // to save so errors surface immediately.
        do {
            try modelContext.save()
            onSaved()
            dismiss()
        } catch {
            // TODO: surface this to the user with a toast/alert.
            print("SaveBoardSheet: failed to save — \(error.localizedDescription)")
        }
    }
}

// MARK: - LabeledRow

private struct LabeledRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).lineLimit(2).multilineTextAlignment(.trailing)
        }
    }
}
