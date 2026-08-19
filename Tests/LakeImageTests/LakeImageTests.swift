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
            thumbnailSize: nil
        )
        let small = makeLakeImageRequest(
            url: url,
            contentMode: .fill,
            thumbnailSize: CGSize(width: 48, height: 48)
        )
        let large = makeLakeImageRequest(
            url: url,
            contentMode: .fill,
            thumbnailSize: CGSize(width: 144, height: 144)
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
                thumbnailSize: size
            )
            XCTAssertNil(request.thumbnail)
        }
    }

    func testFitAndFillThumbnailRequestsHaveDistinctCacheIdentity() {
        let url = URL(string: "https://example.com/cover.jpg")!
        let size = CGSize(width: 80, height: 120)
        let fit = makeLakeImageRequest(url: url, contentMode: .fit, thumbnailSize: size)
        let fill = makeLakeImageRequest(url: url, contentMode: .fill, thumbnailSize: size)

        XCTAssertNotEqual(ImageCacheKey(request: fit), ImageCacheKey(request: fill))
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
            thumbnailSize: CGSize(width: 40, height: 40)
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
