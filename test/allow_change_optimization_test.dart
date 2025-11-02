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
  });
}
