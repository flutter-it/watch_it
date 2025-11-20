# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

**watch_it** is a Flutter state management package built on top of get_it. It provides reactive data binding that automatically rebuilds widgets when observed data changes, eliminating the need for `ValueListenableBuilder`, `StreamBuilder`, and `FutureBuilder` widgets.

**Core philosophy**: Simple, hook-like API (similar to React Hooks/flutter_hooks) that watches registered objects in get_it and rebuilds widgets automatically.

## Development Commands

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/watch_it_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code (REQUIRED before commits)
dart format .

# Dry run publish check
flutter pub publish --dry-run
```

### Example App
```bash
cd example
flutter run

# Run on specific device
flutter run -d chrome
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies (check compatibility first)
flutter pub upgrade
```

## Architecture & Design Principles

### The Global State Pattern

**Critical**: watch_it uses a global variable `_activeWatchItState` (in `elements.dart`) that holds the current widget's watch state during build. This is the "magic" that allows watch functions to work without explicit parameters.

**How it works**:
1. When a widget with `WatchItMixin` or `WatchingWidget` builds, its `Element` sets `_activeWatchItState` to its local `_WatchItState` instance
2. All `watch*()` function calls access `_activeWatchItState` to register watches
3. After build completes, `_activeWatchItState` is reset to null
4. Similar pattern to `flutter_hooks` and React Hooks

**Code location**: `lib/src/elements.dart:3-32` - `_WatchItElement` mixin

### Watch Entry List & Ordering

**CRITICAL RULE**: All `watch*()` and `registerHandler*()` calls MUST:
- Be called inside `build()` method
- Be called in the SAME ORDER on every build
- Not be conditional (no `if` statements wrapping watch calls)
- Not be inside builders/callbacks

**Why**: Each watch call corresponds to a position in `_watchList` (see `watch_it_state.dart:78`). On rebuild, the counter resets and each watch call retrieves its previous `_WatchEntry` by index. Changing order breaks this mapping.

**Implementation**: `lib/src/watch_it_state.dart:138-175`
- `resetCurrentWatch()` - Resets counter to 0 at start of build
- `_getWatch()` - Retrieves watch entry by current index, increments counter
- `_appendWatch()` - Adds new watch entry when first encountered

### Widget Integration

Three ways to use watch_it:

1. **WatchingWidget** (extends StatelessWidget) - `lib/src/widgets.dart`
2. **WatchingStatefulWidget** (extends StatefulWidget) - `lib/src/widgets.dart`
3. **Mixins**: `WatchItMixin` or `WatchItStatefulWidgetMixin` - `lib/src/mixins.dart`

All create custom `Element` subclasses (`_StatelessWatchItElement` or `_StatefulWatchItElement`) that:
- Initialize `_WatchItState` on mount
- Set/unset `_activeWatchItState` around build
- Dispose watch entries on unmount

### Data Types & Watch Functions

**Hierarchy**:
```
Listenable (base)
├─ ChangeNotifier
└─ ValueListenable<T>
   └─ ValueNotifier<T>
```

**Watch function mapping**:
- `watch()` - Any `Listenable` (ChangeNotifier, ValueNotifier, etc.)
- `watchIt()` - `Listenable` from get_it
- `watchValue()` - `ValueListenable` property from get_it object
- `watchPropertyValue()` - Property of `Listenable`, rebuilds only when property value changes
- `watchStream()` - `Stream<T>`, returns `AsyncSnapshot<T>`
- `watchFuture()` - `Future<T>`, returns `AsyncSnapshot<T>`

**Implementation**: All in `lib/src/watch_it.dart`

### Handler Pattern (Side Effects)

Handlers execute side effects (show dialogs, navigation, etc.) instead of rebuilding:
- `registerHandler()` - For `ValueListenable` changes
- `registerChangeNotifierHandler()` - For `ChangeNotifier` changes
- `registerStreamHandler()` - For `Stream` events
- `registerFutureHandler()` - For `Future` completion

**Key difference**: Handlers receive a `cancel()` function to unsubscribe from inside the handler.

### Lifecycle Helpers

- `createOnce()` - Create objects on first build, auto-dispose on widget destroy
- `createOnceAsync()` - Async version, returns `AsyncSnapshot<T>`
- `callOnce()` - Execute function once on first build
- `onDispose()` - Register dispose callback
- `pushScope()` - Push get_it scope tied to widget lifecycle

**Use case**: Creating `TextEditingController`, `AnimationController`, etc. in stateless widgets

### Tracing & Debugging

Two-level tracing system:

1. **Widget-level**: Call `enableTracing()` at start of build
2. **Subtree-level**: Wrap with `WatchItSubTreeTraceControl` widget

**Performance consideration**: Subtree tracing only active if `enableSubTreeTracing = true` globally (checked in `_checkSubTreeTracing()`)

**Custom logging**: Override `watchItLogFunction` to integrate with analytics/monitoring

**Events tracked**: `WatchItEvent` enum in `watch_it_tracing.dart` - rebuild, handler, createOnce, scopePush, etc.

## Common Patterns

### Basic Watch Pattern
```dart
class MyWidget extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    // Always at top of build, same order every time
    final user = watchIt<UserModel>();
    final count = watchValue((CounterModel m) => m.count);
    final name = watchPropertyValue((UserModel m) => m.name);

    return Text('$name: $count');
  }
}
```

### Handler Pattern (Side Effects)
```dart
class MyWidget extends StatelessWidget with WatchItMixin {
  @override
  Widget build(BuildContext context) {
    registerHandler(
      select: (ErrorModel m) => m.lastError,
      handler: (context, error, cancel) {
        if (error != null) {
          showDialog(context: context, builder: (_) => ErrorDialog(error));
          cancel(); // Stop listening after first error
        }
      },
    );

    return Container();
  }
}
```

### Async Initialization
```dart
class MyWidget extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final ready = allReady(
      onReady: (context) => Navigator.pushReplacement(...),
      timeout: Duration(seconds: 5),
    );

    if (!ready) return CircularProgressIndicator();
    return MainContent();
  }
}
```

## Testing

### Key Test Patterns

1. **Setup**: Always call `GetIt.I.reset()` in `tearDown`
2. **Pump widgets**: Use `pumpWidget()` to trigger builds
3. **Verify rebuilds**: Track state changes, verify widget updates
4. **Test ordering**: Verify watch calls maintain order across rebuilds

**Test file**: `test/watch_it_test.dart`

### Testing Watch Functions

```dart
testWidgets('watch rebuilds on notify', (tester) async {
  final model = TestModel();
  GetIt.I.registerSingleton(model);

  await tester.pumpWidget(
    MaterialApp(home: TestWidget()),
  );

  expect(find.text('0'), findsOneWidget);

  model.increment(); // Triggers notifyListeners()
  await tester.pump();

  expect(find.text('1'), findsOneWidget);
});
```

## Critical Rules for Modifications

### When Adding New Watch Functions

1. **Access global state**: Use `_activeWatchItState` (assert it's not null)
2. **Delegate to _WatchItState**: Don't implement watch logic in global functions
3. **Maintain order invariant**: Document that function must be called in same order
4. **Support both get_it and local**: Provide `target` parameter for local observables when possible

### When Modifying _WatchItState

1. **Index management**: Carefully handle `currentWatchIndex` in `_getWatch()` and `resetCurrentWatch()`
2. **Dispose properly**: Every `_WatchEntry` must clean up listeners/subscriptions in its dispose function
3. **Null safety**: Check `_element != null` before calling handlers (can be called after dispose)
4. **Tracing**: Add appropriate trace points for new functions

### When Adding Helper Functions

1. **Follow lifecycle pattern**: Use `_getWatch()` / `_appendWatch()` pattern
2. **Provide eventType**: Add new `WatchItEvent` enum value if needed
3. **Document ordering requirement**: Make clear in docs/asserts if order matters

## Dependencies

- **get_it**: ^8.0.0 - Service locator (foundation)
- **functional_listener**: ^4.0.0 - Advanced listenable utilities
- **flutter**: SDK

**Compatibility**: Flutter >=3.0.0, Dart >=2.19.6 <4.0.0

## Common Issues & Solutions

### "watch can only be called inside a build function"
- Widget must extend `WatchingWidget` / `WatchingStatefulWidget` OR use `WatchItMixin`
- Watch calls must be directly in build method, not in callbacks

### "This Object is already watched by watch_it"
- Can't call `watch()` or `watchIt()` twice on same object
- Use `watchPropertyValue()` for multiple properties of same object
- Handlers are exempt (can register multiple handlers on same object)

### Infinite rebuild loops
- `watchFuture` / `watchStream` selector returns NEW Future/Stream each build
- Solution: Return the SAME Future/Stream instance (store in object)

### Order violations
- Conditional watch calls change order between builds
- Solution: Move watch calls to top of build, use conditional rendering AFTER

## File Structure

```
lib/
├── watch_it.dart              # Main export, global di/sl instances
├── src/
    ├── elements.dart          # Element mixins, global _activeWatchItState
    ├── mixins.dart            # WatchItMixin, WatchItStatefulWidgetMixin
    ├── watch_it_state.dart    # Core _WatchItState class, _WatchEntry
    ├── watch_it.dart          # All watch*() and register*() global functions
    ├── watch_it_tracing.dart  # Tracing infrastructure, WatchItEvent enum
    └── widgets.dart           # WatchingWidget, WatchingStatefulWidget
```

## Publishing Checklist

1. Update `CHANGELOG.md` with version and changes
2. Update version in `pubspec.yaml`
3. Run `dart format .`
4. Run `flutter analyze` (must pass)
5. Run `flutter test` (must pass)
6. Run `flutter pub publish --dry-run`
7. Commit changes
8. Create git tag: `git tag vX.Y.Z`
9. Push with tags: `git push --tags`
10. Run `flutter pub publish`

## Links

- Documentation site: https://flutter-it.dev
- GitHub: https://github.com/escamoteur/watch_it
- Discord: https://discord.gg/ZHYHYCM38h
- get_it package: https://pub.dev/packages/get_it
- don't stop to announce something if you haven't finished