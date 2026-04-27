# Edits
The initial prompt that I made using claude: 

## App: MET Inspo — Art Inspiration Board

###Final project edits at the bottom

---

Build a SwiftUI iOS app called **MET Inspo** that fetches artwork data from the Metropolitan Museum of Art's public API (no key required) and displays it as a scrollable visual inspiration board, similar to Pinterest. The app should feel like an editorial art gallery — clean, sophisticated, and image-forward.

---

## API Details

This app uses a **two-step fetch** from the Met Museum Collection API.

### Step 1 — Search for object IDs
```
GET https://collectionapi.metmuseum.org/public/collection/v1/search?q=painting&hasImages=true
```
Returns a JSON object with this structure:
```json
{
  "total": 4321,
  "objectIDs": [436535, 12345, 67890, ...]
}
```

### Step 2 — Fetch each artwork by ID
```
GET https://collectionapi.metmuseum.org/public/collection/v1/objects/{objectID}
```
Returns a JSON object. The fields I want to use are:
```json
{
  "objectID": 436535,
  "title": "Bridge over a Pond of Water Lilies",
  "artistDisplayName": "Claude Monet",
  "primaryImageSmall": "https://images.metmuseum.org/...",
  "department": "European Paintings",
  "objectDate": "1899",
  "medium": "Oil on canvas",
  "culture": "French"
}
```
Use `primaryImageSmall` (not `primaryImage`) for performance.

---

## Data Models (Codable Structs)

Create a file called `ArtworkModel.swift` with two Codable structs:

1. `SearchResponse` — models the search endpoint response with `total: Int` and `objectIDs: [Int]`
2. `Artwork` — models the object endpoint response with the fields listed above. Make it `Identifiable` using `objectID` as the `id`. Add a computed property `imageURL: URL?` that converts `primaryImageSmall` to a URL.

---

## ViewModel

Create a file called `ArtworkViewModel.swift` with an `@MainActor` class `ArtworkViewModel: ObservableObject`.

It should:
- Have a `@Published var artworks: [Artwork] = []`
- Have a `@Published var isLoading: Bool = false`
- Have an async function `fetchArtworks(query: String = "painting")` that:
  1. Fetches the search endpoint to get object IDs
  2. Takes only the first 20 IDs using `.prefix(20)`
  3. Loops through the IDs and fetches each artwork object
  4. Only appends artworks where `primaryImageSmall` is not empty
  5. Uses `URLSession.shared.data(from:)` with async/await
  6. Uses `JSONDecoder` to decode both response types
  7. Sets `isLoading` to true at the start and false when done

---

## Design System

Apply these values consistently across all views:

| Token | Value |
|---|---|
| App background | `#F5F0EB` (warm cream) |
| Card background | `#FFFFFF` |
| Accent / highlight | `#B5451B` (terracotta) |
| Primary text | `#1A1A1A` |
| Secondary text | `#6B6B6B` |
| Card corner radius | 12pt |
| Image corner radius | 12pt |
| Card shadow | `color: .black.opacity(0.07), radius: 8, x: 0, y: 4` |
| Section label tracking | 1.5pt letter spacing |

Add a `Color+Hex.swift` extension:
```swift
extension Color {
    init(hex: String) {
        // standard hex-to-Color implementation
    }
}
```

Set the global background with `.background(Color(hex: "#F5F0EB").ignoresSafeArea())` on all ScrollViews.

---

## Typography

Use at least four distinct text styles:

| Role | Style | Color | Notes |
|---|---|---|---|
| Hero title "Curated Visions" | `.custom("Georgia-Bold", size: 34)` or largest serif available | Terracotta `#B5451B` | Home screen only |
| Artwork title | `.custom("Georgia", size: 20)` | `#1A1A1A` | Serif, bold |
| Detail view title | `.custom("Georgia-Bold", size: 34)` | `#1A1A1A` | Multiline allowed |
| Department / section labels | `.caption`, `.textCase(.uppercase)`, `.tracking(1.5)` | `#B5451B` | All caps, terracotta |
| Artist name + date | `.subheadline` | `#6B6B6B` | Regular weight |
| Body / subtitle text | `.body` | `#6B6B6B` | Home screen hero subtitle |

---

## Screen 1 — Home Feed (`ContentView.swift`)

### Navigation Bar
- Leading: `Image(systemName: "line.3.horizontal")` icon, `#1A1A1A`
- Center: Text "MET Inspo" in italic serif font `.custom("Georgia-Italic", size: 20)`
- Trailing: `Image(systemName: "magnifyingglass")` icon, `#1A1A1A`
- Nav bar background: `#F5F0EB`, no separator line

### Hero Section (above the card list)
```
VStack(alignment: .leading, spacing: 12) {
    Text("Curated Visions")
        // large terracotta serif, ~34pt
    Text("A digital gateway to the world's most evocative art, selected for the discerning eye.")
        // body, gray, regular weight
}
.padding(.horizontal, 16)
.padding(.top, 8)
```

### Card List
- `ScrollView` → `LazyVStack(spacing: 16)` → `padding(16)`
- `ForEach` over `viewModel.artworks` rendering `ArtworkCard`
- Trigger with `.task { await viewModel.fetchArtworks() }`
- Show `ProgressView()` overlay while loading

### Bottom Tab Bar
Create a custom tab bar with three tabs: HOME, EXPLORE, PROFILE.
- Each tab: SF Symbol icon above uppercase caption label (`.caption`, `.tracking(1.2)`)
- Active tab: terracotta oval/pill background (`#B5451B`) behind icon, icon and label in white
- Inactive tabs: gray `#6B6B6B` icons and labels
- Tab bar background: white `#FFFFFF` with a subtle top border `Color.gray.opacity(0.2)`
- Use a `TabView` or custom `HStack` at the bottom of the screen

---

## Screen 2 — Artwork Card (`ArtworkCard.swift`)

Card structure (top to bottom inside a white rounded rectangle):

1. **Image block**
   - `AsyncImage` with `.scaledToFill()`, frame height 280, `.clipped()`, corner radius 12
   - Placeholder: `Rectangle().fill(Color(hex: "#E8E2D9"))`

2. **Metadata block** — `VStack(alignment: .leading, spacing: 6)`, padding 14
   - Department: `.caption`, `.textCase(.uppercase)`, `.tracking(1.5)`, terracotta color
   - Title: Georgia serif ~20pt, near-black
   - Artist + year on one line: `.subheadline`, gray. If `artistDisplayName` is empty use "Unknown Artist"

Apply to card container:
- `.background(Color.white)`
- `.cornerRadius(12)`
- `.shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)`

Tapping a card navigates to `ArtworkDetailView`.

---

## Screen 3 — Artwork Detail (`ArtworkDetailView.swift`)

### Layout
- Full-bleed `AsyncImage` at the top of the screen extending behind the status bar, height ~45% of screen height, `.scaledToFill()`, `.clipped()`
- A white rounded card overlapping the image from below:
  - `.cornerRadius(24)` on top corners only (use `.clipShape(RoundedCorner(radius: 24, corners: [.topLeft, .topRight]))`)
  - `.offset(y: -28)` so it slides up over the image
  - Padding inside: 24pt all sides

### Floating Buttons (over the image)
- Back button: top left, `Image(systemName: "chevron.left")`, white circle background, shadow
- Heart/save button: top right, `Image(systemName: "heart")`, white circle background, shadow
- Both buttons: 44×44pt, white fill, corner radius 22, shadow `radius: 4, opacity: 0.15`

### Inside the White Card (top to bottom)
```
"MASTERPIECE DETAIL"   ← caption, uppercase, terracotta, tracking 2.0
"Portrait of a Noblewoman"   ← large Georgia serif bold ~34pt, near-black, multiline
"Circa 1545"   ← terracotta, ~16pt
"Accession No. 29.100.6"   ← gray caption (use objectID formatted as accession if needed)

Divider()

Label section — repeat for each field:
  Text("ARTIST")   ← caption uppercase gray tracking 1.5
  Text(artwork.artistDisplayName)   ← body, near-black

Label section:
  Text("MEDIUM")   ← caption uppercase gray
  Text(artwork.medium)   ← body

Label section:
  Text("DEPARTMENT")   ← caption uppercase gray
  Text(artwork.department)   ← body
```

---

## Screen 4 — Explore View (`ExploreView.swift`)

### Header
```
HStack {
    Text("Explore the\nCollection")   ← large serif, ~28pt, near-black
    Spacer()
    Text("VIEW GALLERY")   ← caption uppercase terracotta, tracking 1.5
}
.padding(16)
```

### Grid
- `LazyVGrid` with 2 columns, spacing 12, padding 16
- Each cell: `AsyncImage`, `.scaledToFill()`, `.frame(height: 160)`, `.clipped()`, `.cornerRadius(12)`

---

## Project Structure

Create these files:
- `METInspoApp.swift` — app entry point, sets accent color
- `ContentView.swift` — home feed with hero section and card list
- `ArtworkCard.swift` — reusable card component
- `ArtworkDetailView.swift` — full detail screen
- `ExploreView.swift` — 2-column grid explore screen
- `ArtworkModel.swift` — Codable structs
- `ArtworkViewModel.swift` — ObservableObject with URLSession fetch
- `Color+Hex.swift` — hex color extension
- `RoundedCorner.swift` — Shape extension for one-sided corner radius

---

## Notes
- Target iOS 16+
- Use `async/await` and `URLSession` only — no Combine, no third-party networking
- Use `AsyncImage` — no third-party image libraries
- Set `AccentColor` in `Assets.xcassets` to `#B5451B`
- The app must compile and run without errors on a real device or simulator
- NavigationStack with `.navigationBarHidden(true)` on the detail view so the floating buttons show correctly

##CODEX

As I ran into errors, I went to the errors and "Generated" fixes for the little things that popped up. 


## FINAL - Claude Code edits

1. Deleted duplicate and conflicting Swift files that were causing the project to not compile
2. Rewrote ContentView.swift to remove everything that didn't belong there and kept only the tab bar
3. Added a .combined source type to SavedBoard so the app can save boards made from two sources
4. Added extra fields to SavedBoard to store the personal photo, and remember how many colors came from each source
5. Added a new method to PaletteExtractor that pulls colors from two images at the same time instead of one at a time
6. Added a new method to PaletteNamer that prompts the AI with both color sources and asks it to name the palette like a UX design direction
7. Built CombinePickerView — a two step screen where you pick a Met artwork first then a photo from your camera roll
8. Built CombinedBoardView — the screen that shows both images stacked on top of each other with the merged color palette and all the board info below it
9. Added a "Combine with My Photo" button to the artwork detail page
10. Added a "New Combined VisionBoard" button to the profile page
11. Made the search bar in the Explore tab actually work and pull results from the Met API
12. Made every color swatch tappable so it copies the hex code to your clipboard
13. Updated the save sheet and saved board detail screen to handle the new combined board type
14. Added a fourth Combine tab to the bottom navigation
15, Changed the tab bar to show icons only with no text
16. Redesigned the home page as a scrapbook polaroid collage with staggered cards, slight rotations, color dots, and a digital camera timestamp on each photo
