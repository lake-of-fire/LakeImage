import SwiftUI
//import WebURL
//import WebURLFoundationExtras
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
    let contentMode: ContentMode
    var maxWidth: CGFloat? = nil
    var minHeight: CGFloat? = nil
    var maxHeight: CGFloat? = nil
    var cornerRadius: CGFloat? = nil
    
    @State private static var imagePipeline = ImagePipeline(configuration: .withDataCache)
    
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
        .pipeline(Self.imagePipeline)
        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
    }
    
    public init(_ url: URL, contentMode: ContentMode = .fill, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, maxHeight: CGFloat? = nil, cornerRadius: CGFloat? = nil) {
        self.url = url
        self.contentMode = contentMode
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.cornerRadius = cornerRadius
    }
}
