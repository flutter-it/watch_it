part of 'watch_it.dart';

/// Global switch to enable/disable subtree tracing
bool enableSubTreeTracing = false;

/// Enum representing different types of events in watch_it
enum WatchItEvent {
  /// Rebuild triggered by any data source change (Listenable, Stream, Future, Property)
  rebuild,

  /// Handler function called for any data source change
  handler,

  /// Create once operation (createOnce)
  createOnce,

  /// Create once async operation (createOnceAsync)
  createOnceAsync,

  /// All ready check (allReady)
  allReady,

  /// Is ready check (isReady)
  isReady,

  /// Scope push operation (pushScope)
  scopePush,

  /// Call once operation (callOnce)
  callOnce,

  /// On dispose operation (onDispose)
  onDispose,

  /// Scope change detection (rebuildOnScopeChanges)
  scopeChange,
}

/// Typedef for the logging function signature
typedef WatchItLogFunction = void Function({
  String? sourceLocationOfWatch,
  required WatchItEvent eventType,
  Object? observedObject,
  Object? parentObject,

  /// For stream the value of the last event
  /// For createOnce && createOnceAsync the value of the object that was created
  Object? lastValue,
});

/// Global logging function that can be overridden by users
/// Default implementation prints to console
WatchItLogFunction? watchItLogFunction = _defaultWatchItLogFunction;

/// Default implementation of the logging function
void _defaultWatchItLogFunction({
  String? sourceLocationOfWatch,
  required WatchItEvent eventType,
  Object? observedObject,
  Object? parentObject,
  Object? lastValue,
}) {
  final location = sourceLocationOfWatch ?? 'unknown location';
  final eventTypeString = _getEventTypeString(eventType);
  final message =
      '\nWatchIt: $eventTypeString at\n\t $location \n\t by ${observedObject?.runtimeType}${parentObject != null ? ' in ${parentObject.runtimeType}' : ''}';
  // ignore: avoid_print
  print(message);
}

/// Helper function to convert WatchItEvent enum to readable string
String _getEventTypeString(WatchItEvent eventType) {
  switch (eventType) {
    case WatchItEvent.rebuild:
      return 'Rebuild was triggered';
    case WatchItEvent.handler:
      return 'Handler was called';
    case WatchItEvent.createOnce:
      return 'Create once was called';
    case WatchItEvent.createOnceAsync:
      return 'Create once async was called';
    case WatchItEvent.allReady:
      return 'All ready check was performed';
    case WatchItEvent.isReady:
      return 'Is ready check was performed';
    case WatchItEvent.scopePush:
      return 'Scope was pushed';
    case WatchItEvent.callOnce:
      return 'Call once was executed';
    case WatchItEvent.onDispose:
      return 'On dispose was called';
    case WatchItEvent.scopeChange:
      return 'Scope change was detected';
  }
}

/// An inherited widget that controls tracing behavior for WatchingWidgets in its subtree.
///
/// This widget allows you to enable or disable tracing for rebuilds and handler calls
/// for all WatchingWidgets below it in the widget tree.
///
/// Example usage:
/// ```dart
/// // Enable global subtree tracing
/// enableSubTreeTracing = true;
///
/// // Wrap your app or a specific subtree with WatchItSubTreeTraceControl
/// WatchItSubTreeTraceControl(
///   logRebuilds: true,
///   logHandlers: true,
///   includeChildWidgets: false,
///   child: MyApp(),
/// )
/// ```
class WatchItSubTreeTraceControl extends InheritedWidget {
  /// Whether to enable tracing for rebuilds in the subtree.
  final bool logRebuilds;

  /// Whether to enable tracing for handler calls in the subtree.
  final bool logHandlers;

  /// Whether to enable tracing for helper functions in the subtree.
  final bool logHelperFunctions;

  const WatchItSubTreeTraceControl({
    super.key,
    required this.logRebuilds,
    required this.logHandlers,
    required this.logHelperFunctions,
    required super.child,
  });

  /// Retrieves the nearest [WatchItSubTreeTraceControl] from the given [context].
  ///
  /// Returns `null` if no [WatchItSubTreeTraceControl] is found in the widget tree.
  static WatchItSubTreeTraceControl? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WatchItSubTreeTraceControl>();
  }

  /// Retrieves the nearest [WatchItSubTreeTraceControl] from the given [context].
  ///
  /// Throws a [FlutterError] if no [WatchItSubTreeTraceControl] is found in the widget tree.
  static WatchItSubTreeTraceControl of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null,
        'No WatchItSubTreeTraceControl found in the widget tree.');
    return result!;
  }

  @override
  bool updateShouldNotify(WatchItSubTreeTraceControl oldWidget) {
    return logRebuilds != oldWidget.logRebuilds ||
        logHandlers != oldWidget.logHandlers ||
        logHelperFunctions != oldWidget.logHelperFunctions;
  }
}
