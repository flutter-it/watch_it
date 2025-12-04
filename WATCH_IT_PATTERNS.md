# watch_it Usage Patterns Guide

A comprehensive guide to using the `watch_it` package for reactive state management in Flutter, integrated with the `command_it` package for handling async operations.

---

## Core watch_it Functions

### 1. **watchValue** - Reactive State Observation

The most common pattern for observing reactive state changes from managers.

**Pattern:**
```dart
// Watch specific manager properties
final data = watchValue((DataManager m) => m.data);
final isLoading = watchValue((DataManager m) => m.command.isRunning);

// Watch command state
final result = watchValue((DataManager m) => m.fetchCommand);
```

**Multiple Properties Example:**
```dart
final userState = watchValue((UserManager m) => m.userState);
final settings = watchValue((SettingsManager m) => m.settings);
final isEnabled = watchValue((AppState s) => s.isFeatureEnabled);
```

**Watching Filters:**
```dart
final location = watchValue((FilterManager m) => m.location);
final category = watchValue((FilterManager m) => m.category);
final sortOrder = watchValue((FilterManager m) => m.sortOrder);
final tags = watchValue((FilterManager m) => m.tags);
```

---

### 2. **callOnce** - One-Time Initialization

Used for initialization logic that should run only once, similar to `initState` but in a stateless context.

**Pattern:**
```dart
callOnce((_) {
  // Initialize data, trigger commands
  di<Manager>().loadCommand.run();
});
```

**Examples:**

```dart
// Load initial data on first build
callOnce((_) {
  di<DataManager>().fetchDataCommand.run();
  di<DataManager>().loadSettingsCommand.run();
});
```

```dart
// Conditional initialization
callOnce((_) {
  if (di<DataManager>().needsRefresh) {
    di<DataManager>().refreshCommand.run();
  }
});
```

```dart
// Initialize with context
callOnce((context) {
  di<TrackingManager>().markAsViewed(widget.itemId);
});
```

```dart
// Simple initialization
callOnce((_) => manager.initFields());
```

---

### 3. **registerHandler** - Side Effect & Success Handling

Registers handlers for command results, errors, or value changes. Replaces traditional `.listen()` callbacks with widget-lifecycle-aware handlers.

**Pattern:**
```dart
// Success handler
registerHandler(
  select: (Manager m) => m.command,
  handler: (context, result, _) {
    if (result != null) {
      // Handle success
    }
  },
);

// Error handler
registerHandler(
  select: (Manager m) => m.command.errors,
  handler: (context, error, _) {
    // Show error toast/snackbar
  },
);
```

**Success Handler Example:**
```dart
// Navigate after successful creation
registerHandler(
  select: (DataManager m) => m.createCommand,
  handler: (context, result, _) async {
    if (result != null) {
      Navigator.of(context).pop();
      // Optional: trigger related actions
      di<RelatedManager>().refreshCommand.run();
    }
  },
);
```

**Error Handler Example:**
```dart
// Show error toast
registerHandler(
  select: (DataManager m) => m.loadCommand.errors,
  handler: (context, error, _) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load data: ${error.toString()}')),
    );
  },
);
```

**Multiple Handlers for One Command:**
```dart
// Error handler
registerHandler(
  target: command.errors,
  handler: (context, error, _) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.toString()}')),
    );
  },
);

// Success handler
registerHandler(
  target: command,
  handler: (context, result, _) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Success!')),
    );

    // Auto-close page if needed
    if (shouldAutoClose) {
      Navigator.of(context).pop(result);
    }
  },
);
```

**Auto-Close on Success:**
```dart
registerHandler(
  select: (Manager m) => m.createCommand,
  handler: (context, item, _) {
    if (item != null) {
      Navigator.of(context).pop(item);
    }
  },
);

registerHandler(
  select: (Manager m) => m.updateCommand,
  handler: (context, item, _) {
    if (item != null) {
      Navigator.of(context).pop(item);
    }
  },
);
```

---

### 4. **registerStreamHandler** - Stream Event Handling

Specialized handler for stream-based events, commonly used with event buses.

**Pattern:**
```dart
registerStreamHandler<Stream<EventType>, EventType>(
  target: di<EventBus>().on<EventType>(eventKey),
  handler: (context, snapshot, _) {
    // Handle stream event
  },
);
```

**Examples:**

```dart
// Listen to creation events
registerStreamHandler<Stream<ItemCreatedEvent>, ItemCreatedEvent>(
  target: di<EventBus>().on<ItemCreatedEvent>(Events.itemCreated),
  handler: (context, snapshot, _) {
    _handleNewItem(snapshot.data?.item);
  },
);

// Listen to update events
registerStreamHandler(
  target: di<EventBus>().on(Events.dataUpdated),
  handler: (context, snapshot, _) {
    _refreshData();
  },
);
```

---

### 5. **createOnce** - Create Disposable Objects Once

Creates an object once per widget lifecycle, automatically disposing it when the widget is disposed.

**Pattern:**
```dart
final dataSource = createOnce(() => createDataSource());
```

**Examples:**

```dart
// Create feed source
final dataSource = createOnce(() => item.createFeedSource());
```

```dart
// Create paginated source
final feedSource = createOnce(
  () => item.createRelatedItemsSource(),
);
```

```dart
// Create typed source
final reviewsSource = createOnce<ReviewsFeedSource>(
  () => di<Manager>().createReviewsSource(itemId),
);
```

**Typical Usage with Pagination:**
```dart
final feedSource = createOnce(() => createFeedSource());

final isLoading = watch(feedSource.isFetchingNextPage).value;
final itemCount = watch(feedSource.itemCount).value;
final errors = watch(feedSource.errors).value;
```

---

### 6. **watch** - Direct Object Watching

Low-level watching API for watching entire objects (not specific properties).

**Pattern:**
```dart
watch(object);  // Watch entire object for changes
final value = watch(object.property).value;  // Watch property with .value access
```

**Examples:**

```dart
// Watch command execution state
final isLoading = watch(command.isRunning).value;
```

```dart
// Watch data source properties
final isLoading = watch(dataSource.isFetchingNextPage).value;
final itemCount = watch(dataSource.itemCount).value;
```

```dart
// Watch multiple properties
watch(dataSource.itemCount);
final isLoading = watch(dataSource.isFetchingNextPage).value;
final errors = watch(dataSource.errors).value;
```

```dart
// Watch inherited data
final proxy = watch(InheritedData.of(context).proxy);
final isLoading = watch(proxy.updateCommand.isRunning).value;
```

```dart
// Watch entire object for any changes
watch(dataObject);
```

---

## WatchingWidget vs WatchingStatefulWidget

### WatchingWidget Pattern

Used when you don't need traditional StatefulWidget lifecycle or local state - watch_it provides all the lifecycle you need.

**Example:**
```dart
class MyWidget extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    callOnce((_) {
      di<Manager>().loadCommand.run();
    });

    final data = watchValue((Manager m) => m.data);

    registerHandler(
      select: (Manager m) => m.command,
      handler: (context, result, _) {
        if (result != null) {
          // Handle success
        }
      },
    );

    return content;
  }
}
```

### WatchingStatefulWidget Pattern

Used when you need local widget state (setState) alongside reactive state management.

**Example:**
```dart
class MyPage extends WatchingStatefulWidget {
  const MyPage({super.key, required this.itemId});

  final String itemId;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String? _selectedOption;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Use both watchValue and setState
    final data = watchValue((DataManager m) => m.data);

    // Later, use setState to update local state
    onOptionChanged(String? option) {
      setState(() {
        _selectedOption = option;
      });
    }

    return content;
  }
}
```

**With Animation Controllers:**
```dart
class AnimatedButton extends WatchingStatefulWidget {
  const AnimatedButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use watch_it for reactive state
    final isLoading = watch(di<Manager>().command.isRunning).value;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => content,
    );
  }
}
```

---

## Integration with command_it

### Command Creation Pattern

Commands are created using `Command.createAsync*` factory methods from the command_it package.

**Examples:**

```dart
// No parameter, returns list
late final loadItemsCommand = Command.createAsyncNoParam<List<Item>>(
  () async {
    final api = ItemApi(di<ApiClient>());
    final response = await api.getItems();
    return response.map(Item.fromDto).toList();
  },
  debugName: 'loadItems',
);

// No parameter, no result
late final initializeCommand = Command.createAsyncNoParamNoResult(
  () async {
    await di<Service>().initialize();
  },
  debugName: 'initialize',
);

// With parameters, returns result
late final createItemCommand = Command.createAsync<CreateItemParams, Item?>(
  (params) async {
    final api = ItemApi(di<ApiClient>());
    final dto = await api.createItem(
      title: params.title,
      description: params.description,
    );
    return Item.fromDto(dto);
  },
  debugName: 'createItem',
  errorFilter: const LocalOnlyErrorFilter(),
);
```

**Command with Complex Logic:**
```dart
late final deleteItemCommand = Command.createAsyncNoParamNoResult(
  () async {
    final api = ItemApi(di<ApiClient>());
    await api.deleteItem(id);

    // Refresh related data
    await loadItemsCommand.runAsync();

    // Update parent if exists
    if (parentId != null) {
      final parent = await di<Manager>().getItemById(parentId!);
      parent.refreshCommand.run();
    }
  },
  debugName: 'deleteItem',
  errorFilter: const CustomErrorFilter(),
);
```

### Command Execution Patterns

**Non-blocking (fire-and-forget):**
```dart
// Don't await - UI remains responsive
command.run();
```

**Blocking (wait for result):**
```dart
// Use when you need the result
await command.runAsync();
```

**In UI (preferred pattern):**
```dart
ElevatedButton(
  onPressed: () => di<Manager>().command.run(),  // No await!
  child: Text('Submit'),
)
```

### Reactive Loading States

**Pattern:**
```dart
final isLoading = watchValue((Manager m) => m.command.isRunning);
final data = watchValue((Manager m) => m.command.value);

// In UI
if (isLoading) {
  return const CircularProgressIndicator();
}
```

**Button with Loading State:**
```dart
ElevatedButton(
  onPressed: canSubmit && !isSubmitting
      ? () => di<Manager>().submitCommand.run(data)
      : null,
  child: isSubmitting
      ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
      : const Text('Submit'),
)
```

---

## Error Handling Patterns

### Command Error Filters

Use error filters to control how errors are handled:

**Basic Error Filter:**
```dart
late final command = Command.createAsync<Params, Result>(
  (params) async {
    // ... command logic
  },
  debugName: 'myCommand',
  errorFilter: const LocalOnlyErrorFilter(),  // Handle locally, don't log globally
);
```

**Error Listener Pattern:**
```dart
late final command = Command.createAsyncNoParamNoResult(
  () async {
    // ... command logic
  },
  debugName: 'myCommand',
  errorFilter: const CustomErrorFilter(),
)..errors.listen((error, stackTrace) {
    // Handle error globally
    print('Command failed: $error');
  });
```

### registerHandler Error Pattern

```dart
registerHandler(
  target: command.errors,
  handler: (context, error, _) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${error.toString()}'),
      ),
    );
  },
);
```

---

## Dependency Injection with watch_it

### DI Setup

The app uses `get_it` (which watch_it builds on) for dependency injection:

```dart
import 'package:watch_it/watch_it.dart';

void setupDi() {
  // Configure command error reporting
  Command.reportAllExceptions = false;

  // Register singletons
  di.registerSingleton<AppState>(appState);
  di.registerSingleton<StorageService>(storageService);
  di.registerSingleton<ApiClient>(apiClient);

  // Register lazy singletons (created when first accessed)
  di.registerLazySingleton<UserManager>(() => UserManager());
  di.registerLazySingleton<DataManager>(() => DataManager());
  di.registerLazySingleton<SettingsManager>(() => SettingsManager());
}
```

### DI Access in Widgets

**Pattern:**
```dart
// Direct access - NOT passed as constructor parameter
final manager = di<DataManager>();
final data = watchValue((DataManager m) => m.data);
```

**Key Principle:** If an object can be accessed via DI, **don't pass it as a widget constructor parameter**. Widgets should be self-contained and access dependencies internally.

---

## Common Patterns & Best Practices

### 1. Self-Contained Widget Pattern

**Good:**
```dart
class MyWidget extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final manager = di<DataManager>();
    final data = watchValue((DataManager m) => m.data);

    callOnce((_) => manager.loadCommand.run());

    return content;
  }
}
```

**Bad (anti-pattern):**
```dart
class MyWidget extends StatelessWidget {
  const MyWidget({required this.manager});  // ❌ Don't do this for DI objects

  final DataManager manager;
}
```

### 2. Command-First Pattern

Replace async methods with commands:

**Good:**
```dart
late final loadDataCommand = Command.createAsyncNoParam(
  () async {
    final result = await api.fetchData();
    return result;
  },
);

// In widget
callOnce((_) => di<Manager>().loadDataCommand.run());
```

**Bad:**
```dart
Future<void> loadData() async {  // ❌ Don't use raw async methods
  final result = await api.fetchData();
}
```

### 3. Initial vs Refresh Loading Pattern

Only show spinner when data is null/empty, not on every execution:

```dart
final isLoading = watch(dataSource.isFetchingNextPage).value;
final itemCount = watch(dataSource.itemCount).value;

// Only show loading on initial load
if (!isLoading && itemCount == 0) {
  return const Center(child: Text('No data'));
}

// Show content even when refreshing
return ListView.builder(
  itemCount: itemCount,
  itemBuilder: (context, index) => itemBuilder(index),
);
```

### 4. Multiple Handlers Pattern

You can register multiple handlers for different aspects:

```dart
// Success handler
registerHandler(
  select: (Manager m) => m.command,
  handler: (context, result, _) { /* handle success */ },
);

// Error handler
registerHandler(
  select: (Manager m) => m.command.errors,
  handler: (context, error, _) { /* handle error */ },
);

// Value change handler
registerHandler(
  select: (Manager m) => m.someProperty,
  handler: (context, value, _) { /* react to change */ },
);
```

### 5. Data Source Pattern

Feed sources are often created with `createOnce` and watched with `watch`:

```dart
final feedSource = createOnce(() => createFeedSource());

final isLoading = watch(feedSource.isFetchingNextPage).value;
final itemCount = watch(feedSource.itemCount).value;
final errors = watch(feedSource.errors).value;

// Use in list view
if (isLoading && itemCount == 0) {
  return const CircularProgressIndicator();
}

return ListView.builder(
  itemCount: itemCount,
  itemBuilder: (context, index) => buildItem(index),
);
```

---

## Advanced Patterns

### 1. Conditional registerHandler

```dart
// Register handler with conditional logic
registerHandler(
  select: (Manager m) => m.selectedItem,
  handler: (context, item, _) {
    if (item?.needsValidation == true) {
      showValidationDialog(context);
    }
  },
);
```

### 2. Chained Commands with registerHandler

```dart
// Execute another command based on result
registerHandler(
  select: (Manager m) => m.firstCommand,
  handler: (context, result, _) {
    if (result?.isValid == true) {
      di<Manager>().secondCommand.run(result);
    }
  },
);
```

### 3. Automatic Page Close on Success

```dart
registerHandler(
  select: (Manager m) => m.createCommand,
  handler: (context, result, _) {
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  },
);
```

### 4. WatchItMixin

Use `WatchItMixin` to add watch_it capabilities to any widget without extending `WatchingWidget`:

```dart
class MyWidget<T> extends StatelessWidget with WatchItMixin {
  @override
  Widget build(BuildContext context) {
    final data = watchValue((Manager m) => m.data);

    callOnce((_) => di<Manager>().loadCommand.run());

    return content;
  }
}
```

---

## Key Takeaways

1. **WatchingWidget replaces StatefulWidget** for most cases - use `callOnce` instead of `initState`

2. **Commands over async methods** - All async operations should use `Command.createAsync*`

3. **No DI in constructors** - Access managers via `di<Manager>()` inside widgets

4. **registerHandler replaces .listen()** - Widget-lifecycle-aware event handling

5. **Non-blocking execution** - Use `command.run()` without `await` in UI

6. **Reactive loading states** - Watch `command.isRunning` for UI feedback

7. **Error filters for different scenarios** - Use appropriate filters for error handling strategy

8. **createOnce for disposable objects** - Automatically disposed when widget is disposed

9. **Multiple registerHandler calls** - One for success, one for errors, one for value changes

10. **Stream handlers for events** - `registerStreamHandler` for event bus integration

---

## Common watch_it Functions Summary

| Function | Purpose | Typical Use Case |
|----------|---------|------------------|
| `watchValue` | Watch specific property | Reactive UI updates |
| `watch` | Watch entire object | Low-level watching |
| `callOnce` | One-time initialization | Replace `initState` |
| `registerHandler` | Handle command results | Success/error handling |
| `registerStreamHandler` | Handle stream events | Event bus integration |
| `createOnce` | Create disposable object | Data sources, controllers |

---

## Getting Started Checklist

- [ ] Setup `get_it` dependency injection
- [ ] Create managers with commands instead of async methods
- [ ] Use `WatchingWidget` instead of `StatefulWidget` where possible
- [ ] Access DI objects inside widgets, not via constructor
- [ ] Use `watchValue` for reactive state
- [ ] Use `callOnce` for initialization
- [ ] Use `registerHandler` for success/error handling
- [ ] Execute commands with `.run()` (no await)
- [ ] Watch `command.isRunning` for loading states
- [ ] Use `createOnce` for disposable objects
