import XCTest
import Nuke
@testable import LakeImage
#if canImport(AppKit)
import AppKit
#endif

final class LakeImageTests: XCTestCase {
    func testThumbnailRequestIsOptInAndSizeSpecific() {
        let url = URL(string: "https://example.com/cover.jpg")!
        let original = makeLakeImageRequest(
            url: url,
            contentMode: .fill,
            thumbnailSize: nil,
            displayScale: 2
        )
        let small = makeLakeImageRequest(
            url: url,
            contentMode: .fill,
            thumbnailSize: CGSize(width: 48, height: 48),
            displayScale: 2
        )
        let large = makeLakeImageRequest(
            url: url,
            contentMode: .fill,
            thumbnailSize: CGSize(width: 144, height: 144),
            displayScale: 2
        )

        XCTAssertNil(original.thumbnail)
        XCTAssertNotNil(small.thumbnail)
        XCTAssertNotNil(large.thumbnail)
        XCTAssertNotEqual(ImageCacheKey(request: original), ImageCacheKey(request: small))
        XCTAssertNotEqual(ImageCacheKey(request: small), ImageCacheKey(request: large))
    }

    func testInvalidThumbnailBoundsPreserveOriginalImageRequest() {
        let url = URL(string: "https://example.com/cover.jpg")!
        for size in [
            CGSize(width: 0, height: 48),
            CGSize(width: 48, height: -1),
            CGSize(width: CGFloat.infinity, height: 48),
        ] {
            let request = makeLakeImageRequest(
                url: url,
                contentMode: .fit,
                thumbnailSize: size,
                displayScale: 2
            )
            XCTAssertNil(request.thumbnail)
        }

        let invalidScale = makeLakeImageRequest(
            url: url,
            contentMode: .fit,
            thumbnailSize: CGSize(width: 48, height: 48),
            displayScale: 0
        )
        XCTAssertNil(invalidScale.thumbnail)

        let overflowingPixelSize = makeLakeImageRequest(
            url: url,
            contentMode: .fit,
            thumbnailSize: CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: 48
            ),
            displayScale: 2
        )
        XCTAssertNil(overflowingPixelSize.thumbnail)
    }

    func testFitAndFillThumbnailRequestsHaveDistinctCacheIdentity() {
        let url = URL(string: "https://example.com/cover.jpg")!
        let size = CGSize(width: 80, height: 120)
        let fit = makeLakeImageRequest(
            url: url,
            contentMode: .fit,
            thumbnailSize: size,
            displayScale: 2
        )
        let fill = makeLakeImageRequest(
            url: url,
            contentMode: .fill,
            thumbnailSize: size,
            displayScale: 2
        )

        XCTAssertNotEqual(ImageCacheKey(request: fit), ImageCacheKey(request: fill))
    }

    func testThumbnailRequestConvertsDisplayPointsToExplicitPixels() {
        let url = URL(string: "https://example.com/cover.jpg")!
        let request = makeLakeImageRequest(
            url: url,
            contentMode: .fit,
            thumbnailSize: CGSize(width: 80, height: 120),
            displayScale: 2
        )
        var expected = ImageRequest(url: url)
        expected.thumbnail = ImageRequest.ThumbnailOptions(
            size: CGSize(width: 160, height: 240),
            unit: .pixels,
            contentMode: .aspectFit
        )

        XCTAssertEqual(
            ImageCacheKey(request: request),
            ImageCacheKey(request: expected)
        )
    }

#if canImport(AppKit)
    func testThumbnailRequestDownsamplesDuringDecode() async throws {
        let sourceWidth = 1_200
        let sourceHeight = 600
        let representation = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: sourceWidth,
            pixelsHigh: sourceHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ))
        let data = try XCTUnwrap(representation.representation(using: .png, properties: [:]))
        let url = URL(string: "https://example.com/large-cover.png")!
        let provider = CustomImageProvider { requestedURL in
            requestedURL == url ? data : nil
        }
        let request = makeLakeImageRequest(
            url: url,
            contentMode: .fit,
            thumbnailSize: CGSize(width: 40, height: 40),
            displayScale: 1
        )

        let image = try await provider.imagePipeline.image(for: request)
        let decodedImage = try XCTUnwrap(
            image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        )

        XCTAssertLessThan(decodedImage.width, sourceWidth)
        XCTAssertLessThan(decodedImage.height, sourceHeight)
        XCTAssertEqual(
            Double(decodedImage.width) / Double(decodedImage.height),
            Double(sourceWidth) / Double(sourceHeight),
            accuracy: 0.05
        )
    }
#endif
}
