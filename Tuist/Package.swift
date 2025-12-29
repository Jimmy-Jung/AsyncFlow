// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "AsyncViewModel": .framework,
        ]
    )
#endif

let package = Package(
    name: "Dependencies",
    dependencies: [
        // AsyncViewModel
        .package(url: "https://github.com/Jimmy-Jung/AsyncViewModel", from: "1.2.0"),
    ]
)
