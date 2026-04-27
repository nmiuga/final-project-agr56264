# MetDigitalGallery — Edits Log

## Code Cleanup & Error Fixes

### Problem
The project accumulated duplicate and conflicting Swift files during development, causing the following compile errors:
- Multiple `@main` entry points
- Redeclaration of `SearchResponse`, `ArtworkViewModel`, `ArtworkDetailView`, `ExploreView`, `ProfileView`, `ArtworkCard`, `Color.init(hex:)`, and `RoundedCorner`
- Two incompatible model types (`Artwork` vs `ArtObject`) both feeding into the same `ArtworkViewModel` class name

---

### Files Deleted

| File | Reason |
|---|---|
| `METInspoApp.swift` | Duplicate `@main` entry point — `MetDigitalGalleryApp.swift` is the correct one |
| `ArtworkModel.swift` | Old `Artwork` struct replaced by the richer `ArtObject` in `ArtObject.swift` |
| `ArtworkViewModel 2.swift` | Duplicate `ArtworkViewModel` using the old `Artwork` model |
| `ArtworkDetailView 2.swift` | Duplicate detail view using the old `Artwork` model |
| `ExploreView 2.swift` | Duplicate explore view using the old `Artwork` model |
| `ProfileView 2.swift` | Stub placeholder — superseded by the full `ProfileView.swift` |
| `ArtworkCard.swift` | Used old `Artwork` model; home feed card is handled by `ArtworkCardView` inside `ArtworkListView.swift` |
| `RoundedCorner.swift` | Only used by deleted files |
| `Color+Hex.swift` | Only used by deleted files; colors are now handled via `GalleryTheme.swift` tokens |

---

### Files Rewritten

**`ContentView.swift`**
- Removed all inline type and view definitions (these were duplicating `ArtObject`, `ArtworkViewModel`, `ArtworkCard`, `ArtworkDetailView`, `ExploreView`, `ProfileView`, `Color.init(hex:)`, and `RoundedCorner`)
- Kept only its real responsibility: the `AppTab` enum and the 3-tab navigation shell (`ContentView`, `CustomTabBar`, `TabBarItem`)
- Updated tab bar colors to use `Color.terracotta` and `Color.cream` from `GalleryTheme.swift` instead of raw hex strings

---

### Final File Structure

```
MetDigitalGallery/
  MetDigitalGalleryApp.swift   ← @main entry point
  ContentView.swift            ← tab navigation shell (HOME / EXPLORE / PROFILE)
  ArtObject.swift              ← model: SearchResponse + ArtObject (Met API)
  ArtworkViewModel.swift       ← ViewModel: fetches artwork from Met API
  ArtworkListView.swift        ← HOME tab (HomeView + ArtworkCardView)
  ArtworkDetailView.swift      ← detail screen pushed from Home and Explore
  ExploreView.swift            ← EXPLORE tab (2-column image grid)
  ProfileView.swift            ← PROFILE tab
  GalleryTheme.swift           ← design tokens: colors, fonts, view modifier
  Assets.xcassets              ← app icon, accent color
```

---

---

# VisionBoard for Color — New Feature Additions

## Overview

Building on top of the Project 2 codebase, I added a **Combined VisionBoard** feature that merges color palettes extracted from a Met Museum artwork *and* a personal photo into one unified moodboard. I also redesigned the home screen and navigation to feel like a creative UX design tool.

---

## New Edits

---

### 1. Added `.combined` source type to `SavedBoard.swift`

**What I changed:** The `BoardSourceType` enum originally had two cases — `.artwork` (from the Met) and `.photo` (from your camera roll). I added a third: `.combined`.

**How it works:** `SavedBoard` is a SwiftData `@Model` — it's the object saved to the device's local database. The source type tells the app where the board's image came from so it knows how to re-render it later. I also added three new optional fields:
- `photoImageData` — stores the personal photo as compressed JPEG bytes (since it can't be re-fetched from PhotosPicker after the session ends)
- `artworkColorCount` — how many swatches came from the Met artwork
- `photoColorCount` — how many came from the personal photo

---

### 2. Added `extractCombined()` to `PaletteExtractor.swift`

**What I changed:** Added a new method to the existing `PaletteExtractor` service.

**How it works:** `PaletteExtractor` uses Core Image to downsample an image to 64×64 pixels and count which color "buckets" appear most — no ML, just pixel math. The original `extract()` handled one image at a time. My `extractCombined()` takes two images (artwork + photo), runs extraction on both **simultaneously** using Swift's `async let` concurrency keyword, then concatenates the results with artwork colors first. Running them concurrently means it's faster than running sequentially.

---

### 3. Added `generateCombined()` to `PaletteNamer.swift`

**What I changed:** Added a second generation method alongside the original `generate()`.

**How it works:** `PaletteNamer` talks to Apple's on-device Foundation Models LLM via the `@Generable` macro — this is the same AI that powers Writing Tools on iPhone. The original method sent the model hex codes from one painting. My `generateCombined()` gives the model a richer prompt explaining that the colors come from *two* sources, and asks it to name the result as a **UX design direction** (something a designer would name a Figma color theme). The model returns a typed `PaletteBoard` struct — no JSON parsing needed.

---

### 4. Created `CombinePickerView.swift` (new file)

**What I built:** A two-step screen that walks the user through picking both sources.

**How it works:**
- **Step 1** — A searchable artwork grid powered by the Met API. Tapping an artwork highlights it with a terracotta border and automatically advances to step 2.
- **Step 2** — Apple's `PhotosPicker` sheet opens. Once the user picks a photo it loads as a `UIImage` and the app navigates to `CombinedBoardView`.
- A numbered step indicator at the top (pill-shaped) shows your progress.
- Accepts an optional `preselectedArtwork` parameter so that tapping "Combine with My Photo" from an artwork's detail page skips step 1 entirely.

---

### 5. Created `CombinedBoardView.swift` (new file)

**What I built:** The main Combined VisionBoard screen.

**How it works:**
- Loads the Met artwork image from its URL via `ImageLoader` (a URLSession wrapper)
- Calls `extractCombined()` to get colors from both images concurrently
- Calls `generateCombined()` to ask the LLM for a palette name, mood tag, color names, and description
- Layout is fully stacked and scrollable: **artwork image** (full-width, 280pt) → **"Your Photo" label** → **personal photo** (full-width, 240pt) → **split swatch row** → board name, mood pill, description, source attribution, and action buttons
- The swatch row shows artwork colors on the left and photo colors on the right, split by a thin terracotta line with small source labels above each group
- Tapping any swatch copies its hex code to the clipboard with a "Copied!" overlay animation
- A `DisclosureGroup` lets the user adjust the color split ratio (default: 3 artwork + 2 photo) and re-extract
- "Save Board" opens `SaveBoardSheet` with the `.combined` source type

---

### 6. Added "Combine with My Photo" button to `ArtworkDetailView.swift`

**What I changed:** The original view had one primary button: "Create Inspo Board." I added a second button below it.

**How it works:** Tapping "Combine with My Photo" navigates to `CombinePickerView(preselectedArtwork: artwork)`, skipping the artwork search step since the user is already on the artwork they want.

---

### 7. Added "New Combined VisionBoard" button to `ProfileView.swift`

**What I changed:** Added a second entry point beneath the existing "New Board from Photo" button.

**How it works:** Navigates to `CombinePickerView()` with no preselection, so the user goes through the full two-step flow. This is the entry point for building a combined board when starting from scratch.

---

### 8. Added a working search bar to `ExploreView.swift`

**What I changed:** The original Explore tab had a decorative search icon that did nothing. I added a real `TextField`.

**How it works:** On submit, it calls `viewModel.loadArtworks(query:)` which fires a new Met Museum API request — first hitting `/search?q=\(query)&hasImages=true` for object IDs, then fetching full details for up to 15 results. An "×" button clears the field and reloads the default query.

---

### 9. Added hex copy-on-tap to `SwatchRowView.swift`

**What I changed:** Made each color swatch tappable.

**How it works:** Tapping calls `UIPasteboard.general.string = color.hex` to copy the hex code (e.g. `#B34519`) to the system clipboard — ready to paste directly into Figma or any design tool. A "Copied!" overlay fades in on the swatch and dismisses after 1.2 seconds using `DispatchQueue.main.asyncAfter`.

---

### 10. Updated `SaveBoardSheet.swift` for combined boards

**What I changed:** Added `photoImageData`, `artworkColorCount`, and `photoColorCount` parameters.

**How it works:** These new fields flow through to the `SavedBoard` SwiftData insert. The Met artwork image is still saved as a URL string (re-fetchable), but the personal photo must be stored as JPEG bytes since PhotosPicker doesn't give you a stable reference after the session ends.

---

### 11. Updated `SavedBoardDetailView.swift` for the combined case

**What I changed:** Added `.combined` to the `sourceLabel` switch statement.

**How it works:** Swift `switch` statements on enums must be exhaustive — adding the new `.combined` case makes the app show "Combined VisionBoard" as the source label on the saved board detail screen.

---

### 12. Added a COMBINE tab to `ContentView.swift`

**What I changed:** Expanded from 3 tabs (Home, Explore, Profile) to 4 (Home, Explore, Combine, Profile).

**How it works:** `AppTab` is a Swift enum conforming to `CaseIterable`. Adding a `.combine` case with its SF Symbol icon name and wiring it to `CombinePickerView()` in the `switch` is all that's needed — the `ForEach(AppTab.allCases)` loop in the tab bar renders it automatically.

---

### 13. Redesigned tab bar to icons only

**What I changed:** Removed text labels; the bar now shows only SF Symbol icons.

**How it works:** The `TabBarItem` view was simplified to a single `Image(systemName:)`. The selected state uses the `.fill` variant of the icon (e.g. `"safari.fill"`) and renders it in terracotta. The bar background uses `.ultraThinMaterial` — iOS's frosted-glass blur effect — instead of a flat cream rectangle.

---

### 14. Redesigned Home page as a scrapbook / digital camera collage

**What I changed:** Completely rewrote `HomeView` and replaced `ArtworkCardView` with `PolaroidCard`.

**How it works:**
- Artworks are split into two arrays (even-indexed / odd-indexed) and rendered as two independent `VStack` columns inside an `HStack`, with one column offset lower than the other — this creates the staggered, hand-placed collage feel without a third-party library.
- Each `PolaroidCard` is a white card using `scaledToFit` (so the full artwork is always visible, never cropped), a strip of 5 extracted color dots below the image, the title in small serif, and the artist in monospaced type.
- **Rotation:** `rotationEffect(.degrees(tilt))` where `tilt = Double((artwork.objectID % 9) - 4) * 0.6`. Using the objectID as a seed means each card always tilts the same amount — it won't re-randomize on re-render — but every card is different, ranging roughly -2.4° to +2.4°.
- **Lazy color extraction:** Each card runs `PaletteExtractor.shared.extract()` inside a `.task` modifier so extraction only happens for cards currently visible on screen, keeping scrolling smooth.
- **Date stamp:** The artwork's date string is overlaid in the corner of the photo with a semi-transparent background — like a digicam timestamp.
- The header shows a `"⬤ REC"` badge for the digital camera aesthetic, and the loading state reads "Developing…" in monospaced type.

---

## Final App Structure

```
MetDigitalGallery/
├── MetDigitalGalleryApp.swift       ← SwiftData ModelContainer setup
├── ContentView.swift                ← 4-tab navigation + icon-only tab bar
├── ArtworkListView.swift            ← Home: scrapbook polaroid collage
├── ArtworkDetailView.swift          ← Artwork detail + two action buttons
├── ExploreView.swift                ← Explore: searchable 2-column grid
├── ProfileView.swift                ← Profile: collections + two creation entry points
├── ArtObject.swift                  ← Met API model
├── ArtworkViewModel.swift           ← URLSession ViewModel
├── GalleryTheme.swift               ← Design tokens (terracotta, cream, fonts)
└── InspoBoard/
    ├── Models/
    │   ├── SavedBoard.swift         ← SwiftData model (now with .combined type)
    │   ├── BoardCollection.swift    ← SwiftData collection grouping
    │   ├── PaletteBoard.swift       ← @Generable LLM output type
    │   └── DominantColor.swift      ← Extracted color wrapper
    ├── Services/
    │   ├── PaletteExtractor.swift   ← Pixel color extraction + extractCombined()
    │   ├── PaletteNamer.swift       ← Foundation Models LLM + generateCombined()
    │   └── ImageLoader.swift        ← URL → UIImage async loader
    └── Views/
        ├── CombinePickerView.swift  ← NEW: two-step artwork + photo picker
        ├── CombinedBoardView.swift  ← NEW: stacked dual-source moodboard
        ├── PaletteBoardView.swift   ← Single-source inspo board
        ├── SaveBoardSheet.swift     ← Save to collection (updated for combined)
        ├── SavedBoardDetailView.swift
        ├── CollectionListView.swift
        ├── CollectionDetailView.swift
        ├── SwatchRowView.swift      ← Color swatches + hex copy-on-tap
        └── AvailabilityGateView.swift
```
