// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LakeImage",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        .library(
            name: "LakeImage",
            targets: ["LakeImage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "LakeImage",
            dependencies: [
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "NukeUI", package: "Nuke"),
            ]),
//        .testTarget(
//            name: "LakeImageTests",
//            dependencies: ["LakeImage"]),
    ]
)
