//
//  PaletteNamer.swift
//  MetDigitalGallery — Inspo Board feature
//
//  Takes the hex codes PaletteExtractor produced plus optional artwork
//  metadata, asks Apple's on-device Foundation Models LLM to return a
//  fully-typed PaletteBoard via the @Generable macro.
//
//  Requires iOS 26+ and an Apple Intelligence-eligible device.
//

import Foundation
import FoundationModels

// MARK: - Errors

enum PaletteNamerError: Error, LocalizedError {
    case modelUnavailable(reason: String)
    case generationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let reason):
            return "Apple Intelligence is unavailable: \(reason)"
        case .generationFailed(let error):
            return "Couldn't generate a palette name: \(error.localizedDescription)"
        }
    }
}

// MARK: - PaletteNamer

final class PaletteNamer {

    static let shared = PaletteNamer()
    private init() {}

    /// Generate a named, described, mood-tagged palette board.
    func generate(
        hexes: [String],
        artworkTitle: String? = nil,
        artist: String? = nil
    ) async throws -> PaletteBoard {

        // 1. Availability gate.
        let availability = SystemLanguageModel.default.availability
        switch availability {
        case .available:
            break
        case .unavailable(let reason):
            throw PaletteNamerError.modelUnavailable(reason: "\(reason)")
        @unknown default:
            throw PaletteNamerError.modelUnavailable(reason: "Unknown availability state")
        }

        // 2. Session with curator-style instructions.
        let instructions = """
        You are an expert art curator writing display copy for a museum inspo board.
        Your voice is poetic, concise, and evocative — more like gallery wall text
        than a product description. Avoid generic color terms.
        """
        let session = LanguageModelSession(instructions: instructions)

        // 3. Build the prompt. Fold in artwork metadata when available so
        //    the LLM can ground its response in real context.
        var prompt = "Generate a palette board for these \(hexes.count) dominant colors"
        if let title = artworkTitle {
            prompt += " from the artwork titled \"\(title)\""
            if let artist = artist {
                prompt += " by \(artist)"
            }
        }
        prompt += ": " + hexes.joined(separator: ", ") + "."

        // 4. Structured response via @Generable.
        do {
            let response = try await session.respond(
                to: prompt,
                generating: PaletteBoard.self
            )
            return response.content
        } catch {
            throw PaletteNamerError.generationFailed(underlying: error)
        }
    }

    /// Generate a board name for a palette merged from two sources:
    /// a Met artwork and a personal photo. The LLM is told about both
    /// sources so it can treat the board as a dialogue between the two.
    func generateCombined(
        artworkHexes: [String],
        photoHexes: [String],
        artworkTitle: String? = nil,
        artist: String? = nil
    ) async throws -> PaletteBoard {

        // Availability gate.
        let availability = SystemLanguageModel.default.availability
        switch availability {
        case .available:
            break
        case .unavailable(let reason):
            throw PaletteNamerError.modelUnavailable(reason: "\(reason)")
        @unknown default:
            throw PaletteNamerError.modelUnavailable(reason: "Unknown availability state")
        }

        // Session with a UX design director persona.
        let instructions = """
        You are a UX design director creating a combined moodboard palette for designers.
        You are merging the color world of a museum artwork with colors from a personal photograph.
        Your voice is evocative, precise, and speaks to how these two color worlds harmonize.
        Avoid generic color terms. Name the resulting palette as if it were a design direction —
        something a designer would name a Figma color theme.
        """
        let session = LanguageModelSession(instructions: instructions)

        // Build a prompt that describes both source layers separately.
        var prompt = "Generate a combined palette board merging two color sources.\n"
        if let title = artworkTitle {
            prompt += "Source 1 — Museum artwork: \"\(title)\""
            if let artist { prompt += " by \(artist)" }
            prompt += ". Colors: \(artworkHexes.joined(separator: ", ")).\n"
        } else {
            prompt += "Source 1 — Artwork colors: \(artworkHexes.joined(separator: ", ")).\n"
        }
        prompt += "Source 2 — Personal photo colors: \(photoHexes.joined(separator: ", ")).\n"
        prompt += "Combined palette: \((artworkHexes + photoHexes).joined(separator: ", "))."

        do {
            let response = try await session.respond(
                to: prompt,
                generating: PaletteBoard.self
            )
            return response.content
        } catch {
            throw PaletteNamerError.generationFailed(underlying: error)
        }
    }
}
