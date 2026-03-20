# Testing Patterns

**Analysis Date:** 2026-03-19

## Test Framework

**Runner:**
- Framework: `flutter_test` (part of Flutter SDK)
- Version: Provided by Flutter SDK matching project version
- Config file: `pubspec.yaml` - `flutter_test` under `dev_dependencies`
- Run commands:
  ```bash
  flutter test                    # Run all tests
  flutter test --watch           # Watch mode - re-run on file changes
  flutter test --coverage        # Generate coverage report
  flutter test test/widget_test.dart  # Run specific test file
  ```

**Assertion Library:**
- Built-in: `expect()` function from `flutter_test` package
- Matchers: `findsOneWidget`, `findsNothing`, `findsWidgets`, etc.
- Matcher-based assertions: `expect(find.text('0'), findsOneWidget);`

## Test File Organization

**Location:**
- Tests co-located in dedicated `test/` directory at project root
- Pattern: Separate test directory (not alongside source in `lib/`)

**Naming:**
- Pattern: `[feature]_test.dart` or `[feature]_widget_test.dart`
- Example: `widget_test.dart` - currently a generic widget smoke test

**Structure:**
```
test/
├── widget_test.dart      # Widget tests
└── [future]_test.dart    # Additional test files
```

## Test Structure

**Suite Organization:**

```dart
void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
```

**Patterns:**

- **Setup:** Use `await tester.pumpWidget(widget)` to build widget under test
- **Interaction:** Use `await tester.tap(finder)` to simulate user interactions, `await tester.pump()` to rebuild after interaction
- **Verification:** Use `expect(finder, matcher)` with finders like `find.text()`, `find.byIcon()`, `find.byType()`
- **Async handling:** All test methods are `async` with `await` for pump/interaction commands

## Mocking

**Framework:**
- Not explicitly mocked in current test
- Firebase mocking would use `firebase_core/firebase_core_platform_interface.dart` for platform channels
- Alternative: Use `mockito` package if needed (not currently in dependencies)

**Patterns:**

For widget tests, mock Firebase if needed:
```dart
// Firebase would need to be mocked or stubbed
// Use firebase_core testing utilities or create mock implementations
```

**What to Mock:**
- External services (Firebase, HTTP clients, databases)
- Platform channels that depend on native code
- Heavy computations or I/O operations

**What NOT to Mock:**
- Flutter framework widgets and utilities
- Navigation (use `WidgetTester` for navigation simulation)
- Theme and context objects (part of test scaffold)

## Fixtures and Factories

**Test Data:**
- Currently: No dedicated fixtures
- Smoke test uses hardcoded widget: `const MyApp()`
- Future pattern: Create factory methods or helper functions to build test widgets

**Location:**
- Test utilities would go in `test/` directory
- Could create `test/helpers/` for shared test utilities
- Could create `test/fixtures/` for mock data

## Coverage

**Requirements:**
- Not enforced in current project
- No coverage thresholds set in configuration

**View Coverage:**
```bash
flutter test --coverage              # Generate coverage data
lcov --list coverage/lcov.info       # View coverage report (requires lcov tool)
genhtml coverage/lcov.info -o coverage/html  # Generate HTML coverage report
open coverage/html/index.html        # View in browser
```

**Coverage output:**
- Coverage data written to `coverage/lcov.info`
- Can be integrated with CI/CD tools

## Test Types

**Unit Tests:**
- Scope: Individual Dart functions and classes (not currently in project)
- Approach: Test logic independently without Flutter framework
- Would use: `test()` function from `test` package (not currently added)

**Widget Tests:**
- Scope: Single widget or small widget tree interactions
- Approach: Use `testWidgets()` with `WidgetTester` to test UI rendering and interactions
- Current example: `widget_test.dart` - tests `MyApp` widget rendering
- Pattern: Build widget, find elements, verify state, interact, re-verify

**Integration Tests (E2E):**
- Framework: `integration_test` package (not currently configured)
- Would test: Full app flows across multiple screens
- Would use: `testWidgets()` from `integration_test/integration_test.dart`
- Not currently used in project

## Common Patterns

**Async Testing:**
```dart
testWidgets('Description', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());  // Build widget (returns Future)
  await tester.pump();                      // Trigger rebuild (returns Future)
  // All test operations are awaited
});
```

**Finding Widgets:**
- `find.text('0')` - Find widget by displayed text
- `find.byIcon(Icons.add)` - Find widget by icon type
- `find.byType(TextField)` - Find widget by type
- `find.byKey(Key('myKey'))` - Find widget by Key
- `find.byWidget(widget)` - Find specific widget instance

**Verification with Matchers:**
```dart
expect(find.text('0'), findsOneWidget);     // Exactly one match
expect(find.text('1'), findsNothing);       // No matches
expect(find.byType(Text), findsWidgets);    // One or more matches
```

**Error Testing:**
- Firebase initialization errors caught in `main()` with `async/await`
- Widget errors would be caught with `tester` error handling
- Exception matchers: `expect(() => function(), throwsException)`

## Test Dependencies

**Current dev_dependencies:**
- `flutter_test: sdk: flutter` - Core testing framework
- `flutter_lints: ^6.0.0` - Linting (not testing, but code quality)

**Future dependencies for expanded testing:**
- `mockito: ^5.0.0` - For mocking Firebase and services
- `integration_test: sdk: flutter` - For E2E tests
- `test: ^1.0.0` - For unit tests

## Running Tests

**All Tests:**
```bash
flutter test
```

**Specific Test File:**
```bash
flutter test test/widget_test.dart
```

**Watch Mode (re-run on changes):**
```bash
flutter test --watch
```

**With Coverage:**
```bash
flutter test --coverage
```

**With Verbose Output:**
```bash
flutter test --verbose
```

---

*Testing analysis: 2026-03-19*
