<img align="left" src="https://github.com/flutter-it/watch_it/blob/main/watch_it.png?raw=true" alt="watch_it logo" width="150" style="margin-left: -10px;"/>

<div align="right">
  <a href="https://www.buymeacoffee.com/escamoteur"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="28" width="120"/></a>
  <br/>
  <a href="https://github.com/sponsors/escamoteur"><img src="https://img.shields.io/badge/Sponsor-❤-ff69b4?style=for-the-badge" alt="Sponsor" height="28" width="120"/></a>
</div>

<br clear="both"/>

# watch_it <a href="https://codecov.io/gh/escamoteur/watch_it"><img align="right" src="https://codecov.io/gh/escamoteur/watch_it/branch/master/graph/badge.svg?style=for-the-badge" alt="codecov" width="200"/></a>

> 📚 **[Complete documentation available at flutter-it.dev](https://flutter-it.dev/documentation/watch_it/getting_started)**
> Check out the comprehensive docs with detailed guides, examples, and best practices!

A simple state management solution powered by get_it.

> This package is the successor of the get_it_mixin, [here you can find what's new](#whats-different-from-the-get_it_mixin)

> We now have a support discord server [https://discord.gg/ZHYHYCM38h](https://discord.gg/ZHYHYCM38h)

This package offers a set of functions to `watch` data registered with `GetIt`. Widgets that watch data will rebuild automatically whenever that data changes.

Supported data types that can be watched are `Listenable / ChangeNotifier`, `ValueListenable / ValueNotifier`, `Stream` and `Future`. On top of that there are several other powerful functions to use in `StatelessWidgets` that normally would require a `StatefulWidget`.

`ChangeNotifier` based example:

```dart
 // Create a ChangeNotifier based model
 class UserModel extends ChangeNotifier {
   get name => _name;
   String _name = '';
   set name(String value){
     _name = value;
     notifyListeners();
   }
   ...
 }

 // Register it
 di.registerSingleton<UserModel>(UserModel());

 // Watch it
 class UserNameText extends WatchingWidget {
   @override
   Widget build(BuildContext context) {
     final userName = watchPropertyValue((UserModel m) => m.name);
     return Text(userName);
   }
 }
```

Whenever the name property changes the `watchPropertyValue` function will trigger a rebuild and return the latest value of `name`.

## Accessing GetIt

WatchIt exports the default instance of get_it as a global variable `di` (**d**ependency **i**njection) which lets
you access it from anywhere in your app. To access any get_it registered
object you only have to type `di<MyType>()` instead of `GetIt.I<MyType>()`.
If you prefer to use `GetIt.I` or you have your own global variable that's fine too as they all
will use the same instance of GetIt.

> Because of criticism that GetIt isn't real dependency injection, therefore `di` wouldn't be correct, you now can also use `sl` for service locator instead.

If you want to use a different instance of get_it you can pass it to
the functions of this library as an optional parameter.

## Watching Data

Where `WatchIt` really shines is data-binding. It comes with a set of `watch` methods to rebuild a widget when data changes.

Imagine you had a very simple shared model, with multiple fields, one of them being country:

```dart
class Model {
    final country = ValueNotifier<String>('Canada');
    ...
}
di.registerSingleton<Model>(Model());
```

You could tell your view to rebuild any time country changes with a simple call to `watchValue`:

```dart
class MyWidget extends StatelessWidget with WatchItMixin {
  @override
  Widget build(BuildContext context) {
    String country = watchValue((Model x) => x.country);
    ...
  }
}
```

There are various `watch` methods, for common types of data sources, including `ChangeNotifier`, `ValueNotifier`, `Stream` and `Future`:

| API  | Description  |
|---|---|
| `watch` | observes any Listenable you have access to |
| `watchIt` | observes any Listenable registered in get_it |
| `watchValue` | observes a ValueListenable property of an object registered in get_it |
| `watchPropertyValue` | observes a property of a Listenable object and trigger a rebuild whenever the Listenable notifies a change and the value of the property changes |
| `watchStream` | observes a Stream and triggers a rebuild whenever the Stream emits a new value |
| `watchFuture` | observes a Future and triggers a rebuild whenever the Future completes |

To be able to use the functions you have either to derive your widget from
`WatchingWidget` or `WatchingStatefulWidget` or use the `WatchItMixin` or `WatchItStatefulWidgetMixin` in your widget class and call the watch functions inside the their build functions.

Just call `watch*` to listen to the data type you need, and `WatchIt` will take care of cancelling bindings and subscriptions when the widget is destroyed.

The primary benefit to the `watch` methods is that they eliminate the need for `ValueListenableBuilders`, `StreamBuilder` etc. Each binding consumes only one line and there is no nesting. Making your code more readable and maintainable. Especially if you want to bind more than one variable.

Here we watch three `ValueListenable` which would normally be three builders, 12+ lines of code and several levels of indentation. With `WatchIt`, it's three lines:

```dart
class MyWidget extends StatelessWidget with WatchItMixin {
  @override
  Widget build(BuildContext context) {
    bool loggedIn = watchValue((UserModel x) => x.isLoggedIn);
    String userName = watchValue((UserModel x) => x.user.name);
    bool darkMode = watchValue((SettingsModel x) => x.darkMode);
    ...
  }
}
```

This can be used to eliminate `StreamBuilder` and `FutureBuilder` from your UI as well:

```dart
class MyWidget extends StatelessWidget with WatchItMixin {
  @override
  Widget build(BuildContext context) {
    final currentUser = watchStream((UserModel x) => x.userNameUpdates, initialValue: 'NoUser');
    final ready = watchFuture((AppModel x) => x.initializationReady, initialValue: false).data;
    bool appIsLoading = ready == false || currentUser.hasData == false;
    
    if(appIsLoading) return CircularProgressIndicator();
    return Text(currentUser.data);    
  }
}
```

compare that to:

```dart
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: di<AppModel>().initializationReady,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        return StreamBuilder(
          stream: di<UserModel>().userNameUpdates,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            return Text(snapshot.data!);
          },
        );
      },
    );
  }
```  

### Side Effects / Event Handlers

Instead of rebuilding, you might instead want to show a toast notification or dialog when a Stream emits a value or a ValueListenable changes. Normally you would need to use a `Stateful` widget to be able to subscribe and unsubscribe your handler function.

To run an action when data changes you can use the `register*Handler` methods:

| API  | Description  |
|---|---|
| `.registerHandler`  | Add an event handler for a `ValueListenable`  |
| `.registerStreamHandler`  | Add an event handler for a `Stream`  |
| `.registerFutureHandler`  | Add an event handler for a `Future`  |
| `.registerChangeNotifierHandler`  | Add an event handler for a `ChangeNotifier`  |

The `registerHandler`, `registerStreamHandler` and `registerFutureHandler` methods have an optional `select` delegate parameter that can be used to watch a specific field of an object in GetIt. The second parameter is the action which will be triggered when that field changes:

```dart
class MyWidget extends StatelessWidget with WatchItMixin {
  @override
  Widget build(BuildContext context) {
    registerHandler(
        select: (Model x) => x.name,
        handler: (context, value, cancel) => showNameDialog(context, value));
    ...
  }
}
```

In the example above you see that the handler function receives the value that is returned from the select delegate (`(Model x) => x.name`), as well as a `cancel` function that the handler can call to cancel registration at any time.

In case of the `registerChangeNotifierHandler` the handler function receives the `ChangeNotifier` object itself as well as a `cancel` function that the handler can call to cancel registration at any time.

```dart

class Counter extends ChangeNotifier {
  int value = 0;
  void increment() {
    value++;
    notifyListeners();
  }
}

di.registerSingleton<Counter>(Counter());

class MyWidget extends StatelessWidget with WatchItMixin {
  @override
  Widget build(BuildContext context) {
    registerChangeNotifierHandler(
        handler: (context, Counter value, cancel) {
          if (value.value == 3) {
            SnackBar snackbar = SnackBar(
              content: Text('Value is 3'),
            );

            Scaffold.of(context).showSnackBar(snackbar);
          }
        }
    );
    ...
  }
}

```

As with `watch` calls, all `registerHandler` calls are cleaned up when the Widget is destroyed. If you want to register a handler for a local variable all the functions offer a `target` parameter.

# Rules

There are some important rules to follow in order to avoid bugs with the `watch` or `register*` methods:

* `watch` methods must be called within `build()`
  * It is good practice to define them at the top of your build method
* must be called on every build, in the same order (no conditional watching). This is similar to `flutter_hooks`.
* do not use them inside of a builder as it will break the mixins ability to rebuild

If you want to know more about the reasons for this rule check out [Lifting the magic curtain](#lifting-the-magic-curtain)

# The watch functions in detail:

## Watching `Listenable / ChangeNotifier`

`watch` observes any `Listenable` that you pass as parameter and triggers a rebuild whenever it notifies a change.

```dart
T watch<T extends Listenable>(T target);
```

That listenable is passed directly in as a parameter which means it could be  some local variable/property or also come from get_it. Like

```dart
final userName = watch(di<UserModel>()).name;
```

given that `UserManager` is a `Listenable` (eg. `ChangeNotifier`).

If all of the following functions don't fit your needs you can probably use this one by manually providing the Listenable that should be observed.

Example:

```dart
class CounterModel with ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count += 1;
    notifyListeners();
  }
}

final counter = CounterModel();
...

Widget build(BuildContext context) {
  watch(counter);

  return Text(counter.count);
}
```

## Watching `Listenable` inside GetIt

`watchIt` observes any Listenable registered with the type `T` in get_it and triggers a rebuild whenever it notifies a change. It's basically a shortcut for `watch(di<T>())`.
`instanceName` is the optional name of the instance if you registered it
with a name in get_it.
`getIt` is the optional instance of get_it to use if you don't want to use the
default one. 99% of the time you won't need this.

```dart
T watchIt<T extends Listenable>({String? instanceName, GetIt? getIt}) {
```

If we take our Listenable `UserModel` from above we could watch it like

```dart
class MyWidget extends StatelessWidget with WatchItMixin {
  @override
  Widget build(BuildContext context) {
    final userName = watchIt<UserModel>().name;
    return Text(userName);
  }
}
```

## Watching only one property of a `Listenable`

If the `Listenable` parent object that you watch with `watchIt` notifies often because other properties have changed that you don't want to watch, the widget would rebuild without any need. In this case you can use `watchPropertyValue`

```dart
R watchPropertyValue<T extends Listenable, R>(R Function(T) selectProperty,
    {T? target, String? instanceName, GetIt? getIt});
```

It will only trigger a rebuild if the watched listenable notifies a change AND the value of the selected property has really changed.

```dart
final userName = watchPropertyValue<UserManager, String>((m) => m.userName);
```

Could be an example. Or even more expressive and concise:

```dart
final userName = watchPropertyValue((UserManager m) => m.userName);
```

which lets the analyzer infer the type of T and R.

If you have a local Listenable and you want to observe only a single property
you can pass it as [target] and omit the generic parameter:

```dart
final userManager = UserManager();
...
// inside build()
final userName = watchPropertyValue((m) => m.userName, target: userManger);
```

## Watching `ValueListenable / ValueNotifier

```dart
R watchValue<T extends Object, R>(ValueListenable<R> Function(T) selectProperty,
    {String? instanceName, GetIt? getIt}) {
```

`watchValue` observes a `ValueListenable` (e.g. a `ValueNotifier`) property of an object registered in get_it.
It triggers a rebuild whenever the `ValueListenable` notifies a change and returns its current value. It's basically a shortcut for `watchIt<T>().value`
As this is a common scenario it allows us a type safe concise way to do this.

```dart
class UserManager
{
  final userName = ValueNotifier<String>('James');
}

// register it in GetIt
di.registerSingleton(UserManager);

// watch it
Widget build(BuildContext context) {
  final userName = watchValue<UserManager, String>((user) => user.userName);

  return Text(userName);
}
```

is an example of how to use it.
We can use the strength of generics to infer the type of the property and write
it even more expressive like this:

```dart
final userName = watchValue((UserManager user) => user.userName);
```

`instanceName` is the optional name of the instance if you registered it
with a name in get_it.
`getIt` is the optional instance of get_it to use if you don't want to use the
default one. 99% of the time you won't need this.

### Watching a local ValueListenable/ValueNotifier

You might wonder why `watchValue` has no `target` parameter. The reason is that Dart doesn't support positional optional parameters in combination with named optional parameters. This would require that you always would have to add a parameter name to the select function when using it in the most common way to watch a `ValueListenable` property of an object inside GetIt.
As there is already another option to watch local ValueListenable by using `watch` I decided to drop the `target` property from `watchValue`.
As all `ValueListenable` are also `Listenable` we can watch them with `watch()`:

```dart
final counter = ValueNotifier<int>();

Widget build(BuildContext context) {
  final counterValue = watch(counter).value;

  return Text(counterValue);
}
```

This will trigger a rebuild every time the `counter.value` changes.

# Watching Streams and Futures

`watchStream and watchFuture` follow nearly the same pattern as the above watch functions.

```dart
class TestStateLessWidget extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = watchStream((Model x) => x.userNameUpdateStream, 'NoUser');
    final ready =
        watchFuture((Model x) => x.initializationReady,false).data;

    return Column(
      children: [
        if (ready != true || !currentUser.hasData) // in case of an error ready could be null
         CircularProgressIndicator()
         else
        Text(currentUser.data),
      ],
    );
  }
}
```

> **Important**: `watchFuture` and `watchStream` expect that the selector function that is used to select the watched Stream/Future will return the same Stream/Future on every build (unless you really know what you are doing). So you should not call any async function that returns a new Future here because otherwise it can easily happen that your widget gets into an infinite rebuild cycle. 

Please check the API docs for details.

# __isReady<T>() and allReady()__

A common use case is to toggle a loading state when side effects are in-progress. To check whether any async registration actions inside `GetIt` have completed you can use `allReady()` and `isReady<T>()`. These methods return the current state of any registered async operations and a rebuild is triggered when they change.
If you only want the `onReady` handler to be called once set `callHandlerOnlyOnce==true`

```dart
class MyWidget extends StatelessWidget with WatchItMixin {
  @override
  Widget build(BuildContext context) {
    allReady(onReady: (context)
      => Navigator.of(context).pushReplacement(MainPageRoute()));
    return CircularProgressIndicator();
  }
}
```

Check out the GetIt docs for more information on the `isReady` and `allReady` functionality:
[https://pub.dev/packages/get_it](https://pub.dev/packages/get_it)

# __callOnce() and onDispose()__

If you want to execute a function  only on the first built (even in in a StatelessWidget), you can use the `callOnce` function anywhere in your build function. It has an optional `dispose` handler which will be called when the widget is disposed.

To dispose anything when the widget is disposed you can use call `onDispose` anywhere in your build function

# __createOnce and createOnceAsync__

If you need an object that is created on the first build of your stateless widget that is automatically disposed when the widget is destroyed you can use `createOnce`:

```dart
  Widget build(BuildContext context) {
    final controller =
        createOnce<TextEditingController>(() => TextEditingController());
    return Row(
      children: [
        TextField(
          controller: controller,
        ),
        ElevatedButton(
          onPressed: () => controller.clear(),
          child: const Text('Clear'),
        ),
      ],
    );
  }
```

On the first build, the controller gets created. On all following builds the same controller instance is returned. When the widget is disposed the controller gets disposed by either:

* if the object contains a `dispose()` method it will be called automatically
* if you need to call a different function to dispose the object, like `cancel()` on a StreamSubscription you can pass a custom dispose function as a second parameter to `createOnce`.

If the object you need requires an async creation function you can use:

```dart
/// [createOnceAsync] creates an  object with the async factory function
/// [factoryFunc] at the time of the first build and disposes it when the widget
/// is disposed if the object implements the Disposable interface.
/// [initialValue] is the value that will be returned until the factory function
/// completes.
/// When the [factoryFunc] completes the value will be updated with the new value
/// and the widget will be rebuilt.
/// [dispose] allows you to pass a custom dispose function to dispose of the
/// object.
/// if provided it will override the default dispose behavior.
AsyncSnapshot<T> createOnceAsync<T>(Future<T> Function() factoryFunc,
    {required T initialValue, void Function(T)? dispose});
```

# Pushing a new GetIt Scope

With `pushScope()` you can push a scope when a Widget/State is mounted, and automatically drop it when the Widget/State is destroyed. You can pass an optional init or dispose function.

```dart
void pushScope({void Function(GetIt getIt) init, void Function() dispose});
```

The newly created Scope gets a unique name so that it is ensured the right Scope is dropped even if you push or drop manually other Scopes.

# The WatchingWidgets

Some people don't like mixins so `WatchIt` offers two Widgets that can be used instead.

* `WatchingWidget` - can be used instead of `StatelessWidget`
* `WatchingStatefulWidget` - instead of `StatefulWidget`


# Tracing and Debugging

`WatchIt` provides comprehensive tracing and debugging capabilities to help you understand what's happening in your reactive widgets. This feature allows you to monitor rebuilds, handler calls, and other watch_it events in real-time.

## Basic Tracing

You can enable tracing for individual widgets using the `enableTracing()` function:

```dart
class MyWidget extends StatelessWidget with WatchItMixin {
  @override
  Widget build(BuildContext context) {
    // Enable tracing for this widget (must be called before any watch functions)
    enableTracing(logRebuilds: true, logHandlers: true);
    
    final user = watchIt<UserModel>();
    final userName = watchPropertyValue((UserModel m) => m.name);
    
    return Text(userName);
  }
}
```

This will log all rebuilds and handler calls for this specific widget to the console.

## Global Subtree Tracing

For more comprehensive tracing, you can enable global subtree tracing and use the `WatchItSubTreeTraceControl` widget:

```dart
// Enable global subtree tracing
enableSubTreeTracing = true;


// Wrap your app or specific subtrees with WatchItSubTreeTraceControl
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WatchItSubTreeTraceControl(
      logRebuilds: true,
      logHandlers: true,
      logHelperFunctions: true,
      child: MaterialApp(
        home: MyHomePage(),
      ),
    );
  }
}
```

This will trace all `WatchIt` events for all widgets in the subtree, even if they don't explicitly call `enableTracing()`.
You can even disable the logging for certain subtrees further down the tree by adding another `WatchItSubTreeTraceControl`.

> For performance reasons WatchingWidgets only looks for an `WatchItSubTreeTraceControl` if you set `enableSubTreeTracing=true`


## Default logging

The default logger will provide you with logs like this

```
WatchIt: Rebuild was triggered at
	 #5      _HomePageState.build (package:flutter_weather_demo/homepage.dart:31:9) 
homepage.dart:31
	 by CombiningValueNotifier<bool, bool, bool> in WeatherManager
flutter: 
WatchIt: Rebuild was triggered at
	 #5      WeatherListView.build (package:flutter_weather_demo/listview.dart:9:18) 
listview.dart:9
	 by CommandAsync<String?, List<WeatherEntry>> in WeatherManager
flutter: 
WatchIt: Rebuild was triggered at
	 #5      _HomePageState.build (package:flutter_weather_demo/homepage.dart:29:9) 
homepage.dart:29
	 by CustomValueNotifier<bool>
flutter: 
WatchIt: Rebuild was triggered at
	 #5      _HomePageState.build (package:flutter_weather_demo/homepage.dart:31:9) 
homepage.dart:31
	 by CombiningValueNotifier<bool, bool, bool> in WeatherManager
flutter: 
WatchIt: Rebuild was triggered at
	 #5      _HomePageState.build (package:flutter_weather_demo/homepage.dart:33:9) 
homepage.dart:33
	 by CommandSync<bool, bool> in WeatherManager
```

## Custom Logging

You can override the default logging behavior by providing your own logging function:

```dart
// Define a custom logging function
void myCustomLogger({
  String? sourceLocationOfWatch,
  required WatchItEvent eventType,
  Object? observedObject,
  Object? parentObject,
  Object? lastValue,
}) {
  // Log to your preferred system (e.g., Firebase Analytics, Sentry, etc.)
  print('Custom Log: $eventType at $sourceLocationOfWatch');
  
  // Or send to external logging service
  // analyticsService.logEvent('watch_it_event', {
  //   'event_type': eventType.toString(),
  //   'location': sourceLocationOfWatch,
  //   'observed_object': observedObject?.runtimeType.toString(),
  // });
}

// Assign your custom logger
watchItLogFunction = myCustomLogger;
```

## Event Types

The tracing system categorizes events into different types:

- **`WatchItEvent.rebuild`**: Widget rebuilds triggered by data changes
- **`WatchItEvent.handler`**: Handler functions called for data changes
- **`WatchItEvent.createOnce`**: Objects created with `createOnce()`
- **`WatchItEvent.createOnceAsync`**: Objects created with `createOnceAsync()`
- **`WatchItEvent.allReady`**: `allReady()` checks performed
- **`WatchItEvent.isReady`**: `isReady()` checks performed
- **`WatchItEvent.scopePush`**: New GetIt scopes pushed
- **`WatchItEvent.callOnce`**: `callOnce()` functions executed
- **`WatchItEvent.onDispose`**: `onDispose()` functions called
- **`WatchItEvent.scopeChange`**: GetIt scope changes detected

## Advanced Usage

### Selective Tracing

You can enable different types of tracing for different parts of your app:

```dart
// Enable only rebuild tracing for a specific subtree
WatchItSubTreeTraceControl(
  logRebuilds: true,
  logHandlers: false,
  logHelperFunctions: false,
  child: MyWidget(),
)

// Enable only handler tracing for another subtree
WatchItSubTreeTraceControl(
  logRebuilds: false,
  logHandlers: true,
  logHelperFunctions: false,
  child: AnotherWidget(),
)
```

### Integration with External Services

The tracing system is designed to integrate easily with external logging and analytics services:

```dart
// Example: Integration with Firebase Analytics
void firebaseAnalyticsLogger({
  String? sourceLocationOfWatch,
  required WatchItEvent eventType,
  Object? observedObject,
  Object? parentObject,
  Object? lastValue,
}) {
  FirebaseAnalytics.instance.logEvent(
    name: 'watch_it_event',
    parameters: {
      'event_type': eventType.toString(),
      'location': sourceLocationOfWatch ?? 'unknown',
      'observed_object': observedObject?.runtimeType.toString(),
      'parent_object': parentObject?.runtimeType.toString(),
    },
  );
}

// Example: Integration with Sentry
void sentryLogger({
  String? sourceLocationOfWatch,
  required WatchItEvent eventType,
  Object? observedObject,
  Object? parentObject,
  Object? lastValue,
}) {
  Sentry.addBreadcrumb(
    Breadcrumb(
      message: 'WatchIt Event: $eventType',
      category: 'watch_it',
      data: {
        'location': sourceLocationOfWatch,
        'observed_object': observedObject?.runtimeType.toString(),
      },
    ),
  );
}
```

### Performance Monitoring

You can use the tracing system to monitor performance and identify potential issues:

```dart
void performanceLogger({
  String? sourceLocationOfWatch,
  required WatchItEvent eventType,
  Object? observedObject,
  Object? parentObject,
  Object? lastValue,
}) {
  final timestamp = DateTime.now();
  
  // Track frequency of rebuilds
  if (eventType == WatchItEvent.rebuild) {
    _rebuildCount++;
    if (_rebuildCount > 10) {
      print('Warning: High rebuild frequency detected at $sourceLocationOfWatch');
    }
  }
  
  // Log performance metrics
  print('Performance: $eventType took ${timestamp.difference(_lastEvent).inMilliseconds}ms');
  _lastEvent = timestamp;
}
```

## Best Practices

1. **Use tracing in development**: Enable tracing during development to understand your widget behavior
2. **Disable in production**: Consider disabling or using minimal tracing in production builds
3. **Be selective**: Use subtree tracing to focus on specific areas of your app
4. **Custom logging**: Implement custom logging to integrate with your existing monitoring systems
5. **Performance awareness**: Monitor rebuild frequency to identify potential performance issues

The tracing system provides powerful insights into your reactive widgets, helping you debug issues, optimize performance, and understand the flow of data through your application.


# Lifting the magic curtain

*It's not necessary to understand the following chapter to use `WatchIt` successfully.
You might be wondering how on earth is this possible, that you can watch multiple objects at the same time without passing some identifier to any of the `watch` functions. The reality might feel a bit like a hack but the advantages that you get from it justify it absolutely.
When applying the `WatchItMixin` to a Widget you add a handler into the build mechanism of Flutter that makes sure that before the `build` function is called a `_watchItState` object that contains a reference to the `Element` of this widget plus a list of `WatchEntry`s is assigned to a private global variable. Over this global variable the `watch*` functions can access the `Element` to trigger a rebuild.
With each `watch*` function call a new `WatchEntry` is added to that list and a counter is incremented.
When a rebuild is triggered the counter is reset and incremented again with each `watch*` call so that it can access the data it stored during the last build.
Now it should be clear why the `watch*` functions always have to happen in the same order and no conditionals are allowed that would change the order between two builds because then the relation between `watch*` call and its `WatchEntry` would be messed up.
If you think that all sounds very familiar to you then probably because the exact same mechanism is used by `flutter_hooks` or React Hooks.

# Find out more!

To learn more about GetIt, watch the presentation: [GetIt in action By Thomas Burkhart](https://youtu.be/YJ52kSfSMyM), in there the predecessor of this package called ´get_it_mixin´ is described but the video should still be helpful for the GetIt part.

## What's different from the `get_it_mixin`

Two main reasons lead me to replace the `get_it_mixin` package with `watch_it`

* The name `get_it_mixin seemed not to catch with people and only a fraction of my get_it users used it.
* The API naming wasn't as intuitive as I thought when I first wrote them.

These are the main differences:

* Widgets now can be `const`!
* a reduced API with more intuitive naming.The old package had too many functions which were only slight variations of each other. You can easily achieve the same functionality with the functions of this package.
* no `get/getX` functions anymore because you can just use the included global `get_it` instance `di<T>`.
* only one mixin for all Widgets. You only need to apply it to the widget and no mixin for `States` as now all `watch*` functions are global functions.

Please let me know if you miss anything
