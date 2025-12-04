## 2.4.0

### Improvements
* `allReady()` now properly detects when new async singletons are registered in pushed scopes
  * Previously, `allReady()` would not rebuild the UI when `pushNewScope()` registered new async singletons
  * Now works correctly with get_it 9.2.0's cached `allReady()` future
* Requires get_it ^9.2.0

## 2.3.1

### Maintenance
* Updated example project

## 2.3.0

### Documentation
* Restructured README with clearer benefits, improved examples, and links to official flutter-it.dev website
* Fixed documentation anchor links

## 2.2.0

### Improvements
* **Renamed for clarity**: `callAfterFirstBuild()` → `callOnceAfterThisBuild()`. The new name better reflects the actual behavior: it executes once after the first build where the function is called, not necessarily after the widget's first build. This makes it clear that it can be safely used inside conditionals. Since this function was only introduced in version 2.0.0, migration should be straightforward - just update the function name in your code.
* Enhanced documentation for `callOnceAfterThisBuild()` with better explanation of behavior and added example showing usage in conditionals for navigation when async dependencies are ready.

## 2.1.1

### Maintenance
* Updated example to use command_it 9.0.2 API (`execute` → `run`, `isExecuting` → `isRunning`)

## 2.1.0

### Improvements
* **Better Error Messages**: Watch ordering violations now show a helpful error message instead of cryptic type errors. When conditional watch calls are placed incorrectly, you'll see clear guidance on how to fix it with BAD/GOOD examples.
* **Enhanced Documentation**: Added "Watch Ordering and Conditional Watches" section to README with visual examples explaining why conditional watches must be at the end of build methods.
* **Improved Test Coverage**: Test coverage increased to 93.3%.

## 2.0.1

### Maintenance
* Updated get_it dependency to ^9.0.0
* Added GitHub Actions workflow for CI/CD with automated testing and code coverage
* Improved README header with logo and better formatting to match flutter_it ecosystem style
* Added package logo to pub.dev screenshots

## 2.0.0 - Performance optimizations and post-frame callbacks

### Breaking Changes
* **BREAKING**: Replaced dependency `functional_listener ^4.0.0` with `listen_it ^5.1.0`. This is a breaking change as `functional_listener` has been renamed and restructured into `listen_it`. If you use `functional_listener` operators in your code, update your imports from `package:functional_listener/functional_listener.dart` to `package:listen_it/listen_it.dart`.
* **BREAKING**: `watchValue()` and `registerHandler()` now default to `allowObservableChange: false` for better performance and memory leak prevention. This means the selector function is only called once on first build. If you need to dynamically switch observables (e.g., `condition ? obsA : obsB`), set `allowObservableChange: true`. This prevents common memory leaks from inline chain creation like `watchValue((m) => m.source.map(...))`.

### New Features
* Added `callAfterFirstBuild()` function that executes a callback once after the first frame has been rendered. This is useful for operations that require the widget tree to be fully built and laid out, such as showing dialogs, accessing widget dimensions, scrolling to positions, or starting animations that depend on final widget sizes. This replaces the common pattern of using `WidgetsBinding.instance.addPostFrameCallback` in `initState()`.
* Added `callAfterEveryBuild()` function that executes a callback after every frame has been rendered. This is useful for operations that need to run after each rebuild, such as updating scroll positions, repositioning overlays, or performing measurements. The callback includes a `cancel()` function to stop future invocations when needed.

### Performance Improvements
* `watchValue()` and `registerHandler()` now have zero overhead on rebuilds with default settings - selectors are only called once instead of on every build
* Added helpful `StateError` messages when observables change unexpectedly with `allowObservableChange: false`, guiding users to the correct fix

### Bug Fixes
* Fixed `createOnceAsync` test isolation issue by properly resetting `testCompleter` in `setUp`
* Internal refactoring: Renamed parameters for better clarity (`target` → `parentOrListenable`, etc.)

## 1.7.0 - adding powerful tracing and logging so you can understand why and when your UI rebuilds
## 1.6.5 - 11.03.2025
* PR by @timmaffett imrproving the markdown of the readme
* adding topics to pubspec
## 1.6.4 - 25.02.2025
* adding `sl` alias for `di`
* adding createOnce to the readme
## 1.6.3 - 22.02.2025
* fixing an exception in Streambuilder during loading state if you don't provide an inital value
## 1.6.2 - 09.01.2025
* Fix for https://github.com/escamoteur/watch_it/issues/42
## 1.6.1 - 13.12.2024

* fixing linter warnings 

## 1.6.0 - 12.12.2024

* Adding `createOnce` and `createOnceAsync`

## 1.5.1 - updated to latest version of functional_listener
## 1.5.0 - updated to latest versions of get_it and flutter_command
## 1.4.2 - 14.05.2024 fix for https://github.com/escamoteur/watch_it/issues/29
## 1.4.1 - 23.03.2024
* fix for https://github.com/escamoteur/watch_it/issues/28
## 1.4.0 - 23.01.2024
* thanks to the pr https://github.com/escamoteur/watch_it/pull/27 by @jefflongo `pushScope` now accepts the `isFinal` parameter that the underlying get_it function does for some time now.
## 1.3.0 - 18.01.2024
* added `executeHandlerOnlyOnce` to `registerFutureHandler`, `allReady` and `allReadyHandler`
* added new functions: `callOnce` and `onDispose`. See readme for details
## 1.2.0 - 27.12.2023
* thanks to the PR from @smjxpro https://github.com/escamoteur/watch_it/pull/22 you now can register handlers for pure Listenable/ChangeNotifiers too
## 1.1.0 - 08.11.2023
* https://github.com/fluttercommunity/get_it/issues/345 `allReady()` will now throw a correct error if an exception is thrown in one of the factory functions that `allReady()` checks
## 1.0.6 - 31.10.2023 
* Typo fixes by PRs from @mym0404 @elitree @florentmx 
## 1.0.5 

* updates Discord invite link
## 1.0.4
* added some more asserts to provide better error messages in case you forgot to use the WatchItMixin
## 1.0.3
* bumped get_it version
## 1.0.2
* thanks for PR by @yangsfang https://github.com/escamoteur/watch_it/pull/10
## 1.0.1 
* small change in documentation
## 1.0.0
* fix for https://github.com/escamoteur/watch_it/issues/8
* improved comments thanks to PR by @kevlar700 
## 0.9.3
* added safety checks in case _element gets null but still a handler might get called
## 0.9.2
* improving readme
## 0.9.1
 * fix typo
## 0.9.0
* First beta release
## 0.0.1

* This is currently just a placeholder for the new version of the get_it_mixin
