// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

/// A per-entity manager as it would be created by `registerCachedFactoryParam`
/// (e.g. one manager per station id).
class Manager extends ChangeNotifier {
  final String id;
  final ValueNotifier<String> notifier;
  final StreamController<String> streamController =
      StreamController<String>.broadcast();
  final Completer<String> completer = Completer<String>();
  late final Future<String> future = completer.future;
  String property;

  Manager(this.id)
      : notifier = ValueNotifier('${id}_init'),
        property = '${id}_prop';

  Stream<String> get stream => streamController.stream;

  void setProperty(String value) {
    property = value;
    notifyListeners();
  }
}

/// keeps the created managers alive and addressable by id so the tests are
/// independent of when the weak reference inside get_it gets collected
final managers = <String, Manager>{};

void registerManagerFactory() {
  GetIt.I.registerCachedFactoryParam<Manager, String, void>(
    (id, _) => managers.putIfAbsent(id, () => Manager(id)),
  );
}

int selectorCallCount = 0;
final handlerValues = <Object?>[];
int buildCount = 0;

late String currentParam;
late StateSetter _setHostState;

/// hosts a widget under test whose `param` can be changed from outside
Future<void> pumpHost(
  WidgetTester tester,
  Widget Function(String param) builder,
) {
  return tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: StatefulBuilder(
      builder: (context, setState) {
        _setHostState = setState;
        return builder(currentParam);
      },
    ),
  ));
}

Future<void> switchParam(WidgetTester tester, String param) async {
  _setHostState(() => currentParam = param);
  await tester.pump();
}

/// rebuilds the host without changing anything
Future<void> rebuildHost(WidgetTester tester) async {
  _setHostState(() {});
  await tester.pump();
}

/// Stream events and Future completions are delivered in a microtask, so the
/// rebuild they trigger only shows up after a second pump
Future<void> pumpTwice(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

class WatchValueWidget extends StatelessWidget with WatchItMixin {
  final String param;
  const WatchValueWidget({super.key, required this.param});

  @override
  Widget build(BuildContext context) {
    buildCount++;
    final value = watchValue((Manager m) {
      selectorCallCount++;
      return m.notifier;
    }, param1: param);
    return Text(value);
  }
}

class WatchPropertyValueWidget extends StatelessWidget with WatchItMixin {
  final String param;
  const WatchPropertyValueWidget({super.key, required this.param});

  @override
  Widget build(BuildContext context) {
    buildCount++;
    final value = watchPropertyValue((Manager m) => m.property, param1: param);
    return Text(value);
  }
}

class WatchItWidget extends StatelessWidget with WatchItMixin {
  final String param;
  const WatchItWidget({super.key, required this.param});

  @override
  Widget build(BuildContext context) {
    buildCount++;
    final manager = watchIt<Manager>(param1: param);
    return Text(manager.property);
  }
}

class WatchStreamWidget extends StatelessWidget with WatchItMixin {
  final String param;
  const WatchStreamWidget({super.key, required this.param});

  @override
  Widget build(BuildContext context) {
    buildCount++;
    final snapshot = watchStream((Manager m) {
      selectorCallCount++;
      return m.stream;
    }, initialValue: 'initial', param1: param);
    return Text(snapshot.data ?? 'null');
  }
}

class WatchFutureWidget extends StatelessWidget with WatchItMixin {
  final String param;
  const WatchFutureWidget({super.key, required this.param});

  @override
  Widget build(BuildContext context) {
    buildCount++;
    final snapshot = watchFuture((Manager m) {
      selectorCallCount++;
      return m.future;
    }, initialValue: 'initial', param1: param);
    return Text(snapshot.data ?? 'null');
  }
}

class RegisterHandlerWidget extends StatelessWidget with WatchItMixin {
  final String param;
  const RegisterHandlerWidget({super.key, required this.param});

  @override
  Widget build(BuildContext context) {
    registerHandler(
      select: (Manager m) {
        selectorCallCount++;
        return m.notifier;
      },
      handler: (context, value, cancel) => handlerValues.add(value),
      param1: param,
    );
    return const Text('handler');
  }
}

class RegisterChangeNotifierHandlerWidget extends StatelessWidget
    with WatchItMixin {
  final String param;
  const RegisterChangeNotifierHandlerWidget({super.key, required this.param});

  @override
  Widget build(BuildContext context) {
    registerChangeNotifierHandler<Manager>(
      handler: (context, manager, cancel) =>
          handlerValues.add(manager.property),
      param1: param,
    );
    return const Text('handler');
  }
}

class RegisterStreamHandlerWidget extends StatelessWidget with WatchItMixin {
  final String param;
  const RegisterStreamHandlerWidget({super.key, required this.param});

  @override
  Widget build(BuildContext context) {
    registerStreamHandler(
      select: (Manager m) {
        selectorCallCount++;
        return m.stream;
      },
      handler: (context, snapshot, cancel) => handlerValues.add(snapshot.data),
      param1: param,
    );
    return const Text('handler');
  }
}

class RegisterFutureHandlerWidget extends StatelessWidget with WatchItMixin {
  final String param;
  const RegisterFutureHandlerWidget({super.key, required this.param});

  @override
  Widget build(BuildContext context) {
    registerFutureHandler(
      select: (Manager m) {
        selectorCallCount++;
        return m.future;
      },
      handler: (context, snapshot, cancel) => handlerValues.add(snapshot.data),
      param1: param,
    );
    return const Text('handler');
  }
}

/// watches a plain singleton without params - used to verify that a
/// re-registered singleton is picked up on the next build
class SingletonWatchValueWidget extends StatelessWidget with WatchItMixin {
  // not const on purpose so that a rebuild of the host reaches this widget
  // ignore: prefer_const_constructors_in_immutables
  SingletonWatchValueWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final value = watchValue((Manager m) => m.notifier);
    return Text(value);
  }
}

class ParamsWithTargetWidget extends StatelessWidget with WatchItMixin {
  final Manager target;
  const ParamsWithTargetWidget({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    final value = watchPropertyValue((Manager m) => m.property,
        target: target, param1: 'x');
    return Text(value);
  }
}

void main() {
  setUp(() async {
    await GetIt.I.reset();
    managers.clear();
    selectorCallCount = 0;
    handlerValues.clear();
    buildCount = 0;
    currentParam = 'A';
  });

  group('cached factory params - rebuild functions', () {
    testWidgets('watchValue switches to the new instance when param changes',
        (tester) async {
      registerManagerFactory();

      await pumpHost(tester, (param) => WatchValueWidget(param: param));
      expect(find.text('A_init'), findsOneWidget);
      expect(selectorCallCount, 1);

      // same param -> same instance -> fast path, selector not called again
      await rebuildHost(tester);
      expect(selectorCallCount, 1);
      expect(identical(GetIt.I<Manager>(param1: 'A'), managers['A']), isTrue);

      managers['A']!.notifier.value = 'A_updated';
      await tester.pump();
      expect(find.text('A_updated'), findsOneWidget);

      await switchParam(tester, 'B');
      expect(find.text('B_init'), findsOneWidget);
      expect(selectorCallCount, 2);
      expect(managers['A']!.notifier.hasListeners, isFalse);
      expect(managers['B']!.notifier.hasListeners, isTrue);

      // the old instance no longer triggers rebuilds
      final buildsBefore = buildCount;
      managers['A']!.notifier.value = 'A_ignored';
      await tester.pump();
      expect(buildCount, buildsBefore);
      expect(find.text('B_init'), findsOneWidget);

      managers['B']!.notifier.value = 'B_updated';
      await tester.pump();
      expect(find.text('B_updated'), findsOneWidget);
    });

    testWidgets(
        'watchPropertyValue switches to the new instance when param changes',
        (tester) async {
      registerManagerFactory();

      await pumpHost(tester, (param) => WatchPropertyValueWidget(param: param));
      expect(find.text('A_prop'), findsOneWidget);

      managers['A']!.setProperty('A_changed');
      await tester.pump();
      expect(find.text('A_changed'), findsOneWidget);

      await switchParam(tester, 'B');
      expect(find.text('B_prop'), findsOneWidget);
      expect(managers['A']!.hasListeners, isFalse);
      expect(managers['B']!.hasListeners, isTrue);

      managers['B']!.setProperty('B_changed');
      await tester.pump();
      expect(find.text('B_changed'), findsOneWidget);

      // property value unchanged -> no rebuild
      final buildsBefore = buildCount;
      managers['B']!.notifyListeners();
      await tester.pump();
      expect(buildCount, buildsBefore);
    });

    testWidgets('watchIt switches to the new instance when param changes',
        (tester) async {
      registerManagerFactory();

      await pumpHost(tester, (param) => WatchItWidget(param: param));
      expect(find.text('A_prop'), findsOneWidget);

      await switchParam(tester, 'B');
      expect(find.text('B_prop'), findsOneWidget);
      expect(managers['A']!.hasListeners, isFalse);
      expect(managers['B']!.hasListeners, isTrue);

      managers['B']!.setProperty('B_changed');
      await tester.pump();
      expect(find.text('B_changed'), findsOneWidget);
    });

    testWidgets('watchStream re-subscribes when param changes', (tester) async {
      registerManagerFactory();

      await pumpHost(tester, (param) => WatchStreamWidget(param: param));
      expect(find.text('initial'), findsOneWidget);
      expect(selectorCallCount, 1);

      await rebuildHost(tester);
      expect(selectorCallCount, 1);

      managers['A']!.streamController.add('A_1');
      await pumpTwice(tester);
      expect(find.text('A_1'), findsOneWidget);

      await switchParam(tester, 'B');
      expect(selectorCallCount, 2);
      expect(managers['A']!.streamController.hasListener, isFalse);
      expect(managers['B']!.streamController.hasListener, isTrue);
      // preserveState keeps the last value until the new stream emits
      expect(find.text('A_1'), findsOneWidget);

      managers['A']!.streamController.add('A_2');
      await pumpTwice(tester);
      expect(find.text('A_1'), findsOneWidget);

      managers['B']!.streamController.add('B_1');
      await pumpTwice(tester);
      expect(find.text('B_1'), findsOneWidget);
    });

    testWidgets('watchFuture observes the new Future when param changes',
        (tester) async {
      registerManagerFactory();

      await pumpHost(tester, (param) => WatchFutureWidget(param: param));
      expect(find.text('initial'), findsOneWidget);
      expect(selectorCallCount, 1);

      await rebuildHost(tester);
      expect(selectorCallCount, 1);

      await switchParam(tester, 'B');
      expect(selectorCallCount, 2);

      // completion of the previous instance's Future is ignored
      managers['A']!.completer.complete('A_done');
      await pumpTwice(tester);
      expect(find.text('initial'), findsOneWidget);

      managers['B']!.completer.complete('B_done');
      await pumpTwice(tester);
      expect(find.text('B_done'), findsOneWidget);
    });
  });

  group('cached factory params - handlers', () {
    testWidgets('registerHandler only receives updates from the new instance',
        (tester) async {
      registerManagerFactory();

      await pumpHost(tester, (param) => RegisterHandlerWidget(param: param));
      expect(handlerValues, isEmpty);
      expect(selectorCallCount, 1);

      managers['A']!.notifier.value = 'A_1';
      await tester.pump();
      expect(handlerValues, ['A_1']);

      await switchParam(tester, 'B');
      // the switch itself must not call the handler
      expect(handlerValues, ['A_1']);
      expect(selectorCallCount, 2);
      expect(managers['A']!.notifier.hasListeners, isFalse);
      expect(managers['B']!.notifier.hasListeners, isTrue);

      managers['A']!.notifier.value = 'A_2';
      managers['B']!.notifier.value = 'B_1';
      await tester.pump();
      expect(handlerValues, ['A_1', 'B_1']);
    });

    testWidgets(
        'registerChangeNotifierHandler only receives updates from the new instance',
        (tester) async {
      registerManagerFactory();

      await pumpHost(
          tester, (param) => RegisterChangeNotifierHandlerWidget(param: param));

      managers['A']!.setProperty('A_1');
      await tester.pump();
      expect(handlerValues, ['A_1']);

      await switchParam(tester, 'B');
      expect(handlerValues, ['A_1']);
      expect(managers['A']!.hasListeners, isFalse);
      expect(managers['B']!.hasListeners, isTrue);

      managers['A']!.setProperty('A_2');
      managers['B']!.setProperty('B_1');
      await tester.pump();
      expect(handlerValues, ['A_1', 'B_1']);
    });

    testWidgets(
        'registerStreamHandler only receives events from the new instance',
        (tester) async {
      registerManagerFactory();

      await pumpHost(
          tester, (param) => RegisterStreamHandlerWidget(param: param));
      expect(selectorCallCount, 1);

      managers['A']!.streamController.add('A_1');
      await pumpTwice(tester);
      expect(handlerValues, ['A_1']);

      await switchParam(tester, 'B');
      expect(handlerValues, ['A_1']);
      expect(selectorCallCount, 2);
      expect(managers['A']!.streamController.hasListener, isFalse);
      expect(managers['B']!.streamController.hasListener, isTrue);

      managers['A']!.streamController.add('A_2');
      managers['B']!.streamController.add('B_1');
      await pumpTwice(tester);
      expect(handlerValues, ['A_1', 'B_1']);
    });

    testWidgets(
        'registerFutureHandler only reacts to the new instance\'s Future',
        (tester) async {
      registerManagerFactory();

      await pumpHost(
          tester, (param) => RegisterFutureHandlerWidget(param: param));
      expect(selectorCallCount, 1);

      await switchParam(tester, 'B');
      expect(selectorCallCount, 2);
      expect(handlerValues, isEmpty);

      managers['A']!.completer.complete('A_done');
      await pumpTwice(tester);
      expect(handlerValues, isEmpty);

      managers['B']!.completer.complete('B_done');
      await pumpTwice(tester);
      expect(handlerValues, ['B_done']);
    });
  });

  group('parent identity without params', () {
    testWidgets(
        'watchValue switches to a re-registered singleton on the next build',
        (tester) async {
      final first = Manager('first');
      final second = Manager('second');
      GetIt.I.allowReassignment = true;
      GetIt.I.registerSingleton<Manager>(first);

      await pumpHost(tester, (_) => SingletonWatchValueWidget());
      expect(find.text('first_init'), findsOneWidget);

      GetIt.I.registerSingleton<Manager>(second);
      await rebuildHost(tester);
      expect(find.text('second_init'), findsOneWidget);
      expect(first.notifier.hasListeners, isFalse);
      expect(second.notifier.hasListeners, isTrue);

      second.notifier.value = 'second_updated';
      await tester.pump();
      expect(find.text('second_updated'), findsOneWidget);
    });
  });

  group('debug asserts', () {
    testWidgets('watching a plain factory throws a StateError', (tester) async {
      GetIt.I.registerFactory<Manager>(() => Manager('factory'));

      await pumpHost(tester, (_) => SingletonWatchValueWidget());

      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets('passing params for a non cached-factory registration throws',
        (tester) async {
      GetIt.I.registerLazySingleton<Manager>(() => Manager('lazy'));

      await pumpHost(tester, (param) => WatchValueWidget(param: param));

      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets('combining params with target throws', (tester) async {
      await pumpHost(
          tester, (_) => ParamsWithTargetWidget(target: Manager('local')));

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('passing params for a cached factory without params throws',
        (tester) async {
      GetIt.I.registerCachedFactory<Manager>(() => Manager('cached'));

      await pumpHost(tester, (param) => WatchValueWidget(param: param));

      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets('cached factory without params is still allowed',
        (tester) async {
      GetIt.I.registerCachedFactory<Manager>(() => Manager('cached'));

      await pumpHost(tester, (_) => SingletonWatchValueWidget());

      expect(tester.takeException(), isNull);
      expect(find.text('cached_init'), findsOneWidget);
    });
  });
}
