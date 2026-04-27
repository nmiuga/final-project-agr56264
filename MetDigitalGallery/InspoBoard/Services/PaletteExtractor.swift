//
//  PaletteExtractor.swift
//  MetDigitalGallery — Inspo Board feature
//
//  The pixel layer. Takes a UIImage, returns the N most dominant colors
//  as DominantColor values. Simple downsample + quantize + count — fast
//  enough for a rough draft, no ML needed.
//
//  Why not use Foundation Models for this? The framework is text-only at
//  launch; it can't see pixels. Pixel work happens here, then hex codes
//  are handed to PaletteNamer.
//
//  TODO: upgrade to true k-means for better perceptual accuracy — current
//        bucket-count approach over-rewards large flat backgrounds.
//

import UIKit
import CoreImage

// MARK: - PaletteExtractor

final class PaletteExtractor {

    static let shared = PaletteExtractor()
    private init() {}

    /// Extract the `count` most dominant colors from `image`.
    func extract(from image: UIImage, count: Int = 5) async -> [DominantColor] {

        // 1. Downsample aggressively. A 64×64 thumbnail is plenty for
        //    dominant-color detection and keeps the inner loop tiny.
        let downsampled = downsample(image: image, to: CGSize(width: 64, height: 64))
        guard let cgImage = downsampled.cgImage else { return [] }

        let width = cgImage.width
        let height = cgImage.height

        // 2. Draw the thumbnail into a raw RGBA buffer we walk directly.
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 3. Quantize to 32 steps per channel → max 512 buckets. Enough
        //    granularity to distinguish warm from cool terracottas, coarse
        //    enough that near-duplicates collapse together.
        var buckets: [UInt32: Int] = [:]
        let quantize: UInt8 = 32

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let r = (pixelData[offset]     / quantize) * quantize
                let g = (pixelData[offset + 1] / quantize) * quantize
                let b = (pixelData[offset + 2] / quantize) * quantize
                let key = (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
                buckets[key, default: 0] += 1
            }
        }

        // 4. Top N buckets → DominantColor values.
        let top = buckets.sorted { $0.value > $1.value }.prefix(count)

        return top.map { key, _ in
            let r = CGFloat((key >> 16) & 0xFF) / 255.0
            let g = CGFloat((key >> 8)  & 0xFF) / 255.0
            let b = CGFloat( key        & 0xFF) / 255.0
            let ui = UIColor(red: r, green: g, blue: b, alpha: 1.0)
            return DominantColor(hex: ui.hexString, uiColor: ui)
        }
    }

    /// Extract colors from two images concurrently, then merge them.
    /// - Parameters:
    ///   - artworkImage: image from the Met collection
    ///   - photoImage: image from the user's photo library
    ///   - artworkCount: swatches to take from artwork (default 3)
    ///   - photoCount: swatches to take from photo (default 2)
    /// - Returns: merged array [artwork colors..., photo colors...] = artworkCount + photoCount
    func extractCombined(
        artworkImage: UIImage,
        photoImage: UIImage,
        artworkCount: Int = 3,
        photoCount: Int = 2
    ) async -> [DominantColor] {
        async let artworkColors = extract(from: artworkImage, count: artworkCount)
        async let photoColors   = extract(from: photoImage,   count: photoCount)
        return await artworkColors + photoColors
    }

    // MARK: - Helpers

    private func downsample(image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
