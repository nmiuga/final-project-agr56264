# Initial AI Prompt — VisionBoard for Color

---

Build me a native iOS app called **VisionBoard for Color** for UX designers who want to pull color inspiration from real artwork and their own photos. The app should connect to the Metropolitan Museum of Art's free public API (no key required) and let users browse the collection, extract dominant color palettes from artworks, combine those palettes with colors from their personal photos, and save the results as styled moodboards.

---

## Design

Use a warm, earthy aesthetic throughout — not clinical or bright. The color palette is:
- Background: cream `#F5EFE4`
- Accent / primary action: terracotta `#B34519`
- Card backgrounds: white
- Secondary surfaces: a slightly darker cream

Use custom serif typography for headlines and monospaced type for labels and secondary text. Centralize all colors and fonts into a `GalleryTheme.swift` design token file so nothing is hardcoded across views.

---

## App Structure — 4 Tabs

### 1. Home — Scrapbook Collage
The home screen should feel like a physical moodboard or a digital camera roll. Show Met artworks as **polaroid-style cards** arranged in a staggered two-column layout. Each card should:
- Show the full artwork image (never cropped — use `scaledToFit`)
- Be slightly rotated using a deterministic tilt based on the artwork's ID (so it doesn't re-randomize on re-render)
- Have a strip of 5 extracted color dots below the image
- Show the artwork title in small serif and artist in monospaced type
- Include a date stamp watermark in the corner of the photo, like a digicam timestamp

The header should have a `⬤ REC` badge for the digital camera aesthetic. Loading state should say "Developing…" in monospaced type.

### 2. Explore — Search the Collection
A two-column image grid connected to the Met Museum API. Include a real working search bar — typing a term and submitting fires a new API request (`/search?q=TERM&hasImages=true` for IDs, then `/objects/{id}` for up to 15 results). An × button clears search and reloads a default query.

### 3. Combine — Dual-Source VisionBoard
This is the main feature. A two-step picker:
- **Step 1**: Searchable artwork grid (same Met API). Tap to select with a terracotta border. Automatically advance to Step 2.
- **Step 2**: Apple's `PhotosPicker` opens. Once a photo is selected, navigate to the Combined Board screen.
- A numbered step indicator pill at the top shows progress.
- Accept an optional `preselectedArtwork` parameter so tapping "Combine" from an artwork detail page skips Step 1.

**Combined Board screen:**
- Full-width artwork image (280pt height) stacked above a "Your Photo" label and then the personal photo (240pt height)
- Below: board name (AI-generated, 30pt serif), mood pill (terracotta capsule), and a split swatch row — artwork colors on the left, photo colors on the right, separated by a thin terracotta divider line with "Artwork" / "Your Photo" labels in 8pt type above each group
- Tapping any swatch copies its hex code to the clipboard with a "Copied!" overlay animation
- A `DisclosureGroup` labeled "Adjust color split" contains a `Stepper` for artwork vs. photo swatch count (always totaling 5) and a "Re-extract" button
- Action buttons: Regenerate (reruns AI naming) and Save Board
- Source attribution at the bottom with the artwork title/artist and "Your photo"

### 4. Profile — Saved Boards & Collections
Display saved boards organized into collections the user creates. Include two entry points: "New Board from Photo" and "New Combined VisionBoard" (navigates to the Combine tab flow). Boards save to SwiftData and display in a `CollectionDetailView`.

---

## Technical Requirements

- **Met Museum API** — two-step fetch: `/search` for IDs then `/objects/{id}` for metadata. Cap at 15 results per request.
- **Core Image color extraction** — downsample images to 64×64, quantize RGB into 32-step buckets, return top-N dominant colors as `DominantColor` objects (with a `Color`, `hex` string, and `id`).
- **`extractCombined()` using `async let`** — run extraction on the artwork image and personal photo simultaneously, then concatenate results. Artwork colors come first.
- **Apple Foundation Models (`@Generable` macro)** — use on-device AI to name each palette. For single-source boards, send hex codes and ask for a palette name, mood, color names, and description. For combined boards, use a richer prompt that frames the result as a UX design direction merging two color worlds. Return a typed `PaletteBoard` struct — no JSON parsing needed.
- **SwiftData (`@Model`, `@Query`)** — `SavedBoard` and `BoardCollection` persisted to the device database. `SavedBoard` should have a `BoardSourceType` enum (`.artwork`, `.photo`, `.combined`). The `.combined` case needs extra fields: `photoImageData: Data?`, `artworkColorCount: Int?`, `photoColorCount: Int?`.
- **`PhotosPicker`** — native photo library access with no manual permissions code.
- **`ImageLoader`** — async URL-to-UIImage loader using `URLSession`, with an `NSCache` to prevent re-downloading.
- **`NavigationStack` + `.task`** — push screens onto a navigation stack; tie async work to view lifecycle so it cancels on back-navigation.
- **Tab bar** — icon-only (no text labels), using SF Symbol fill variants for the selected state, frosted glass `.ultraThinMaterial` background.

---

## Requirements

- iOS 26+, Xcode 26+
- Apple Intelligence-eligible device required for palette naming (iPhone 15 Pro or later, M-series iPad). Color extraction works on all devices.
- No third-party dependencies — Apple frameworks only.

---

## File Structure

```
MetDigitalGallery/
├── MetDigitalGalleryApp.swift       ← SwiftData ModelContainer
├── ContentView.swift                ← 4-tab navigation + icon-only tab bar
├── ArtworkListView.swift            ← Home scrapbook collage
├── ArtworkDetailView.swift          ← Detail + two action buttons
├── ExploreView.swift                ← Searchable grid
├── ProfileView.swift                ← Collections + two creation entry points
├── ArtObject.swift                  ← Met API models (Codable)
├── ArtworkViewModel.swift           ← URLSession ViewModel
├── GalleryTheme.swift               ← Design tokens
└── InspoBoard/
    ├── Models/                      ← SavedBoard, BoardCollection, PaletteBoard, DominantColor
    ├── Services/                    ← PaletteExtractor, PaletteNamer, ImageLoader
    └── Views/                       ← CombinePickerView, CombinedBoardView, PaletteBoardView,
                                         SaveBoardSheet, SavedBoardDetailView,
                                         CollectionListView, CollectionDetailView,
                                         SwatchRowView, AvailabilityGateView
```
