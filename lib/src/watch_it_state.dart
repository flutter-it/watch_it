part of 'watch_it.dart';

String _getSourceLocation() {
  final trace = StackTrace.current;
  final lines = trace.toString().split('\n');
  final indexOfWatchItElement =
      lines.indexWhere((line) => line.contains('WatchItElement'));

  /// this should be the line that contains the name of widget that uses the watch
  return lines[indexOfWatchItElement - 2];
}

class _WatchEntry<TObservedObject, TValue> {
  TObservedObject observedObject;
  VoidCallback? notificationHandler;
  StreamSubscription? subscription;
  final void Function(_WatchEntry entry)? _dispose;
  TValue? lastValue;
  bool isHandlerWatch;
  TValue? Function(TObservedObject)? selector;
  bool handlerWasCalled = false;
  Object? parentObject;
  String? sourceLocationOfWatch;
  WatchItEvent? eventType;

  Object? activeCallbackIdentity;
  _WatchEntry(
      {this.notificationHandler,
      this.subscription,
      this.selector,
      required void Function(_WatchEntry entry)? dispose,
      this.lastValue,
      this.isHandlerWatch = false,
      required this.observedObject,
      this.parentObject,
      this.eventType,
      bool shouldTrace = false})
      : _dispose = dispose {
    assert(() {
      if (shouldTrace) {
        sourceLocationOfWatch = _getSourceLocation();
      }
      return true;
    }());
  }
  void dispose() {
    _dispose?.call(this);
  }

  void _logWatchItEvent() {
    final eventTypeToLog = eventType ??
        (isHandlerWatch ? WatchItEvent.handler : WatchItEvent.rebuild);
    watchItLogFunction?.call(
      sourceLocationOfWatch: sourceLocationOfWatch,
      eventType: eventTypeToLog,
      observedObject: observedObject,
      parentObject: parentObject,
    );
  }

  bool watchesTheSameAndNotHandler(_WatchEntry entry) {
    // we can't distinguish properties of simple types from each others
    // so we allow multiple watches on them
    if (isHandlerWatch) return false;
    if (entry.observedObject != null) {
      if (entry.observedObject == observedObject) {
        return true;
      }
      return false;
    }
    return false;
  }
}

class _WatchItState {
  Element? _element;

  final _watchList = <_WatchEntry>[];
  int? currentWatchIndex;

  bool _logRebuilds = false;
  bool _logHandlers = false;
  bool _logHelperFunctions = false;

  /// Cached allReady future from get_it (source)
  Future<void>? _cachedAllReadySourceFuture;

  /// Cached bool-wrapped allReady future for identity checks
  Future<bool>? _cachedAllReadyFuture;

  void enableTracing(
      {bool logRebuilds = true,
      bool logHandlers = true,
      bool logHelperFunctions = true}) {
    _logRebuilds = logRebuilds;
    _logHandlers = logHandlers;
    _logHelperFunctions = logHelperFunctions;
  }

  static CustomValueNotifier<bool?>? onScopeChanged;

  void _markNeedsBuild(_WatchEntry? watch) {
    if (_element != null) {
      if (_logRebuilds) {
        watch?._logWatchItEvent();
      }
      _element!.markNeedsBuild();
    }
  }

  // ignore: use_setters_to_change_properties
  void init(Element element) {
    _element = element;

    /// prepare infrastructure to observe scope changes
    if (onScopeChanged == null) {
      onScopeChanged ??=
          CustomValueNotifier(null, mode: CustomNotifierMode.manual);
      GetIt.I.onScopeChanged = (pushed) {
        onScopeChanged!.value = pushed;
        onScopeChanged!.notifyListeners();
      };
    }
  }

  /// Check for WatchItSubTreeTraceControl in the widget tree and apply its settings
  void _checkSubTreeTracing() {
    if (_element == null) return;

    // Use the proper InheritedWidget access pattern
    final traceControl = WatchItSubTreeTraceControl.maybeOf(_element!);
    if (traceControl != null) {
      _logRebuilds = traceControl.logRebuilds;
      _logHandlers = traceControl.logHandlers;
      _logHelperFunctions = traceControl.logHelperFunctions;
    } else {
      // If no WatchItSubTreeTraceControl found, disable tracing
      _logRebuilds = false;
      _logHandlers = false;
      _logHelperFunctions = false;
    }
  }

  void resetCurrentWatch() {
    /// Check for WatchItSubTreeTraceControl in the widget tree if global tracing is enabled
    if (enableSubTreeTracing) {
      _checkSubTreeTracing();
    }
    // print('resetCurrentWatch');
    currentWatchIndex = _watchList.isNotEmpty ? 0 : null;
  }

  /// if _getWatch returns null it means this is either the very first or the las watch
  /// in this list.
  /// Performs type checking to catch watch ordering violations early with helpful error messages.
  _WatchEntry<T, V>? _getWatch<T, V>() {
    if (currentWatchIndex != null) {
      assert(_watchList.length > currentWatchIndex!);
      final result = _watchList[currentWatchIndex!];

      // Type check with helpful error message for watch ordering violations
      try {
        final typedResult = result as _WatchEntry<T, V>;
        currentWatchIndex = currentWatchIndex! + 1;
        if (currentWatchIndex! == _watchList.length) {
          currentWatchIndex = null;
        }
        return typedResult;
      } on TypeError catch (_) {
        // Build error message with source location if available
        final buffer = StringBuffer('Watch ordering violation detected!\n\n');

        buffer.writeln(
            'You have conditional watch calls (inside if/switch statements) that are');
        buffer.writeln(
            'causing watch_it to retrieve the wrong objects on rebuild.');

        // Add source location if tracing was enabled
        if (result.sourceLocationOfWatch != null) {
          buffer.writeln('\nConflicting watch entry was created at:');
          buffer.writeln(result.sourceLocationOfWatch);
          buffer.writeln('\nLook for a watch statement that returns type: $V');
        }

        buffer.writeln(
            '\nFix: Move ALL conditional watch calls to the END of your build method.');
        buffer.writeln('Only the LAST watch call can be conditional.');
        buffer.writeln('\nExample - BAD:');
        buffer.writeln('  watch(model);');
        buffer.writeln('  if (condition) { watch(optional); }  // ← Problem!');
        buffer.writeln(
            '  watchValue((M m) => m.property);     // ← Gets wrong type');
        buffer.writeln('\nExample - GOOD:');
        buffer.writeln('  watch(model);');
        buffer.writeln('  watchValue((M m) => m.property);');
        buffer.writeln(
            '  if (condition) { watch(optional); }  // ← At the end: OK');

        // Suggest enabling tracing if source location wasn't available
        if (result.sourceLocationOfWatch == null) {
          buffer.writeln(
              '\nTip: Call enableTracing() in your build method to see exact source locations.');
        }

        buffer.writeln('\nWidget: ${_element?.widget.runtimeType}');

        throw StateError(buffer.toString());
      }
    }
    return null;
  }

  /// We don't allow multiple watches on the same object but we allow multiple handler
  /// that can be registered to the same observable object
  void _appendWatch<V>(_WatchEntry entry,
      {bool allowMultipleSubscribers = false}) {
    if (!entry.isHandlerWatch && !allowMultipleSubscribers) {
      for (final watch in _watchList) {
        if (watch.watchesTheSameAndNotHandler(entry)) {
          throw ArgumentError('This Object is already watched by watch_it');
        }
      }
    }
    _watchList.add(entry);
    currentWatchIndex = null;
  }

  /// [handler] and [executeImmediately] are used by [registerHandler]
  /// Returns the observable being watched
  Listenable watchListenable<T, R>({
    required T parentOrListenable,
    ValueListenable<R> Function(T)? selector,
    bool allowObservableChange = true,
    void Function(BuildContext context, R newValue, void Function() dispose)?
        handler,
    bool executeImmediately = false,
  }) {
    var watch = _getWatch<Listenable, R>();

    Listenable actualTarget;

    if (watch != null) {
      if (!allowObservableChange && selector != null) {
        // FAST PATH: Don't call selector, reuse cached observable
        return watch.observedObject;
      }

      // Get the observable
      if (selector != null) {
        actualTarget = selector(parentOrListenable);
      } else {
        // No selector - parentOrListenable is the Listenable
        // Type already validated in public API
        actualTarget = parentOrListenable as Listenable;
      }

      if (actualTarget == watch.observedObject) {
        return watch.observedObject;
      }

      // Observable changed
      if (!allowObservableChange) {
        throw StateError(
            'watchListenable detected an observable change but allowObservableChange is false.\n'
            '\n'
            'This means you are either:\n'
            '1. Creating a new observable on every build (e.g., listenable.map(...))\n'
            '2. Dynamically switching observables (e.g., condition ? obsA : obsB)\n'
            '\n'
            'Solutions:\n'
            '1. Store the observable in your model/widget to use the same instance\n'
            '2. Set allowObservableChange: true to explicitly allow switching\n'
            '\n'
            'Observable type: ${actualTarget.runtimeType}\n'
            'Widget: ${_element?.widget.runtimeType}\n');
      }
      watch.dispose();
    } else {
      // First build - get the observable
      if (selector != null) {
        actualTarget = selector(parentOrListenable);
      } else {
        // Type already validated in public API
        actualTarget = parentOrListenable as Listenable;
      }

      watch = _WatchEntry(
        observedObject: actualTarget,
        dispose: (x) => x.observedObject!.removeListener(
          x.notificationHandler!,
        ),
        isHandlerWatch: handler != null,
        parentObject: parentOrListenable,
        shouldTrace: _logRebuilds || _logHandlers,
      );
      _appendWatch(watch);
    }

    // ignore: prefer_function_declarations_over_variables
    final internalHandler = () {
      if (_element == null) {
        /// it seems it can happen that a handler is still
        /// registered even after dispose was called
        /// to protect against this we just
        return;
      }
      if (handler != null) {
        if (actualTarget is ValueListenable) {
          if (_logHandlers) {
            watch?._logWatchItEvent();
          }
          handler(_element!, actualTarget.value, watch!.dispose);
        } else {
          if (_logHandlers) {
            watch?._logWatchItEvent();
          }
          handler(_element!, actualTarget as R, watch!.dispose);
        }
      } else {
        _markNeedsBuild(watch);
      }
    };
    watch.notificationHandler = internalHandler;
    watch.observedObject = actualTarget;

    actualTarget.addListener(internalHandler);
    if (handler != null && executeImmediately) {
      if (_element == null) {
        /// it seems it can happen that a handler is still
        /// registered even after dispose was called
        /// to protect against this we just
        return actualTarget;
      }
      if (actualTarget is ValueListenable) {
        if (_logHandlers) {
          watch._logWatchItEvent();
        }
        handler(_element!, actualTarget.value, watch.dispose);
      } else {
        if (_logHandlers) {
          watch._logWatchItEvent();
        }
        handler(_element!, actualTarget as R, watch.dispose);
      }
    }
    return actualTarget;
  }

  watchPropertyValue<T extends Listenable, R>({
    required T listenable,
    required R Function(T) only,
    Object? parentObject,
  }) {
    var watch = _getWatch<Listenable, R>();

    if (watch != null) {
      if (listenable != watch.observedObject) {
        /// the target object has changed probably by passing another instance
        /// so we have to unregister our handler and subscribe anew
        watch.dispose();
      } else {
        // if the listenable is the same we can directly return
        return;
      }
    } else {
      watch = _WatchEntry<T, R>(
          observedObject: listenable,
          selector: only,
          lastValue: only(listenable),
          dispose: (x) =>
              x.observedObject!.removeListener(x.notificationHandler!),
          parentObject: parentObject,
          shouldTrace: _logRebuilds || _logHandlers);
      _appendWatch(watch, allowMultipleSubscribers: true);
      // we have to set `allowMultipleSubscribers=true` because we can't differentiate
      // one selector function from another.
    }

    handler() {
      if (_element == null) {
        /// it seems it can happen that a handler is still
        /// registered even after dispose was called
        /// to protect against this we just
        return;
      }
      final newValue = only(listenable);
      if (watch!.lastValue != newValue) {
        _markNeedsBuild(watch);
        watch.lastValue = newValue;
      }
    }

    watch.notificationHandler = handler;

    listenable.addListener(handler);
  }

  AsyncSnapshot<R> watchStream<T, R>({
    required T parentOrStream,
    required R? initialValue,
    String? instanceName,
    bool preserveState = true,
    void Function(BuildContext context, AsyncSnapshot<R> snapshot,
            void Function() cancel)?
        handler,
    Stream<R> Function(T)? selector,
    bool allowStreamChange = true,
  }) {
    var watch = _getWatch<Stream<R>, AsyncSnapshot<R?>>();
    Stream<R> actualStream;

    if (watch != null) {
      if (!allowStreamChange && selector != null) {
        // FAST PATH: Don't call selector, reuse cached stream
        actualStream = watch.observedObject;

        /// Only if this isn't used to register a handler
        ///  still the same stream so we can directly return last value
        if (handler == null) {
          assert(watch.lastValue != null && !watch.lastValue!.hasError);
          return AsyncSnapshot<R>.withData(
              watch.lastValue!.connectionState, watch.lastValue!.data as R);
        } else {
          return AsyncSnapshot<R>.nothing();
        }
      } else {
        // SLOW PATH: Call selector to get potentially new stream
        if (selector != null) {
          actualStream = selector(parentOrStream);
        } else {
          // No selector - parentOrStream is the Stream
          // Type already validated in public API
          actualStream = parentOrStream as Stream<R>;
        }

        if (actualStream == watch.observedObject) {
          /// Only if this isn't used to register a handler
          ///  still the same stream so we can directly return last value
          if (handler == null) {
            assert(watch.lastValue != null && !watch.lastValue!.hasError);
            return AsyncSnapshot<R>.withData(
                watch.lastValue!.connectionState, watch.lastValue!.data as R);
          } else {
            return AsyncSnapshot<R>.nothing();
          }
        } else {
          /// select returned a different value than the last time
          /// so we have to unregister our handler and subscribe anew
          watch.dispose();
          initialValue = preserveState && watch.lastValue!.hasData
              ? watch.lastValue!.data
              : initialValue;
        }
      }
    } else {
      // First build - get the stream
      if (selector != null) {
        actualStream = selector(parentOrStream);
      } else {
        // No selector - parentOrStream is the Stream
        // Type already validated in public API
        actualStream = parentOrStream as Stream<R>;
      }
      watch = _WatchEntry<Stream<R>, AsyncSnapshot<R?>>(
        dispose: (x) => x.subscription!.cancel(),
        observedObject: actualStream,
        isHandlerWatch: handler != null,
        parentObject: parentOrStream,
        shouldTrace: _logRebuilds || _logHandlers,
      );
      _appendWatch(
        watch,
      );
    }

    // ignore: cancel_subscriptions
    final subscription = actualStream.listen(
      (x) {
        if (_element == null) {
          /// it seems it can happen that a handler is still
          /// registered even after dispose was called
          /// to protect against this we just
          return;
        }
        if (handler != null) {
          if (_logHandlers) {
            watch?._logWatchItEvent();
          }
          handler(_element!, AsyncSnapshot.withData(ConnectionState.active, x),
              watch!.dispose);
        } else {
          watch!.lastValue = AsyncSnapshot.withData(ConnectionState.active, x);
          _markNeedsBuild(watch);
        }
      },
      onError: (Object error) {
        if (_element == null) {
          /// it seems it can happen that a handler is still
          /// registered even after dispose was called
          /// to protect against this we just
          return;
        }
        if (handler != null) {
          if (_logHandlers) {
            watch?._logWatchItEvent();
          }
          handler(
              _element!,
              AsyncSnapshot.withError(ConnectionState.active, error),
              watch!.dispose);
        }
        watch!.lastValue =
            AsyncSnapshot.withError(ConnectionState.active, error);
        _markNeedsBuild(watch);
      },
    );
    watch.subscription = subscription;
    watch.observedObject = actualStream;
    watch.lastValue =
        AsyncSnapshot<R?>.withData(ConnectionState.waiting, initialValue);

    if (handler != null) {
      if (_element == null) {
        /// it seems it can happen that a handler is still
        /// registered even after dispose was called
        /// to protect against this we just
        return AsyncSnapshot<R>.nothing();
      }
      if (initialValue != null) {
        if (_logHandlers) {
          watch._logWatchItEvent();
        }
        handler(
            _element!,
            AsyncSnapshot.withData(ConnectionState.waiting, initialValue),
            watch.dispose);
      }
      return AsyncSnapshot<R>.nothing();
    }
    assert(watch.lastValue != null && !watch.lastValue!.hasError);
    if (watch.lastValue!.data is! R &&
        watch.lastValue!.connectionState == ConnectionState.waiting) {
      return AsyncSnapshot<R>.waiting();
    }

    return AsyncSnapshot<R>.withData(
        watch.lastValue!.connectionState, watch.lastValue!.data as R);
  }

  void registerStreamHandler<T, R>(
    T parentOrStream,
    void Function(
      BuildContext context,
      AsyncSnapshot<R> snapshot,
      void Function() cancel,
    ) handler, {
    R? initialValue,
    String? instanceName,
    Stream<R> Function(T)? selector,
    bool allowStreamChange = true,
  }) {
    watchStream<T, R>(
        parentOrStream: parentOrStream,
        initialValue: initialValue,
        instanceName: instanceName,
        handler: handler,
        selector: selector,
        allowStreamChange: allowStreamChange);
  }

  /// Helper to call handler if conditions are met
  /// Returns true if handler was called
  bool _callFutureHandlerIfNeeded<R>(
    void Function(BuildContext context, AsyncSnapshot<R?> snapshot,
            void Function() cancel)?
        handler,
    _WatchEntry<Future<R>, AsyncSnapshot<R>> watch,
    bool callHandlerOnlyOnce,
  ) {
    if (handler != null &&
        _element != null &&
        (!watch.handlerWasCalled || !callHandlerOnlyOnce)) {
      if (_logHandlers) {
        watch._logWatchItEvent();
      }
      handler(_element!, watch.lastValue!, watch.dispose);
      watch.handlerWasCalled = true;
      return true;
    }
    return false;
  }

  /// this function is used to implement several others
  /// therefore not all parameters will be always used
  /// [initialValueProvider] can return an initial value that is returned
  /// as long the Future has not completed
  /// [preserveState] if select returns a different value than on the last
  /// build this determines if for the new subscription [initialValueProvider()] or
  /// the last received value should be used as initialValue
  /// [executeImmediately] if the handler should be directly called.
  /// if the Future has completed [handler] will be called every time until
  /// the handler calls `cancel` or the widget is destroyed
  /// [futureProvider] overrides a looked up future. Used to implement [allReady]
  /// We use provider functions here so that [registerFutureHandler] ensure
  /// that they are only called once.
  AsyncSnapshot<R> registerFutureHandler<T, R>(
      {T? parentOrFuture,
      void Function(BuildContext context, AsyncSnapshot<R?> snapshot,
              void Function() cancel)?
          handler,
      required bool allowMultipleSubscribers,
      required R Function() initialValueProvider,
      bool preserveState = true,
      bool executeImmediately = false,
      Future<R> Function()? futureProvider,
      String? instanceName,
      bool callHandlerOnlyOnce = false,
      void Function(R value)? dispose,
      bool isCreateOnceAsync = false,
      Future<R> Function(T)? selector,
      bool allowFutureChange = true}) {
    var watch = _getWatch<Future<R>, AsyncSnapshot<R>>();

    Future<R>? future;

    R? initialValue;
    if (watch != null) {
      if (!allowFutureChange && selector != null && futureProvider == null) {
        // FAST PATH: Don't call selector, reuse cached future
        future = watch.observedObject;

        ///  still the same Future so we can directly return last value
        _callFutureHandlerIfNeeded(handler, watch, callHandlerOnlyOnce);
        return watch.lastValue!;
      } else if (futureProvider != null) {
        ///  still the same Future so we can directly return last value
        /// in case that we got a futureProvider we always keep the first
        /// returned Future
        /// and call the Handler again as the state hasn't changed
        _callFutureHandlerIfNeeded(handler, watch, callHandlerOnlyOnce);
        return watch.lastValue!;
      } else {
        // Get the future from selector or parentOrFuture
        if (selector != null) {
          assert(parentOrFuture != null,
              'parentOrFuture must not be null when using a selector');
          future = selector(parentOrFuture as T);
        } else {
          // Type already validated in public API
          future = parentOrFuture as Future<R>;
        }

        // Check if the Future identity has changed
        if (future == watch.observedObject) {
          ///  still the same Future so we can directly return last value
          /// and call the Handler again as the state hasn't changed
          _callFutureHandlerIfNeeded(handler, watch, callHandlerOnlyOnce);
          return watch.lastValue!;
        } else {
          /// Future identity changed
          /// so we have to unregister out handler and subscribe anew
          watch.dispose();
          initialValue = preserveState && watch.lastValue!.hasData
              ? watch.lastValue!.data
              : initialValueProvider.call();
        }
      }
    } else {
      // First build - get the future
      if (futureProvider != null) {
        future = futureProvider();
      } else if (selector != null) {
        assert(parentOrFuture != null,
            'parentOrFuture must not be null when using a selector');
        future = selector(parentOrFuture as T);
      } else {
        // Type already validated in public API
        future = parentOrFuture as Future<R>;
      }

      watch = _WatchEntry<Future<R>, AsyncSnapshot<R>>(
          observedObject: future,
          isHandlerWatch: handler != null,
          dispose: (x) {
            x.activeCallbackIdentity = null;
            if (dispose != null && x.lastValue != null) {
              dispose(x.lastValue!.data as R);
            }
          },
          eventType: isCreateOnceAsync ? WatchItEvent.createOnceAsync : null,
          parentObject: parentOrFuture,
          shouldTrace: _logRebuilds || _logHandlers);
      _appendWatch(watch, allowMultipleSubscribers: allowMultipleSubscribers);
    }
    //if no handler was passed we expect that this is a normal watchFuture
    handler ??= (context, x, cancel) => _markNeedsBuild(watch);

    /// in case of a new watch or an changing Future we do the following:
    watch.observedObject = future;

    /// by using a local variable we ensure that only the value and not the
    /// variable is captured.
    final callbackIdentity = Object();
    watch.activeCallbackIdentity = callbackIdentity;
    future.then(
      (x) {
        if (_element == null) {
          /// it seems it can happen that a handler is still
          /// registered even after dispose was called
          /// to protect against this we just
          return;
        }

        /// here we compare the captured callbackIdentity with the one that is
        /// currently stored in the watch. If they are different it means that
        /// the future isn't the same anymore and we don't have to call the handler
        if (watch!.activeCallbackIdentity == callbackIdentity) {
          // print('Future completed $x');
          // only update if Future is still valid
          watch.lastValue = AsyncSnapshot.withData(ConnectionState.done, x);
          if (watch.isHandlerWatch && _logHandlers ||
              _logRebuilds ||
              _logHelperFunctions) {
            watch._logWatchItEvent();
          }
          handler!(_element!, watch.lastValue!, watch.dispose);
          watch.handlerWasCalled = true;
        }
      },
      onError: (Object error) {
        if (_element == null) {
          /// it seems it can happen that a handler is still
          /// registered even after dispose was called
          /// to protect against this we just
          return;
        }
        if (watch!.activeCallbackIdentity == callbackIdentity) {
          // print('Future error');
          watch.lastValue =
              AsyncSnapshot.withError(ConnectionState.done, error);
          if (watch.isHandlerWatch && _logHandlers ||
              _logRebuilds ||
              _logHelperFunctions) {
            watch._logWatchItEvent();
          }
          handler!(_element!, watch.lastValue!, watch.dispose);
          watch.handlerWasCalled = true;
        }
      },
    );

    watch.lastValue = AsyncSnapshot<R>.withData(
        ConnectionState.waiting, initialValue ?? initialValueProvider.call());
    if (executeImmediately && _element != null) {
      if (watch.isHandlerWatch && _logHandlers ||
          _logRebuilds ||
          _logHelperFunctions) {
        watch._logWatchItEvent();
      }
      handler(_element!, watch.lastValue!, watch.dispose);
      watch.handlerWasCalled = true;
    }

    return watch.lastValue!;
  }

  bool _testIfDisposable(Object? d) {
    if (d == null) {
      return false;
    }
    Object? dispose;
    try {
      dispose = (d as dynamic).dispose;
      if (dispose is void Function()) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  T createOnce<T>(T Function() factoryFunc, {void Function(T value)? dispose}) {
    var watch = _getWatch<void, T>();

    if (watch == null) {
      final value = factoryFunc();
      watch = _WatchEntry(
        lastValue: value,
        observedObject: null,
        dispose: dispose != null
            ? (x) => dispose(x.lastValue!)
            : (_testIfDisposable(value)
                ? (x) {
                    (x.lastValue as dynamic).dispose();
                  }
                : (_) {
                    assert(() {
                      // ignore: avoid_print
                      print(
                          'WatchIt: Info - createOnce without a dispose function');
                      return true;
                    }());
                  }),
        eventType: WatchItEvent.createOnce,
        shouldTrace: _logRebuilds || _logHandlers,
      );
      _appendWatch(watch);
    }
    if (_logHelperFunctions) {
      watch._logWatchItEvent();
    }
    return watch.lastValue!;
  }

  AsyncSnapshot<T> createOnceAsync<T>(Future<T> Function() factoryFunc,
      {required T initialValue, void Function(T value)? dispose}) {
    return registerFutureHandler<Object?, T>(
      parentOrFuture: null,
      allowMultipleSubscribers: false,
      initialValueProvider: () => initialValue,
      futureProvider: factoryFunc,
      isCreateOnceAsync: true,
      dispose: (x) {
        if (dispose != null) {
          dispose(x);
        } else {
          if (_testIfDisposable(x)) {
            (x as dynamic).dispose();
          } else {
            assert(() {
              // ignore: avoid_print
              print(
                  'WatchIt: Info - createOnceAsync without a dispose function');
              return true;
            }());
          }
        }
      },
    );
  }

  bool allReady(
      {void Function(BuildContext context)? onReady,
      void Function(BuildContext context, Object? error)? onError,
      Duration? timeout,
      bool shouldRebuild = true,
      bool callHandlerOnlyOnce = false}) {
    if (_logHelperFunctions) {
      watchItLogFunction?.call(
        sourceLocationOfWatch: _getSourceLocation(),
        eventType: WatchItEvent.allReady,
        observedObject: null,
        parentObject: null,
      );
    }

    // Get the source future from get_it (cached by get_it)
    final sourceFuture = GetIt.I.allReady(timeout: timeout);

    // If source future changed, create new bool wrapper
    if (sourceFuture != _cachedAllReadySourceFuture) {
      _cachedAllReadySourceFuture = sourceFuture;
      _cachedAllReadyFuture = sourceFuture.then((_) => true);
    }

    final readyResult = registerFutureHandler<Object?, bool>(
      parentOrFuture: _cachedAllReadyFuture,
      handler: (context, x, dispose) {
        if (x.hasError) {
          onError?.call(context, x.error);
        } else if (x.connectionState == ConnectionState.done) {
          // Only call onReady when the future has actually completed
          onReady?.call(context);
        }
        if (shouldRebuild) {
          _markNeedsBuild(null);
        }
        // Don't dispose - keep watching for future changes (new async registrations)
      },
      allowMultipleSubscribers: false,
      allowFutureChange: true,
      preserveState: false, // Always get fresh value when future changes
      initialValueProvider: () => GetIt.I.allReadySync(),
      callHandlerOnlyOnce: callHandlerOnlyOnce,
    );
    if (readyResult.hasData) {
      return readyResult.data!;
    }
    if (readyResult.hasError && onError != null) {
      return false;
    }
    if (readyResult.error is WaitingTimeOutException) throw readyResult.error!;
    throw Exception(
        'One of your async registrations in GetIt threw an error while waiting for them to finish: \n'
        '${readyResult.error}\n Enable "break on uncaught exceptions" in your debugger to find out more.');
  }

  bool isReady<T extends Object>({
    void Function(BuildContext context)? onReady,
    void Function(BuildContext context, Object? error)? onError,
    Duration? timeout,
    String? instanceName,
    bool callHandlerOnlyOnce = false,
  }) {
    if (_logHelperFunctions) {
      watchItLogFunction?.call(
        sourceLocationOfWatch: _getSourceLocation(),
        eventType: WatchItEvent.isReady,
        observedObject: null,
        parentObject: null,
      );
    }
    final readyResult = registerFutureHandler<Object?, bool>(
      parentOrFuture: null,
      handler: (context, x, cancel) {
        if (x.hasError) {
          onError?.call(context, x.error);
        } else {
          onReady?.call(context);
        }
        _markNeedsBuild(null);
        cancel(); // we want exactly one call.
      },
      allowMultipleSubscribers: false,
      initialValueProvider: () =>
          GetIt.I.isReadySync<T>(instanceName: instanceName),

      /// as `GetIt.allReady` returns a Future<void> we convert it
      /// to a bool because if this Future completes the meaning is true.
      futureProvider: () => GetIt.I
          .isReady<T>(instanceName: instanceName, timeout: timeout)
          .then((_) => true),
      callHandlerOnlyOnce: callHandlerOnlyOnce,
    );

    if (readyResult.hasData) {
      return readyResult.data!;
    }
    if (readyResult.hasError && onError != null) {
      return false;
    }
    if (readyResult.error is WaitingTimeOutException) throw readyResult.error!;
    throw Exception(
        'The factory function of type $T of your registration in GetIt threw an error while waiting for them to finish: \n'
        '${readyResult.error}\n Enable "break on uncaught exceptions" in your debugger to find out more.');
  }

  bool _scopeWasPushed = false;
  String? _scopeName;
  static int _autoScopeCounter = 0;

  void pushScope(
      {void Function(GetIt getIt)? init,
      void Function()? dispose,
      bool isFinal = false}) {
    if (!_scopeWasPushed) {
      if (_logHelperFunctions) {
        watchItLogFunction?.call(
          sourceLocationOfWatch: _getSourceLocation(),
          eventType: WatchItEvent.scopePush,
          observedObject: null,
          parentObject: null,
        );
      }
      _scopeName = 'AutoScope: ${_autoScopeCounter++}';
      GetIt.I.pushNewScope(
          dispose: dispose,
          init: init,
          scopeName: _scopeName,
          isFinal: isFinal);
      _scopeWasPushed = true;
    }
  }

  bool _initWasCalled = false;
  void Function()? _initDispose;

  void callOnce(void Function(BuildContext context) init,
      {void Function()? dispose}) {
    _initDispose = dispose;
    if (!_initWasCalled) {
      if (_logHelperFunctions) {
        watchItLogFunction?.call(
          sourceLocationOfWatch: _getSourceLocation(),
          eventType: WatchItEvent.callOnce,
          observedObject: null,
          parentObject: null,
        );
      }
      init(_element!);
      _initWasCalled = true;
    }
  }

  bool _onceAfterBuildWasCalled = false;

  void callOnceAfterThisBuild(void Function(BuildContext context) callback) {
    if (!_onceAfterBuildWasCalled) {
      if (_logHelperFunctions) {
        watchItLogFunction?.call(
          sourceLocationOfWatch: _getSourceLocation(),
          eventType: WatchItEvent.callOnceAfterThisBuild,
          observedObject: null,
          parentObject: null,
        );
      }
      _onceAfterBuildWasCalled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if element is still mounted before calling callback
        if (_element != null) {
          callback(_element!);
        }
      });
    }
  }

  void callAfterEveryBuild(
      void Function(BuildContext context, void Function() cancel) callback) {
    var watch = _getWatch<void, bool>();

    if (watch == null) {
      // First time - create the watch entry with a cancelled flag
      watch = _WatchEntry<void, bool>(
        observedObject: null,
        lastValue: false, // false = not cancelled
        dispose: (_) {
          // Cleanup if needed
        },
        eventType: WatchItEvent.callAfterEveryBuild,
        shouldTrace: _logHelperFunctions,
      );
      _appendWatch(watch);
    }

    // Check if this callback was cancelled
    if (watch.lastValue == true) {
      // Already cancelled, don't schedule callback
      return;
    }

    if (_logHelperFunctions) {
      watch._logWatchItEvent();
    }

    // Create a cancel function that marks this watch as cancelled
    void cancelFunc() {
      watch!.lastValue = true; // Mark as cancelled
    }

    // Schedule the callback for after this frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if element is still mounted and not cancelled
      if (_element != null && watch!.lastValue != true) {
        callback(_element!, cancelFunc);
      }
    });
  }

  void Function()? _disposeFunction;
  void onDispose(void Function() dispose) {
    _disposeFunction ??= dispose;
    if (_logHelperFunctions) {
      watchItLogFunction?.call(
        sourceLocationOfWatch: _getSourceLocation(),
        eventType: WatchItEvent.onDispose,
        observedObject: null,
        parentObject: null,
      );
    }
  }

  bool? rebuildOnScopeChanges() {
    final result = onScopeChanged!.value;
    if (_logHelperFunctions && result != null) {
      watchItLogFunction?.call(
        sourceLocationOfWatch: _getSourceLocation(),
        eventType: WatchItEvent.scopeChange,
        observedObject: onScopeChanged,
        parentObject: null,
      );
    }
    watchListenable(parentOrListenable: onScopeChanged!);
    onScopeChanged!.value = null;
    return result;
  }

  void clearRegistrations() {
    // print('clearRegistration');
    for (var x in _watchList) {
      x.dispose();
    }
    _watchList.clear();
    currentWatchIndex = null;
  }

  void dispose() {
    // print('dispose');
    clearRegistrations();
    if (_scopeWasPushed) {
      GetIt.I.dropScope(_scopeName!);
    }
    _initDispose?.call();
    _disposeFunction?.call();
    _element = null; // making sure the Garbage collector can do its job
  }
}
