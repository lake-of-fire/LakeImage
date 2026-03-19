import SwiftUI
//import WebURL
//import WebURLFoundationExtras
import Nuke
import NukeUI
//import Combine

//private class RedirectHandler: ImageDownloadRedirectHandler {
//    func handleHTTPRedirection(for task: SessionDataTask, response: HTTPURLResponse, newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
//        var modified = newRequest
//        //    modified.allHTTPHeaderFields = authorizationHeaders
//        completionHandler(modified)
//    }
//}

//private let requestModifier = AnyModifier { request in
//    var r = request
//    if let url = r.url, let webURL = WebURL(url) {
//        r.url = URL(webURL) // Standardize safely.
//    }
//    return r
//}

final class CustomDataLoader: DataLoading, @unchecked Sendable {
    private let defaultDataLoader: any DataLoading = DataLoader()
    private let interceptor: (@Sendable (URL) throws -> Data?)?
    
    init(interceptor: (@Sendable (URL) throws -> Data?)? = nil) {
        self.interceptor = interceptor
    }
    
    func loadData(with request: URLRequest) async throws -> (AsyncThrowingStream<Data, Error>, URLResponse) {
        guard let url = request.url else {
            throw NSError(domain: "CustomDataLoader", code: 0, userInfo: nil)
        }
        
        do {
            if let data = try interceptor?(url) {
                if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) {
                    let stream = AsyncThrowingStream<Data, Error> { continuation in
                        continuation.yield(data)
                        continuation.finish()
                    }
                    return (stream, response)
                } else {
                    throw NSError(domain: "CustomDataLoader", code: 0, userInfo: nil)
                }
            }
        } catch {
            debugPrint("Error loading image URL:", url, error)
        }
        
        return try await defaultDataLoader.loadData(with: request)
    }
}

public class CustomImageProvider {
    let imagePipeline: ImagePipeline
    
    public init(interceptor: (@Sendable (URL) throws -> Data?)? = nil) {
        let cachedConfig = ImagePipeline.Configuration.withDataCache
        var config = ImagePipeline.Configuration(dataLoader: CustomDataLoader(interceptor: interceptor))
        config.dataCache = cachedConfig.dataCache
        config.imageCache = cachedConfig.imageCache
        imagePipeline = ImagePipeline(configuration: config)
    }
    
    static let defaultProvider = CustomImageProvider()
}

public struct LakeImage: View {
    let url: URL
    let contentMode: ContentMode
    let maxWidth: CGFloat?
    let minHeight: CGFloat?
    let maxHeight: CGFloat?
    let cornerRadius: CGFloat?
    let imageProvider: CustomImageProvider
    
    public var body: some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight, alignment: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? 0))
            } else {
                if state.error != nil {
                    Color.clear
                    //                Color.gray // Indicates an error
                } else {
                    Color.gray
                        .opacity(0.7)
                        .frame(minHeight: minHeight)
                    //                    .brightness(0.1)
                }
            }
        }
        .priority(.high)
        .pipeline(imageProvider.imagePipeline)
        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
    }
    
    public init(
        _ url: URL,
        contentMode: ContentMode = .fill,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        imageProvider: (@Sendable (URL) throws -> Data?)? = nil
    ) {
        self.url = url
        self.contentMode = contentMode
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.cornerRadius = cornerRadius
        if let imageProvider {
            self.imageProvider = CustomImageProvider(interceptor: imageProvider)
        } else {
            self.imageProvider = CustomImageProvider.defaultProvider
        }
    }
}
