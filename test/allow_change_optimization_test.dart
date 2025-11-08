// Tests for allow*Change optimization (watchValue, watchStream, watchFuture)
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

/// Model that tracks selector call counts
class TestModel extends ChangeNotifier {
  ValueNotifier<String> field1 = ValueNotifier<String>('field1');
  ValueNotifier<int> rebuildTrigger = ValueNotifier<int>(0);

  final StreamController<String> _streamController =
      StreamController<String>.broadcast();
  Stream<String> get stream1 => _streamController.stream;

  final Completer<String> _futureCompleter = Completer<String>();
  Future<String> get future1 => _futureCompleter.future;

  int field1SelectorCalls = 0;
  int stream1SelectorCalls = 0;
  int future1SelectorCalls = 0;

  ValueNotifier<String> getField1() {
    field1SelectorCalls++;
    return field1;
  }

  Stream<String> getStream1() {
    stream1SelectorCalls++;
    return stream1;
  }

  Future<String> getFuture1() {
    future1SelectorCalls++;
    return future1;
  }

  void triggerRebuild() => rebuildTrigger.value++;
  void emitStreamValue(String value) => _streamController.add(value);
  void completeFuture(String value) {
    if (!_futureCompleter.isCompleted) {
      _futureCompleter.complete(value);
    }
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }
}

/// Model with switchable futures for testing Future identity changes
class SwitchableFutureModel extends ChangeNotifier {
  final Future<String> future1;
  final Future<String> future2;
  ValueNotifier<int> rebuildTrigger = ValueNotifier<int>(0);

  SwitchableFutureModel({
    required this.future1,
    required this.future2,
  });

  Future<String> getFuture(bool useFirst) {
    return useFirst ? future1 : future2;
  }

  void triggerRebuild() => rebuildTrigger.value++;
}

// Test widgets for different scenarios
class WatchValueTestWidget extends StatelessWidget with WatchItMixin {
  final bool allowObservableChange;

  const WatchValueTestWidget({super.key, this.allowObservableChange = false});

  @override
  Widget build(BuildContext context) {
    // Watch rebuildTrigger to enable rebuilds
    final trigger = watch(di<TestModel>().rebuildTrigger);

    // Test watchValue with optimization
    final value = watchValue<TestModel, String>(
      (m) => m.getField1(),
      allowObservableChange: allowObservableChange,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text(value, key: const Key('value')),
          Text(trigger.toString(), key: const Key('trigger')),
        ],
      ),
    );
  }
}

class WatchStreamTestWidget extends StatelessWidget with WatchItMixin {
  final bool allowStreamChange;

  const WatchStreamTestWidget({super.key, this.allowStreamChange = false});

  @override
  Widget build(BuildContext context) {
    // Watch rebuildTrigger to enable rebuilds
    final trigger = watch(di<TestModel>().rebuildTrigger);

    // Test watchStream with optimization
    final snapshot = watchStream<TestModel, String>(
      (m) => m.getStream1(),
      initialValue: 'initial',
      allowStreamChange: allowStreamChange,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text(snapshot.data ?? 'null', key: const Key('value')),
          Text(trigger.toString(), key: const Key('trigger')),
        ],
      ),
    );
  }
}

class WatchFutureTestWidget extends StatelessWidget with WatchItMixin {
  final bool allowFutureChange;

  const WatchFutureTestWidget({super.key, this.allowFutureChange = false});

  @override
  Widget build(BuildContext context) {
    // Watch rebuildTrigger to enable rebuilds
    final trigger = watch(di<TestModel>().rebuildTrigger);

    // Test watchFuture with optimization
    final snapshot = watchFuture<TestModel, String>(
      (m) => m.getFuture1(),
      initialValue: 'initial',
      allowFutureChange: allowFutureChange,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text(snapshot.data ?? 'null', key: const Key('value')),
          Text(trigger.toString(), key: const Key('trigger')),
        ],
      ),
    );
  }
}

class SwitchableFutureTestWidget extends WatchingStatefulWidget {
  final bool useFuture1;
  final VoidCallback onSwitch;

  const SwitchableFutureTestWidget({
    super.key,
    required this.useFuture1,
    required this.onSwitch,
  });

  @override
  State<SwitchableFutureTestWidget> createState() =>
      _SwitchableFutureTestWidgetState();
}

class _SwitchableFutureTestWidgetState
    extends State<SwitchableFutureTestWidget> {
  @override
  Widget build(BuildContext context) {
    // Watch with allowFutureChange=true to allow switching
    // Use preserveState=false so we can test that subscription actually changes
    final snapshot = watchFuture<SwitchableFutureModel, String>(
      (m) => m.getFuture(widget.useFuture1),
      initialValue: 'initial',
      allowFutureChange: true,
      preserveState: false,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text(snapshot.data ?? 'null', key: const Key('value')),
          GestureDetector(
            key: const Key('switch'),
            onTap: () {
              widget.onSwitch();
              setState(() {});
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUp(() async {
    await di.reset();
    di.registerSingleton<TestModel>(TestModel());
  });

  tearDown(() async {
    await di.reset();
  });

  group('allowObservableChange optimization (watchValue)', () {
    testWidgets('allowObservableChange: false - selector called only once',
        (tester) async {
      final model = di<TestModel>();

      await tester.pumpWidget(const WatchValueTestWidget(
        allowObservableChange: false,
      ));

      expect(model.field1SelectorCalls, 1,
          reason: 'Called once on first build');

      // Trigger rebuilds
      model.triggerRebuild();
      await tester.pump();
      expect(model.field1SelectorCalls, 1, reason: 'NOT called on rebuild');

      model.triggerRebuild();
      await tester.pump();
      expect(model.field1SelectorCalls, 1, reason: 'Still NOT called');
    });

    testWidgets('allowObservableChange: true - selector called every build',
        (tester) async {
      final model = di<TestModel>();

      await tester.pumpWidget(const WatchValueTestWidget(
        allowObservableChange: true,
      ));

      expect(model.field1SelectorCalls, 1);

      model.triggerRebuild();
      await tester.pump();
      expect(model.field1SelectorCalls, 2, reason: 'Called on rebuild');

      model.triggerRebuild();
      await tester.pump();
      expect(model.field1SelectorCalls, 3, reason: 'Called again');
    });
  });

  group('allowStreamChange optimization (watchStream)', () {
    testWidgets('allowStreamChange: false - selector called only once',
        (tester) async {
      final model = di<TestModel>();

      await tester.pumpWidget(const WatchStreamTestWidget(
        allowStreamChange: false,
      ));

      expect(model.stream1SelectorCalls, 1,
          reason: 'Called once on first build');

      // Trigger rebuilds
      model.triggerRebuild();
      await tester.pump();
      expect(model.stream1SelectorCalls, 1, reason: 'NOT called on rebuild');

      model.triggerRebuild();
      await tester.pump();
      expect(model.stream1SelectorCalls, 1, reason: 'Still NOT called');
    });

    testWidgets('allowStreamChange: true - selector called every build',
        (tester) async {
      final model = di<TestModel>();

      await tester.pumpWidget(const WatchStreamTestWidget(
        allowStreamChange: true,
      ));

      expect(model.stream1SelectorCalls, 1);

      model.triggerRebuild();
      await tester.pump();
      expect(model.stream1SelectorCalls, 2, reason: 'Called on rebuild');

      model.triggerRebuild();
      await tester.pump();
      expect(model.stream1SelectorCalls, 3, reason: 'Called again');
    });
  });

  group('allowFutureChange optimization (watchFuture)', () {
    testWidgets('allowFutureChange: false - selector called only once',
        (tester) async {
      final model = di<TestModel>();

      await tester.pumpWidget(const WatchFutureTestWidget(
        allowFutureChange: false,
      ));

      expect(model.future1SelectorCalls, 1,
          reason: 'Called once on first build');

      // Trigger rebuilds
      model.triggerRebuild();
      await tester.pump();
      expect(model.future1SelectorCalls, 1, reason: 'NOT called on rebuild');

      model.triggerRebuild();
      await tester.pump();
      expect(model.future1SelectorCalls, 1, reason: 'Still NOT called');
    });

    testWidgets('allowFutureChange: true - selector called every build',
        (tester) async {
      final model = di<TestModel>();

      await tester.pumpWidget(const WatchFutureTestWidget(
        allowFutureChange: true,
      ));

      expect(model.future1SelectorCalls, 1);

      model.triggerRebuild();
      await tester.pump();
      expect(model.future1SelectorCalls, 2, reason: 'Called on rebuild');

      model.triggerRebuild();
      await tester.pump();
      expect(model.future1SelectorCalls, 3, reason: 'Called again');
    });

    testWidgets(
        'allowFutureChange: true - handles selector returning different Future identity',
        (tester) async {
      // This test checks that when the selector returns a DIFFERENT Future object
      // (not just re-calling selector), the new Future's value is actually used.
      // This exposes the bug at line 571 where (future == watch.observedObject) never works
      // because future is null at that point.

      final completer1 = Completer<String>();
      final completer2 = Completer<String>();

      bool useFuture1 = true;

      final testModel = SwitchableFutureModel(
        future1: completer1.future,
        future2: completer2.future,
      );
      await di.reset();
      di.registerSingleton(testModel);

      Widget buildWidget() => SwitchableFutureTestWidget(
            useFuture1: useFuture1,
            onSwitch: () => useFuture1 = !useFuture1,
          );

      await tester.pumpWidget(buildWidget());

      // Complete first future
      completer1.complete('value1');
      await tester.pump(); // Trigger future completion callback
      await tester.pump(); // Rebuild with new value
      expect(find.text('value1'), findsOneWidget);

      // Switch to second future (DIFFERENT Future object)
      await tester.tap(find.byKey(const Key('switch')));
      await tester.pumpWidget(
          buildWidget()); // Rebuild widget with new useFuture1 value

      // After fix: Should reset to initial value when switching futures
      expect(find.text('initial'), findsOneWidget,
          reason: 'Should reset to initial value when Future changes');

      // Complete second future
      completer2.complete('value2');
      await tester.pump(); // Trigger future completion callback
      await tester.pump(); // Rebuild with new value

      // After fix: Should show value2 from the new Future
      expect(find.text('value2'), findsOneWidget,
          reason:
              'Should use new Future value after properly disposing old subscription');
    });
  });
}
