[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/pIINm7ks)

---

# VisionBoard for Color

A native iOS app for UX designers to pull color inspiration from Met Museum artworks and personal photos — and blend them into one moodboard.

![Home screen](assets/screenshot-home.png)
![Detail screen](assets/screenshot-detail.png)

---

## What It Does

VisionBoard for Color connects to the Metropolitan Museum of Art's public API to pull in real artwork from the collection. From there, you can extract the dominant color palette from any painting, combine it with colors from your own photos, and save the results as a styled moodboard. The app is designed for UX designers who want a fast, visual way to build color direction from real-world inspiration.

---

## Screenshots

| Home — Scrapbook Collage | Detail — Combined VisionBoard |
|--------------------------|-------------------------------|
| ![Home](assets/screenshot-home.png) | ![Detail](assets/screenshot-detail.png) |

---

## Features

**Home — Scrapbook Collage**
The home screen shows Met artworks as polaroid-style cards arranged in a staggered two-column layout. Each card is slightly rotated and shows the full artwork image with five extracted color dots below it — like a physical moodboard pinned to a wall. Tapping any card opens the artwork detail.

**Explore — Search the Met Collection**
A two-column image grid connected to the Met Museum API. Type any search term (impressionism, sculpture, landscape) and the grid updates live with real results.

**Combine — Dual-Source VisionBoard**
The signature feature. A two-step picker lets you choose a Met artwork and then a photo from your camera roll. The app extracts the dominant colors from both images at the same time, merges them into one five-color palette, and uses Apple's on-device AI to name and describe the result. The board stacks both images full-width with a split swatch row showing which colors came from which source. Tap any swatch to copy its hex code directly to your clipboard.

**Profile — Saved Boards & Collections**
All your saved boards live here, organized into collections you create. You can move boards between collections, view saved combined boards, or start a new one directly from this tab.

---

## The Concept

Most color tools either give you abstract palettes or require you to already know what you're looking for. This app starts from art — centuries of considered color work — and pairs it with the colors already in your life through your photos. The result is a palette that feels both elevated and personal, which is exactly the kind of color direction that works in UX design.

The terracotta and cream visual design is intentional. The app uses the same color sensibility it's teaching — warm, earthy, and considered rather than bright or clinical.

---

## Technical Concepts Used

- **Met Museum Public API** — no key required; fetches artwork search results and full object metadata via two chained URLSession calls
- **Core Image pixel extraction** — images are downsampled to 64×64 and color-bucketed to find the 5 most dominant colors without any machine learning
- **Apple Foundation Models (`@Generable`)** — Apple's on-device LLM names each palette; the `@Generable` macro returns a typed Swift struct instead of raw text so no JSON parsing is needed
- **`async let` concurrency** — color extraction runs on both images simultaneously rather than one after the other
- **SwiftData (`@Model`, `@Query`)** — boards and collections are saved to the device's local database automatically; `@Query` keeps the UI in sync with the data at all times
- **`PhotosPicker`** — native Apple photo library access with no manual permissions code
- **`NavigationStack` + `.task`** — screens push onto a navigation stack and async work is tied to view lifecycle so it cancels automatically when you navigate away

---

## Requirements

- iOS 26 or later
- Xcode 26 or later
- **Apple Intelligence-eligible device** required for AI palette naming (iPhone 15 Pro, iPhone 16, iPhone 17, or M-series iPad). Color extraction works on all devices — only the naming step requires Apple Intelligence.

---

## Setup

1. Clone this repo
2. Open `MetDigitalGallery.xcodeproj` in Xcode
3. Select your target device or simulator (iPhone 17 Pro recommended)
4. Press **⌘R** to build and run
5. No API keys or configuration needed — the Met API is public

---

## Project Structure

```
MetDigitalGallery/
├── ArtworkListView.swift          ← Home scrapbook collage
├── ArtworkDetailView.swift        ← Artwork detail + board entry points
├── ExploreView.swift              ← Searchable Met collection grid
├── ProfileView.swift              ← Saved boards + collections
├── ContentView.swift              ← 4-tab navigation
├── GalleryTheme.swift             ← Design system (terracotta, cream, fonts)
└── InspoBoard/
    ├── Models/                    ← SavedBoard, PaletteBoard, DominantColor
    ├── Services/                  ← PaletteExtractor, PaletteNamer, ImageLoader
    └── Views/                     ← PaletteBoardView, CombinedBoardView,
                                       CombinePickerView, CollectionListView…
```

---

*Built for iOS App Development — Spring 2026*
