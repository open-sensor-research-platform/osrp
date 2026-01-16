// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OSRP",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "OSRP",
            targets: ["OSRP"]
        ),
    ],
    dependencies: [
        // AWS SDK for Swift
        .package(
            url: "https://github.com/awslabs/aws-sdk-swift.git",
            from: "0.30.0"
        ),
    ],
    targets: [
        .target(
            name: "OSRP",
            dependencies: [
                .product(name: "AWSCognitoIdentityProvider", package: "aws-sdk-swift"),
                .product(name: "AWSS3", package: "aws-sdk-swift"),
            ]
        ),
        .testTarget(
            name: "OSRPTests",
            dependencies: ["OSRP"]
        ),
    ]
)
