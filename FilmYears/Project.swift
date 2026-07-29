import ProjectDescription

let project = Project(
    name: "FilmYears",
    targets: [
        .target(
            name: "FilmYears",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.chocklee.filmyears",
            deploymentTargets: .iOS("18.0"),
            infoPlist: "Resources/Info.plist",
            sources: [
                "App/**",
                "Models/**",
                "Services/**",
                "ViewModels/**",
                "Views/**",
                "Preview Content/**"
            ],
            resources: ["Resources/**"],
            capabilities: [
                .incomingNetworkConnections(),
                .outgoingNetworkConnections()
            ]
        ),
        .target(
            name: "FilmYearsWidgets",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "com.chocklee.filmyears.widgets",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "$(PRODUCT_NAME)"
            ]),
            sources: ["Widgets/**"]
        )
    ]
)
