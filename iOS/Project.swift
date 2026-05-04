import ProjectDescription

let project = Project(
    name: "DoorbellPanel",
    targets: [
        .target(
            name: "DoorbellPanel",
            destinations: .iOS,
            product: .app,
            bundleId: "com.ezefranca.doorbellpanel",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "Doorbell Panel",
                    "UILaunchScreen": [:],
                    "NSCameraUsageDescription": "This app uses the camera for the live doorbell preview.",
                    "NSLocalNetworkUsageDescription": "This app sends ring events to Homebridge on your local network.",
                    "NSAppTransportSecurity": [
                        "NSAllowsLocalNetworking": true,
                    ],
                ]
            ),
            sources: ["DoorbellPanel/Sources/**"]
        ),
    ]
)

