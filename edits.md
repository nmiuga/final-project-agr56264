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
