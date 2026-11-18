//
//  ShelfImageTools.swift
//  DynamicBar
//

import AppKit
import CoreImage
import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import Vision

enum ShelfImageError: LocalizedError {
    case cannotReadImage
    case cannotCreateOutput
    case cannotWriteOutput
    case noForegroundFound

    var errorDescription: String? {
        switch self {
        case .cannotReadImage:
            return "macOS could not read this image format."
        case .cannotCreateOutput:
            return "Could not create the output file."
        case .cannotWriteOutput:
            return "Could not finish writing the output file."
        case .noForegroundFound:
            return "No foreground subject was found."
        }
    }
}

enum ShelfImageTools {
    private static func withReadAccess<T>(
        to url: URL,
        _ work: () throws -> T
    ) throws -> T {
        let startedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if startedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try work()
    }

    private static func readImage(at url: URL) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ShelfImageError.cannotReadImage
        }

        return image
    }

    private static func writeImage(
        _ image: CGImage,
        to url: URL,
        type: UTType,
        properties: CFDictionary? = nil
    ) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            type.identifier as CFString,
            1,
            nil
        ) else {
            throw ShelfImageError.cannotCreateOutput
        }

        CGImageDestinationAddImage(destination, image, properties)

        guard CGImageDestinationFinalize(destination) else {
            throw ShelfImageError.cannotWriteOutput
        }
    }

    static func convertToJPEG(source: URL, destination: URL) throws {
        try withReadAccess(to: source) {
            let image = try readImage(at: source)
            try writeImage(image, to: destination, type: .jpeg)
        }
    }

    static func convertToPDF(source: URL, destination: URL) throws {
        try withReadAccess(to: source) {
            let image = try readImage(at: source)
            var mediaBox = CGRect(
                x: 0,
                y: 0,
                width: CGFloat(image.width),
                height: CGFloat(image.height)
            )

            guard let pdf = CGContext(
                destination as CFURL,
                mediaBox: &mediaBox,
                nil
            ) else {
                throw ShelfImageError.cannotCreateOutput
            }

            pdf.beginPDFPage(nil)
            pdf.draw(image, in: mediaBox)
            pdf.endPDFPage()
            pdf.closePDF()
        }
    }

    // This creates a lossy JPEG. JPEG does not preserve transparency.
    static func compressAsJPEG(
        source: URL,
        destination: URL,
        quality: CGFloat = 0.72
    ) throws {
        try withReadAccess(to: source) {
            let image = try readImage(at: source)
            let clampedQuality = min(max(quality, 0), 1)
            let properties = [
                kCGImageDestinationLossyCompressionQuality: clampedQuality
            ] as CFDictionary

            try writeImage(
                image,
                to: destination,
                type: .jpeg,
                properties: properties
            )
        }
    }

    @available(macOS 14.0, *)
    static func removeBackground(source: URL, destination: URL) throws {
        try withReadAccess(to: source) {
            let image = try readImage(at: source)
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            let request = VNGenerateForegroundInstanceMaskRequest()

            try handler.perform([request])

            guard let observation = request.results?.first else {
                throw ShelfImageError.noForegroundFound
            }

            let maskedBuffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )

            let ciImage = CIImage(cvPixelBuffer: maskedBuffer)
            let context = CIContext()

            guard let output = context.createCGImage(
                ciImage,
                from: ciImage.extent
            ) else {
                throw ShelfImageError.cannotReadImage
            }

            try writeImage(output, to: destination, type: .png)
        }
    }
}

struct ShelfImageActions: View {
    let sourceURL: URL

    @State private var isWorking = false
    @State private var message = ""

    var body: some View {
        HStack {
            Button("Save JPEG") {
                perform(extension: "jpg", type: .jpeg) { source, output in
                    try ShelfImageTools.convertToJPEG(
                        source: source,
                        destination: output
                    )
                }
            }

            Button("Save PDF") {
                perform(extension: "pdf", type: .pdf) { source, output in
                    try ShelfImageTools.convertToPDF(
                        source: source,
                        destination: output
                    )
                }
            }

            Button("Compress JPEG") {
                perform(extension: "jpg", type: .jpeg) { source, output in
                    try ShelfImageTools.compressAsJPEG(
                        source: source,
                        destination: output
                    )
                }
            }

            if #available(macOS 14.0, *) {
                Button("Remove Background") {
                    perform(extension: "png", type: .png) { source, output in
                        try ShelfImageTools.removeBackground(
                            source: source,
                            destination: output
                        )
                    }
                }
            }
        }
        .disabled(isWorking)
        .overlay(alignment: .bottom) {
            if !message.isEmpty {
                Text(message).font(.caption)
            }
        }
    }

    @MainActor
    private func perform(
        extension fileExtension: String,
        type: UTType,
        operation: @escaping @Sendable (URL, URL) throws -> Void
    ) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue =
            sourceURL.deletingPathExtension().lastPathComponent
            + "."
            + fileExtension

        guard panel.runModal() == .OK, let outputURL = panel.url else {
            return
        }

        isWorking = true

        Task {
            do {
                try await Task.detached(priority: .userInitiated) {
                    try operation(sourceURL, outputURL)
                }.value
                message = "Saved."
            } catch {
                message = error.localizedDescription
            }

            isWorking = false
        }
    }
}

