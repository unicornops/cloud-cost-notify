// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CloudCostNotify",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/awslabs/aws-sdk-swift.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "CloudCostNotify",
            dependencies: [
                .product(name: "AWSCostExplorer", package: "aws-sdk-swift"),
                .product(name: "AWSClientRuntime", package: "aws-sdk-swift"),
                .product(name: "AWSSDKIdentity", package: "aws-sdk-swift")
            ],
            path: "CloudCostNotify"
        )
    ]
)
