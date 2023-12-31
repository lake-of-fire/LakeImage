import SwiftUI
import WebURL
import WebURLFoundationExtras
import Nuke
import NukeUI

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

public struct LakeImage: View {
    let url: URL
    var maxWidth: CGFloat? = nil
    var minHeight: CGFloat? = nil
    var maxHeight: CGFloat? = nil
    
    private var cleanURL: URL {
        if let webURL = WebURL(url), let url = URL(webURL) {
            return url
        }
        return url
    }
    
    private let imagePipeline = ImagePipeline(configuration: .withDataCache)
    
    public var body: some View {
        LazyImage(url: cleanURL) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight)
            } else if state.error != nil {
                Color.clear
                //                Color.gray // Indicates an error
                //                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Color.gray
                    .opacity(0.7)
                    .frame(minHeight: minHeight)
                //                    .brightness(0.1)
            }
        }
        .priority(.high)
        .pipeline(imagePipeline)
        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
    }
    
    public init(_ url: URL, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, maxHeight: CGFloat? = nil) {
        self.url = url
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
}
