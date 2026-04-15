# MetDigitalGallery — Project Reflection

## Overview

MetDigitalGallery is an iOS app built with SwiftUI that connects to the Metropolitan Museum of Art's free public Collection API. Users can browse curated artwork, explore the full collection in a grid view, and tap into a detail screen for metadata on any piece. The app was designed to match a provided Figma mockup, using a warm terracotta and cream color palette and custom serif typography.

---

## What I Built

The app has three tabs, each representing a distinct part of the experience:

- **Home** — A vertically scrolling feed of artwork cards pulled live from the Met API. Each card shows the full-width image, department label, title, and artist/date. Tapping a card pushes a detail view.
- **Explore** — A two-column image grid for browsing the collection visually. Each thumbnail navigates to the same detail screen.
- **Profile** — A placeholder profile screen styled to match the app's design system, with a mock user and settings rows.

---

## Technical Decisions

**MVVM Architecture**
I used the Model–View–ViewModel pattern throughout. `ArtObject.swift` holds the data models that map directly to the Met API's JSON shape using `Codable`. `ArtworkViewModel` handles all network logic using `async/await` and `URLSession`, keeping views clean and focused on layout.

**Met Museum API**
The app performs a two-step fetch: first calling the `/search` endpoint to get matching object IDs, then fetching full metadata from `/objects/{id}` for each result. I capped results at 15 items per search to keep load times reasonable.

**Design Tokens**
Rather than scattering raw hex strings everywhere, I centralized the color palette and typography into `GalleryTheme.swift`. This made it easy to stay consistent with the Figma design and change values in one place.

**Custom Tab Bar**
SwiftUI's built-in `TabView` didn't match the Figma design, so I built a custom bottom navigation bar with a capsule-shaped active-state highlight in terracotta. The active tab shows white text on a terracotta pill; inactive tabs use a muted gray.

---

## Challenges

The biggest challenge was managing the project file structure. Over multiple iterations, files accumulated duplicate definitions — two entry points, two model types, and the same views defined both inline in `ContentView.swift` and in their own files. This caused a cascade of "invalid redeclaration" compile errors that had to be untangled carefully by identifying the authoritative version of each type and deleting the rest.

Another challenge was handling the Met API's inconsistent data — many fields like `artistDisplayName`, `culture`, and `period` are empty strings rather than `null` for a large portion of objects. The app handles this gracefully by checking for empty strings and falling back to safe display values like "Unknown Artist."

---

## What I Learned

- How to consume a real public REST API in Swift using `async/await` and `Codable`
- How to structure an iOS app with MVVM so that network logic stays out of views
- How to implement a custom navigation bar and tab bar in SwiftUI to match a Figma design exactly
- The importance of keeping one authoritative definition per type — duplicate files are a quick path to compile errors that are painful to debug

---

## If I Had More Time

- Add a search bar on the Explore tab so users can search by keyword, artist, or department
- Persist favorited artworks with SwiftData so the Profile tab shows a real saved collection
- Add a department filter to the Home feed
- Improve the Explore grid with artwork titles overlaid on the thumbnails
