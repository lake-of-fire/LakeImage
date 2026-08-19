// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LakeImage",
    platforms: [.macOS("15.0"), .iOS(.v15)],
    products: [
        .library(
            name: "LakeImage",
            targets: ["LakeImage"]),
    ],
    dependencies: [
        // Keep the custom DataLoading adapter on the Nuke API used by the app's
        // generated dependency graph. Nuke's moving main branch has already
        // changed this protocol incompatibly.
        .package(
            url: "https://github.com/kean/Nuke.git",
            revision: "4a3dd00de49cb2536ee46cd648137ea3197684df"
        ),
    ],
    targets: [
        .target(
            name: "LakeImage",
            dependencies: [
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "NukeUI", package: "Nuke"),
            ]),
        .testTarget(
            name: "LakeImageTests",
            dependencies: [
                "LakeImage",
                .product(name: "Nuke", package: "Nuke"),
            ]),
    ]
)
