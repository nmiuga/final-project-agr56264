//
//  PaletteBoard.swift
//  MetDigitalGallery — Inspo Board feature
//
//  The structured output type Foundation Models fills in for us. The
//  @Generable macro generates a JSON schema at compile time; @Guide adds
//  natural-language hints so the model knows what "good" looks like for
//  each field. We hand this struct to LanguageModelSession and get back
//  a typed Swift value — no string parsing.
//
//  Note: this is the *transient* palette produced by the LLM. When the
//  user taps "Save to Collection", we copy these fields into a persistent
//  SavedBoard (see Models/SavedBoard.swift).
//

import Foundation
import FoundationModels

// MARK: - PaletteBoard

@Generable
struct PaletteBoard: Equatable, Hashable {

    /// Display headline for the board — shown as the big serif title.
    // Prompting note: "2-4 words" + example names keeps the model from
    // defaulting to generic labels like "Blueish-Gray Palette".
    @Guide(description: "A poetic 2-4 word name evocative of the palette's mood, like 'Terracotta Sunset' or 'Gothic Twilight'")
    let name: String

    /// One-sentence evocative description shown below the swatches.
    // Prompting note: capping at 20 words prevents multi-paragraph runs.
    @Guide(description: "One sentence, max 20 words, describing the feeling of this palette")
    let description: String

    /// Human-readable names for each hex the caller supplied, in order.
    // Prompting note: "in the same order" matters — otherwise the model
    // sometimes reorders colors by importance and labels drift off swatches.
    @Guide(description: "3-5 short color names matching each supplied hex value, in the same order")
    let colorNames: [String]

    /// Single-word mood tag shown as a pill on the moodboard.
    // Prompting note: one-word constraint keeps the pill from wrapping.
    @Guide(description: "A single adjective describing the mood, like 'moody', 'sun-drenched', 'austere'")
    let mood: String
}
