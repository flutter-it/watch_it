# watch_it Expert - Reactive Widget State Management

**What**: Reactive widgets that auto-rebuild when ValueListenables/Listenables, Streams, or Futures change. Built on get_it. Provides `di` global alias for `GetIt.I`.

## CRITICAL RULES

- **ORDERING**: All `watch*()`, `registerHandler*()`, `createOnce()`, `callOnce()` calls MUST execute in the same order on every build (like React Hooks)
- **Widget type**: Must extend `WatchingWidget` / `WatchingStatefulWidget` or use `WatchItMixin` / `WatchItStatefulWidgetMixin`
- **Never in callbacks**: Don't call watch functions inside builders, callbacks, or event handlers
- `watchValue` selector MUST return a `ValueListenable<R>`, not a bare value
- `createOnce` works in BOTH stateless and stateful widgets

## Widget Types

```dart
// Stateless (most common)
class MyWidget extends WatchingWidget {
  @override
  Widget build(BuildContext context) { ... }
}

// Stateful
class MyWidget extends WatchingStatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

// Mixin on existing widget
class MyWidget extends StatelessWidget with WatchItMixin { ... }
class MyWidget extends StatefulWidget with WatchItStatefulWidgetMixin { ... }
```

## Watch Functions

```dart
// watch() - Watch any Listenable you have a reference to (ChangeNotifier, ValueNotifier, etc.)
final manager = watch(myChangeNotifier);            // rebuilds on notifyListeners()
final value = watch(someValueNotifier).value;       // for ValueNotifiers, access .value

// watchIt() - Watch a Listenable registered in get_it
final manager = watchIt<UserManager>();            // rebuilds on any notification
final config = watchIt<Config>(instanceName: 'dev');

// watchValue() - Watch a ValueListenable PROPERTY from a get_it object
// IMPORTANT: The selector MUST return a ValueListenable, not a bare value
final userState = watchValue((UserManager x) => x.userState);    // x.userState is ValueNotifier<UserState>
final isRunning = watchValue((MyManager x) => x.loadCommand.isRunning);  // isRunning is ValueListenable<bool>

// watchPropertyValue() - Watch a non-ValueListenable property from a Listenable
// Rebuilds only when the selected value changes (equality check)
final name = watchPropertyValue((UserManager x) => x.userName);  // userName is a plain String on a ChangeNotifier
// Also supports local target:
final name = watchPropertyValue((MyNotifier x) => x.name, target: myLocalNotifier);

// watchStream() - Replace StreamBuilder
final snapshot = watchStream(
  (EventBus x) => x.onEvent<LoginEvent>(),
  initialValue: null,
);

// watchFuture() - Replace FutureBuilder
final snapshot = watchFuture(
  (ApiClient x) => x.fetchConfig(),
  initialValue: defaultConfig,  // REQUIRED
);
```

## The Ordering Rule

```dart
// ❌ WRONG - Conditional watch changes order
final showDetails = watchValue((Settings x) => x.showDetails);
if (showDetails) {
  final details = watchValue((Data x) => x.details);  // ORDER CHANGES!
}
final count = watchValue((Counter x) => x.count);

// ✅ CORRECT - Always call all watches, use values conditionally
final showDetails = watchValue((Settings x) => x.showDetails);
final details = watchValue((Data x) => x.details);    // Always called
final count = watchValue((Counter x) => x.count);
if (!showDetails) return Text('Count: $count');
return Text('$count - $details');

// ✅ SAFE - Early return (creates separate code path)
final user = watchValue((Auth x) => x.currentUser);
if (user == null) return LoginScreen();  // Early return ok
final name = watchValue((UserData x) => x.name);  // Safe: always after early return
return Text(name);

// ✅ SAFE - Conditional watch as the LAST watch call (no watches follow it)
final showDetails = watchValue((Settings x) => x.showDetails);
final count = watchValue((Counter x) => x.count);
if (showDetails) {
  final details = watchValue((Data x) => x.details);  // Ok: last watch
}
```

## Lifecycle Functions

```dart
// callOnce - Run once on first build (replaces initState logic)
callOnce((context) {
  di<MarketplaceManager>().loadCommand.run();
});

// callOnceAfterThisBuild - Execute after first build completes (safe for navigation)
callOnceAfterThisBuild((context) {
  Navigator.push(context, ...);
});

// callAfterEveryBuild - Execute after every build, with cancel option
callAfterEveryBuild((context, cancel) {
  scrollController.jumpTo(0);
  if (shouldStop) cancel();
});

// createOnce - Create object once, auto-dispose (works in BOTH stateless and stateful)
// Automatically calls dispose() if the object has a dispose method - no callback needed
final controller = createOnce(() => TextEditingController());
final selectedValue = createOnce(() => ValueNotifier<String?>(null));
// Only pass dispose: if you need custom cleanup beyond the object's own dispose()
final dataSource = createOnce(
  () => MyDataSource(),
  dispose: (ds) => ds.customCleanup(),
);

// createOnceAsync - Async creation
final snapshot = createOnceAsync(
  () => loadExpensiveData(),
  initialValue: null,  // REQUIRED
  dispose: (data) => data?.close(),
);

// onDispose - Register cleanup callback
onDispose(() => someSubscription.cancel());
```

## Handlers (Side Effects Without Rebuild)

```dart
// registerHandler - React to ValueListenable changes
registerHandler(
  select: (MarketplaceManager m) => m.submitCommand.errors,
  handler: (context, error, cancel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.error}')),
    );
  },
  executeImmediately: false, // true = call handler with current value now
);

// registerHandler with local target (no get_it needed)
registerHandler(
  target: myLocalNotifier,
  select: (MyNotifier x) => x.someProperty,
  handler: (context, value, cancel) { ... },
);

// registerChangeNotifierHandler - For ChangeNotifier objects (no select, gets the whole object)
registerChangeNotifierHandler<UserManager>(
  handler: (context, manager, cancel) {
    if (manager.isLoggedOut) Navigator.pushReplacementNamed(context, '/login');
  },
);

// registerStreamHandler - For Stream events
registerStreamHandler<EventBus, ComposerEvent>(
  select: (EventBus bus) => bus.on<ComposerEvent>(),
  handler: (context, snapshot, cancel) {
    if (snapshot.hasData) handleEvent(snapshot.data!);
  },
);

// registerFutureHandler - For Future completion
registerFutureHandler<ApiClient, Config>(
  select: (ApiClient api) => api.fetchConfig(),
  handler: (context, snapshot, cancel) {
    if (snapshot.hasData) applyConfig(snapshot.data!);
  },
  callHandlerOnlyOnce: true, // false = handler re-fires on every rebuild after completion
);
```

**allowObservableChange / allowStreamChange / allowFutureChange**: By default `false`, which means the `select` function is only called once on the first build and the result is **cached**. This makes it safe to use derived observables like `listenable.map(...)` or `listenable.where(...)` inside `select` - they won't be recreated on every rebuild. Only set to `true` if you intentionally need to **switch** to a different observable/stream/future between builds (e.g. switching data sources based on state).

## Startup Orchestration

```dart
// Option 1: watch_it allReady() - returns bool, rebuilds reactively
class SplashScreen extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final ready = allReady(
      onReady: (context) => Navigator.pushReplacement(context, ...),
      onError: (context, error) => showErrorDialog(context, error),
      timeout: Duration(seconds: 10),
    );
    if (!ready) return CircularProgressIndicator();
    return MainApp();
  }
}

// Option 2: allReadyHandler (side effect only, no rebuild)
allReadyHandler(
  (context) => Navigator.pushReplacement(context, mainRoute),
  onError: (context, error) => showErrorDialog(context, error),
);
return CircularProgressIndicator(); // Always shows until handler fires

// Option 3: isReady<T>() - Wait for specific type
final dbReady = isReady<Database>(timeout: Duration(seconds: 5));

// Option 4: Without watch_it (FutureBuilder)
FutureBuilder(
  future: getIt.allReady(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SplashScreen();
    return MainApp();
  },
);
```

## Scope Management

```dart
// Push scope tied to widget lifetime (auto-popped on dispose)
pushScope(
  init: (getIt) {
    getIt.registerSingleton<PageData>(PageData());
  },
  dispose: () => print('scope cleaned up'),
);

// Rebuild when any scope changes
rebuildOnScopeChanges();
```

## Widget Granularity

A widget watching multiple objects is perfectly fine. Only split into smaller WatchingWidgets when watched values change at **different frequencies** and rebuilds become costly. Keep a balance - don't over-split.

```dart
// ✅ Fine - watching multiple values that change together or in a simple widget
class MyScreen extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final user = watchValue((Auth x) => x.user);
    final count = watchValue((Counter x) => x.count);
    return Column(children: [Header(user), Counter(count)]);
  }
}

// ✅ Split when values change at different frequencies and widget tree is expensive
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [_Header(), _Counter()]);
  }
}
class _Header extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final user = watchValue((Auth x) => x.user);
    return HeaderWidget(user);
  }
}
class _Counter extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final count = watchValue((Counter x) => x.count);
    return CounterWidget(count);
  }
}
```

## Production Patterns

**Command button with loading state**:
```dart
class WcCommandButton extends WatchingWidget {
  final Command command;
  @override
  Widget build(BuildContext context) {
    final isRunning = watch(command.isRunning).value;
    final canRun = watch(command.canRun).value;
    return ElevatedButton(
      onPressed: canRun ? () => command.run() : null,
      child: isRunning ? CircularProgressIndicator() : Text('Submit'),
    );
  }
}
```

**Error handling with registerHandler**:
```dart
registerHandler(
  select: (CheckoutManager m) => m.submitOrderCommand.errors,
  handler: (context, error, _) {
    handleMarketplaceApiError(error, custom404Message: 'Not found');
  },
);
```

**createOnce for local state**:
```dart
final reasonController = createOnce(() => TextEditingController());
final selectedReason = createOnce(() => ValueNotifier<ReturnReason?>(null));
```

## Debugging

```dart
// Enable tracing for a specific widget (call at top of build)
enableTracing(logRebuilds: true, logHandlers: true, logHelperFunctions: true);
```
