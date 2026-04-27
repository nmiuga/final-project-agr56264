//
//  ProfileView.swift
//  MetDigitalGallery
//
//  Created by Allison Ramirez on 4/1/26.
//
//  PROFILE tab — rewritten for the inspo-board feature (Apr 2026).
//  Shows:
//    • The user's avatar + name header
//    • A quick stat row (collections, boards)
//    • An entry point to create a new board from a personal photo
//    • The full CollectionListView (grid of user's collections)
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

// MARK: - ProfileView

struct ProfileView: View {

    // SwiftData counts for the stat row. We don't render these lists here;
    // CollectionListView handles rendering.
    @Query private var collections: [BoardCollection]
    @Query private var boards: [SavedBoard]

    // Photo picker state for "New Board from Photo".
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var isPresentingPhotoBoard = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // ── Header ────────────────────────────────────────────
                header

                // ── Stats ─────────────────────────────────────────────
                statsRow

                Divider().padding(.horizontal, 40)

                // ── Photo picker entry ────────────────────────────────
                photoBoardButton

                // ── Collections library ───────────────────────────────
                CollectionListView()
            }
            .padding(.bottom, 40)
        }
        .background(Color.cream.ignoresSafeArea())
        .navigationBarHidden(true)
        .onChange(of: pickerItem) { _, newItem in
            // When the user picks a photo from their library, load it
            // into a UIImage then trigger the navigation sheet.
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    pickedImage = ui
                    isPresentingPhotoBoard = true
                }
            }
        }
        .navigationDestination(isPresented: $isPresentingPhotoBoard) {
            if let pickedImage {
                PaletteBoardView(image: pickedImage)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Text("MET Inspo")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Circle()
                .fill(Color.creamDark)
                .frame(width: 90, height: 90)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.terracotta.opacity(0.6))
                )

            VStack(spacing: 4) {
                Text("Art Enthusiast")
                    .font(.galleryDisplay(22))
                Text("Metropolitan Museum Member")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Stats

    /// Two-count summary: collections + boards. Updates live via @Query.
    private var statsRow: some View {
        HStack(spacing: 32) {
            StatItem(value: collections.count, label: "Collections")
            StatItem(value: boards.count, label: "Boards")
        }
    }

    // MARK: - Photo board button

    /// Two creation entry points: single-photo board + combined VisionBoard.
    private var photoBoardButton: some View {
        VStack(spacing: 10) {
            PhotosPicker(
                selection: $pickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("New Board from Photo")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.terracotta, in: Capsule())
                .padding(.horizontal, 20)
            }

            NavigationLink {
                CombinePickerView()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "circle.grid.2x2")
                    Text("New Combined VisionBoard")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.terracotta)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.creamDark, in: Capsule())
                .overlay(Capsule().stroke(Color.terracotta.opacity(0.3), lineWidth: 1))
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - StatItem

private struct StatItem: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.galleryDisplay(26))
                .foregroundStyle(Color.terracotta)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.5)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { ProfileView() }
        .modelContainer(for: [SavedBoard.self, BoardCollection.self], inMemory: true)
}
