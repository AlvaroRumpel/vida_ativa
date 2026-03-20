# Codebase Structure

**Analysis Date:** 2026-03-19

## Directory Layout

```
vida_ativa/
├── .dart_tool/              # Dart tooling cache (generated)
├── .idea/                   # IDE configuration
├── .planning/               # GSD documentation (generated)
│   └── codebase/
├── lib/                     # Dart/Flutter source code
│   ├── main.dart            # Application entry point and root widget
│   └── firebase_options.dart # Platform-specific Firebase configuration
├── test/                    # Widget and unit tests
│   └── widget_test.dart     # Basic smoke test template
├── web/                     # Web platform assets and configuration
│   ├── index.html           # HTML entry point for web
│   ├── manifest.json        # Web app manifest
│   ├── favicon.png          # Web favicon
│   └── icons/               # PWA/web app icons
├── pubspec.yaml             # Dart package manifest and dependencies
├── pubspec.lock             # Locked dependency versions
├── analysis_options.yaml    # Dart linter configuration
├── firebase.json            # FlutterFire configuration metadata
├── .gitignore               # Git ignore patterns
├── .metadata                # Flutter project metadata
├── README.md                # Project documentation stub
└── vida_ativa.iml           # IntelliJ IDEA project file
```

## Directory Purposes

**lib:**
- Purpose: All production Dart/Flutter code
- Contains: Widgets, services, models, utilities
- Key files: `main.dart` (root widget), `firebase_options.dart` (configuration)

**test:**
- Purpose: Automated tests for widgets and business logic
- Contains: Widget tests, integration tests, test utilities
- Key files: `widget_test.dart` (smoke test template)

**web:**
- Purpose: Web platform static assets and configuration
- Contains: HTML entry point, service worker manifest, PWA icons
- Key files: `index.html` (web app bootstrap), `manifest.json` (PWA metadata)

**.planning/codebase:**
- Purpose: GSD documentation and architecture analysis
- Contains: ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md (generated)
- Committed: Yes

**.dart_tool:**
- Purpose: Dart/Flutter tooling cache and build artifacts
- Generated: Yes
- Committed: No (.gitignore entry)

**.idea:**
- Purpose: IntelliJ IDEA and Android Studio IDE settings
- Generated: Yes
- Committed: No

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Application root with main() function and MyApp widget (lines 1-26)
- `web/index.html`: Web platform HTML bootstrap

**Configuration:**
- `pubspec.yaml`: Package name, version, dependencies, Material Design assets
- `analysis_options.yaml`: Dart linter rules (inherits package:flutter_lints)
- `firebase.json`: FlutterFire CLI metadata and Firebase project mapping

**Core Logic:**
- `lib/main.dart`: All current application logic (minimal - placeholder UI)
- `lib/firebase_options.dart`: Firebase platform initialization logic

**Testing:**
- `test/widget_test.dart`: Widget test template (currently contains outdated counter test)

## Naming Conventions

**Files:**
- Pattern: `snake_case.dart`
- Examples: `main.dart`, `firebase_options.dart`, `widget_test.dart`

**Directories:**
- Pattern: `lowercase` (single word)
- Examples: `lib`, `test`, `web`

**Classes/Widgets:**
- Pattern: `PascalCase`
- Examples: `MyApp`, `DefaultFirebaseOptions`, `MaterialApp`

**Functions:**
- Pattern: `camelCase`
- Examples: `main()`, `currentPlatform` (getter)

**Variables:**
- Pattern: `camelCase`
- Examples: `kIsWeb`, `defaultTargetPlatform`

## Where to Add New Code

**New Feature UI Screen:**
- Primary code: `lib/screens/[feature_name]/[feature_name]_screen.dart` (create screens directory)
- Tests: `test/screens/[feature_name]/[feature_name]_screen_test.dart`
- Pattern: StatefulWidget or Consumer widget (when state management added)

**New Service/Repository:**
- Implementation: `lib/services/[service_name]_service.dart` (create services directory)
- Firebase integration: Extend firebase_options.dart or create `lib/services/firebase_service.dart`
- Tests: `test/services/[service_name]_service_test.dart`

**Shared Widgets (Reusable UI Components):**
- Location: `lib/widgets/[component_name].dart` (create widgets directory)
- Tests: `test/widgets/[component_name]_test.dart`

**Data Models/Domain Logic:**
- Location: `lib/models/[entity_name].dart` (create models directory)
- Include: Data classes, serialization (toJson/fromJson), Firebase document mapping
- Tests: `test/models/[entity_name]_test.dart`

**Utilities and Helpers:**
- Location: `lib/utils/[utility_name].dart` (create utils directory)
- Constants: `lib/constants/[category]_constants.dart`

**State Management (when added):**
- Providers: `lib/providers/[domain]_provider.dart` (if using Provider)
- Bloc: `lib/bloc/[feature]/[feature]_bloc.dart` (if using Bloc)
- Services: `lib/services/` (singleton services)

## Special Directories

**.dart_tool:**
- Purpose: Build artifacts and tooling cache
- Generated: Yes (automatically by `flutter pub get`)
- Committed: No (.gitignore entry)

**node_modules/.dart_tool/dartpad:**
- Purpose: DartPad integration cache
- Generated: Yes
- Committed: No

**Platform-Specific Directories (Not Yet Present):**
- `android/`: Android app configuration, gradle build, native code (not generated)
- `ios/`: iOS app configuration, CocoaPods, native code (not generated)
- `windows/`: Windows desktop app configuration (not generated)
- `macos/`: macOS desktop app configuration (not generated)
- `linux/`: Linux desktop app configuration (not generated)

When creating platform-specific builds, run `flutter create --platforms=android,ios,web` to scaffold platform directories.

---

*Structure analysis: 2026-03-19*
