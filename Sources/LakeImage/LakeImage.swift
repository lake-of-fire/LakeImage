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

fileprivate final class LoadTask: Nuke.Cancellable {
    func cancel() {}
}

class CustomDataLoader: DataLoading {
    private let defaultDataLoader: DataLoading = DataLoader()
    private let interceptor: ((URL) throws -> Data?)?
    
    init(interceptor: ((URL) throws -> Data?)? = nil) {
        self.interceptor = interceptor
    }
    
    func loadData(
        with request: URLRequest,
        didReceiveData: @escaping (Data, URLResponse) -> Void,
        completion: @escaping (Error?) -> Void
    ) -> any Nuke.Cancellable {
        let task = LoadTask()
        
        guard let url = request.url else {
            completion(NSError(domain: "CustomDataLoader", code: 0, userInfo: nil))
            return task
        }
        
        do {
            if let data = try interceptor?(url) {
                if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) {
                    didReceiveData(data, response)
                    completion(nil)
                } else {
                    completion(NSError(domain: "CustomDataLoader", code: 0, userInfo: nil))
                }
                return task
            }
        } catch {
            debugPrint("Error loading image URL:", url, error)
        }
        
        return defaultDataLoader.loadData(
            with: request,
            didReceiveData: didReceiveData,
            completion: completion
        )
    }
}

public class CustomImageProvider {
    let imagePipeline: ImagePipeline
    
    public init(interceptor: ((URL) throws -> Data?)? = nil) {
        var config = ImagePipeline.Configuration.withDataCache
        config.dataLoader = CustomDataLoader(interceptor: interceptor)
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
        imageProvider: ((URL) throws -> Data?)? = nil
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
