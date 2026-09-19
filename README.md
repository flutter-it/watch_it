<img align="left" src="https://github.com/flutter-it/watch_it/blob/main/watch_it.png?raw=true" alt="watch_it logo" width="150" style="margin-left: -10px;"/>

<div align="right">
  <a href="https://www.buymeacoffee.com/escamoteur"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="28" width="120"/></a>
  <br/>
  <a href="https://github.com/sponsors/escamoteur"><img src="https://img.shields.io/badge/Sponsor-❤-ff69b4?style=for-the-badge" alt="Sponsor" height="28" width="120"/></a>
</div>

<br clear="both"/>

# watch_it <a href="https://codecov.io/gh/flutter-it/watch_it"><img align="right" src="https://codecov.io/gh/flutter-it/watch_it/branch/main/graph/badge.svg?style=for-the-badge" alt="codecov" width="200"/></a>

> 📚 **[Complete documentation available at flutter-it.dev](https://flutter-it.dev/documentation/watch_it/getting_started)**
> Check out the comprehensive docs with detailed guides, examples, and best practices!

**The easiest state management for Flutter built on `get_it`**

Widgets automatically rebuild when data changes. No `ValueListenableBuilder`, no `StreamBuilder`, no `FutureBuilder`—just watch your data and your UI stays in sync.

One line instead of 12. No nesting, no boilerplate. Watch multiple values without builder hell.

> **Part of [flutter_it](https://flutter-it.dev)** — A construction set of independent packages. watch_it + get_it is the recommended foundation. Add command_it and listen_it when you need them.

## Why watch_it?

- **✨ Zero Boilerplate** — No Builders, no `setState`, no widget tree nesting
- **⚡ Automatic Cleanup** — Subscriptions disposed automatically when widget destroys
- **🎯 Type Safe** — Catch errors at compile time with generics
- **🔧 Flexible Data Types** — Works with Listenable, ValueListenable, Stream, Future
- **📊 Multiple Watches** — Watch 3+ values without pyramid of doom
- **🧪 Test Friendly** — Easy to mock and inject dependencies

[Learn more about the benefits →](https://flutter-it.dev/documentation/watch_it/getting_started)

## Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  watch_it: ^2.2.0
  get_it: ^9.0.5  # Recommended - watch_it builds on get_it
```

### Basic Example

```dart
import 'package:watch_it/watch_it.dart';

// 1. Create a model with ValueNotifier properties
class CounterModel {
  final count = ValueNotifier<int>(0);
  void increment() => count.value++;
}

// 2. Register with get_it (using exported 'di' instance)
di.registerSingleton(CounterModel());

// 3. Watch it - widget rebuilds automatically
class CounterWidget extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final count = watchValue((CounterModel m) => m.count);
    return Column(
      children: [
        Text('$count'),
        ElevatedButton(
          onPressed: di<CounterModel>().increment,
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

**That's it!** No builders, no manual subscriptions. Just watch and rebuild.

### Multiple Watches

Watch multiple values without nesting builders:

```dart
class UserDashboard extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    // Watch multiple values - no nested builders!
    final userName = watchValue((UserModel m) => m.name);
    final isLoggedIn = watchValue((AuthModel m) => m.isLoggedIn);
    final notifications = watchStream(
      (NotificationModel m) => m.updates,
      initialValue: []
    );

    if (!isLoggedIn) return LoginScreen();

    return Text(
      '$userName - ${notifications.data?.length ?? 0} notifications'
    );
  }
}
```

[Full tutorial](https://flutter-it.dev/documentation/watch_it/getting_started)

## Key Features

### Watch Functions

Replace Builders with simple one-line watch calls:

- **[watchValue](https://flutter-it.dev/documentation/watch_it/your_first_watch_functions)** — Watch `ValueListenable` properties from get_it objects

- **[watchIt](https://flutter-it.dev/documentation/watch_it/more_watch_functions#watchit-watch-whole-object-in-get_it)** — Watch whole `Listenable` objects registered in get_it

- **[watchPropertyValue](https://flutter-it.dev/documentation/watch_it/more_watch_functions#watchpropertyvalue-selective-updates)** — Watch specific property, rebuilds only when value changes

- **[watchStream](https://flutter-it.dev/documentation/watch_it/watching_streams_and_futures#watchstream-reactive-streams)** — Reactive streams without StreamBuilder

- **[watchFuture](https://flutter-it.dev/documentation/watch_it/watching_streams_and_futures#watchfuture-reactive-futures)** — Reactive futures without FutureBuilder

- **[watch](https://flutter-it.dev/documentation/watch_it/more_watch_functions#watch-watch-any-listenable)** — Watch any local Listenable

### Handler Functions (Side Effects)

Execute side effects without rebuilding:

- **[registerHandler](https://flutter-it.dev/documentation/watch_it/handlers#registerhandler-for-valuelistenables)** — React to ValueListenable changes (show dialogs, navigate)

- **[registerStreamHandler](https://flutter-it.dev/documentation/watch_it/handlers#registerstreamhandler-for-streams)** — React to stream events

- **[registerFutureHandler](https://flutter-it.dev/documentation/watch_it/handlers#registerfuturehandler-for-futures)** — React to future completion

- **[registerChangeNotifierHandler](https://flutter-it.dev/documentation/watch_it/handlers#registerchangenotifierhandler-for-changenotifier)** — React to ChangeNotifier changes

### Watching objects created by cached factories with parameters

If you have one manager per entity (e.g. per station id), register it with `registerCachedFactoryParam` and pass the parameter to the watch function. When the parameter changes, watch_it automatically unsubscribes from the old instance and subscribes to the new one:

```dart
di.registerCachedFactoryParam<StationManager, String, void>(
  (stationId, _) => StationManager(stationId),
);

class StationTile extends WatchingWidget {
  final String stationId;
  const StationTile({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    final name = watchValue((StationManager m) => m.name, param1: stationId);
    return Text(name);
  }
}
```

`param1`/`param2` are available on all watch and handler functions that resolve their object from get_it. They are only valid for types registered with `registerCachedFactoryParam`. Plain `registerFactory` registrations can't be watched at all (every build would get a new instance) and are rejected in debug mode.

### Lifecycle Helpers

Powerful functions for StatelessWidgets:

- **[createOnce](https://flutter-it.dev/documentation/watch_it/lifecycle#createonce-and-createonceasync)** — Create objects on first build, auto-dispose on widget destroy

- **[callOnce](https://flutter-it.dev/documentation/watch_it/lifecycle#callonce-and-ondispose)** — Execute function only on first build

- **[callOnceAfterThisBuild](https://flutter-it.dev/documentation/watch_it/lifecycle#callonceafterthisbuild)** — Execute function once after current build completes

- **[callAfterEveryBuild](https://flutter-it.dev/documentation/watch_it/lifecycle#callaftereverybuild)** — Execute function after every rebuild

- **[pushScope](https://flutter-it.dev/documentation/watch_it/advanced_integration#pushscope)** — Automatic get_it scope management tied to widget lifecycle

### Important Rules ⚠️

All `watch*` calls must:
- Be called inside `build()` method
- Be called in **same order** every build
- Not be conditional (no `if` wrapping watch calls)

**Why these rules?** watch_it uses index-based retrieval similar to React Hooks. Changing the order breaks the mapping between calls and stored data.

[Read the detailed explanation →](https://flutter-it.dev/documentation/watch_it/watch_ordering_rules)

## Widget Types

Choose the widget type that fits your needs:

- **WatchingWidget** — Extends `StatelessWidget`, use for simple widgets
- **WatchingStatefulWidget** — Extends `StatefulWidget`, use when you need lifecycle or local state
- **WatchItMixin** — Add to existing `StatelessWidget` with `with WatchItMixin`
- **WatchItStatefulWidgetMixin** — Add to existing `StatefulWidget` with `with WatchItStatefulWidgetMixin`

[Learn which to use when →](https://flutter-it.dev/documentation/watch_it/watching_widgets)

## Ecosystem Integration

**Built on get_it** — watch_it is designed to work with get_it's service locator pattern. Register your models, services, and business logic with get_it, then watch them reactively.

```dart
// Register with get_it
di.registerLazySingleton(() => UserManager());
di.registerLazySingleton(() => TodoManager());

// Watch them in any widget
class MyWidget extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final user = watchIt<UserManager>();
    final todos = watchValue((TodoManager m) => m.todos);
    return ListView(...);
  }
}
```

**Want more?** Combine with other flutter_it packages:

- **[get_it](https://pub.dev/packages/get_it)** — **Recommended pairing.** Service locator for dependency injection. Access global services with `di<T>()`.

- **Optional: [command_it](https://pub.dev/packages/command_it)** — Command pattern with loading/error states. Watch Commands reactively for automatic UI updates.

- **Optional: [listen_it](https://pub.dev/packages/listen_it)** — ValueListenable operators (map, debounce, where). Watch reactive collections (ListNotifier, MapNotifier, SetNotifier).

> 💡 **flutter_it is a construction set** — watch_it + get_it is the recommended foundation. Add command_it and listen_it when you need advanced features. Each package works independently.

[Explore the ecosystem →](https://flutter-it.dev)

## AI-Assisted Development

This package ships an [Agent Skill](https://agentskills.io) for AI coding assistants
(Claude Code, Cursor, GitHub Copilot, Codex, Gemini CLI and others) in `skills/watch-it-expert/`.
It teaches them the critical rules, common patterns and anti-patterns of watch_it.
Install it into your project with the official Dart skills tool:

```bash
dart run skills@ get
```

> `dart run skills@ get` only looks at *direct* dependencies. If you use get_it through watch_it, add `get_it` to your pubspec as well to also get `get-it-expert`.

For the ecosystem-wide skills (architecture guidance, feed/data-source patterns, overview)
and the skills of the other flutter_it packages run:

```bash
dart run skills@ add flutter-it/flutter_it
```

[Learn more about AI skills →](https://flutter-it.dev/misc/ai_skills)

## Learn More

### 📖 Documentation

- **[Getting Started Guide](https://flutter-it.dev/documentation/watch_it/getting_started)** — Installation, basic concepts, first steps
- **[Your First Watch Functions](https://flutter-it.dev/documentation/watch_it/your_first_watch_functions)** — Learn `watchValue()` with examples
- **[More Watch Functions](https://flutter-it.dev/documentation/watch_it/more_watch_functions)** — `watchIt()`, `watchPropertyValue()`, `watch()`
- **[Watching Streams & Futures](https://flutter-it.dev/documentation/watch_it/watching_streams_and_futures)** — Replace builders with one-line watches
- **[Handler Functions](https://flutter-it.dev/documentation/watch_it/handlers)** — Side effects without rebuilding
- **[Lifecycle Helpers](https://flutter-it.dev/documentation/watch_it/lifecycle)** — `createOnce()`, `callOnce()`, disposal
- **[Watch Ordering Rules](https://flutter-it.dev/documentation/watch_it/watch_ordering_rules)** — **Critical reading!** Understanding the order requirement
- **[Debugging & Troubleshooting](https://flutter-it.dev/documentation/watch_it/debugging_tracing)** — Common errors, tracing, solutions
- **[Best Practices](https://flutter-it.dev/documentation/watch_it/best_practices)** — Patterns, performance, testing
- **[Advanced Integration](https://flutter-it.dev/documentation/watch_it/advanced_integration)** — Scopes, async initialization, named instances

### 💬 Community & Support

- **[Discord](https://discord.gg/ZHYHYCM38h)** — Get help, share ideas, connect with other developers
- **[GitHub Issues](https://github.com/escamoteur/watch_it/issues)** — Report bugs, request features
- **[GitHub Discussions](https://github.com/escamoteur/watch_it/discussions)** — Ask questions, share patterns

## Contributing

Contributions are welcome! Please read the [contributing guidelines](CONTRIBUTING.md) before submitting PRs.

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Part of the [flutter_it ecosystem](https://flutter-it.dev)** — Build reactive Flutter apps the easy way. No codegen, no boilerplate, just code.
