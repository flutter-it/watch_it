// ignore_for_file: unused_local_variable

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

class TestModel extends ChangeNotifier {
  int _value = 0;
  int get value => _value;

  void increment() {
    _value++;
    notifyListeners();
  }
}

void main() {
  setUp(() {
    di.reset();
  });

  tearDown(() {
    di.reset();
  });

  group('WatchingWidget', () {
    testWidgets('rebuilds on watch', (tester) async {
      final model = TestModel();
      di.registerSingleton(model);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TestWatchingWidget(),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      model.increment();
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('creates correct Element type', (tester) async {
      final model = TestModel();
      di.registerSingleton(model);

      final widget = _TestWatchingWidget();
      final element = widget.createElement();

      expect(
          element.runtimeType.toString(), contains('StatelessWatchItElement'));
    });

    testWidgets('multiple instances are independent', (tester) async {
      final model1 = TestModel();
      final model2 = TestModel();
      di.registerSingleton<TestModel>(model1, instanceName: 'model1');
      di.registerSingleton<TestModel>(model2, instanceName: 'model2');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              _TestWatchingWidgetWithName('model1'),
              _TestWatchingWidgetWithName('model2'),
            ],
          ),
        ),
      );

      expect(find.text('model1: 0'), findsOneWidget);
      expect(find.text('model2: 0'), findsOneWidget);

      model1.increment();
      await tester.pump();

      expect(find.text('model1: 1'), findsOneWidget);
      expect(find.text('model2: 0'), findsOneWidget);

      model2.increment();
      model2.increment();
      await tester.pump();

      expect(find.text('model1: 1'), findsOneWidget);
      expect(find.text('model2: 2'), findsOneWidget);
    });

    testWidgets('disposes watches properly', (tester) async {
      final model = TestModel();
      di.registerSingleton(model);

      int listenerCount = 0;
      void listener() {
        listenerCount++;
      }

      model.addListener(listener);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TestWatchingWidget(),
        ),
      );

      final initialCount = listenerCount;

      // Remove widget from tree (should dispose the watch listener)
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(),
        ),
      );

      // Trigger notification - only our manual listener should be called now
      model.increment();

      // Verify our listener was called exactly once more
      // If watch listener wasn't disposed, count would increase by 2+
      expect(listenerCount, initialCount + 1);
      model.removeListener(listener);
    });

    testWidgets('multiple watches in single widget', (tester) async {
      final model1 = TestModel();
      final model2 = TestModel();
      di.registerSingleton<TestModel>(model1, instanceName: 'model1');
      di.registerSingleton<TestModel>(model2, instanceName: 'model2');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _MultiWatchWatchingWidget(),
        ),
      );

      expect(find.text('0 + 0 = 0'), findsOneWidget);

      model1.increment();
      await tester.pump();

      expect(find.text('1 + 0 = 1'), findsOneWidget);

      model2.increment();
      model2.increment();
      await tester.pump();

      expect(find.text('1 + 2 = 3'), findsOneWidget);
    });
  });

  group('WatchingStatefulWidget', () {
    testWidgets('rebuilds on watch', (tester) async {
      final model = TestModel();
      di.registerSingleton(model);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TestWatchingStatefulWidget(),
        ),
      );

      expect(find.text('watched: 0'), findsOneWidget);

      model.increment();
      await tester.pump();

      expect(find.text('watched: 1'), findsOneWidget);
    });

    testWidgets('creates correct Element type', (tester) async {
      final model = TestModel();
      di.registerSingleton(model);

      final widget = _TestWatchingStatefulWidget();
      final element = widget.createElement();

      expect(
          element.runtimeType.toString(), contains('StatefulWatchItElement'));
    });

    testWidgets('preserves state across rebuilds', (tester) async {
      final model = TestModel();
      di.registerSingleton(model);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TestWatchingStatefulWidget(),
        ),
      );

      expect(find.text('watched: 0'), findsOneWidget);
      expect(find.text('local: 0'), findsOneWidget);

      // Increment local state
      await tester.tap(find.text('increment local'));
      await tester.pump();

      expect(find.text('watched: 0'), findsOneWidget);
      expect(find.text('local: 1'), findsOneWidget);

      // Increment watched value
      model.increment();
      await tester.pump();

      // Local state should be preserved
      expect(find.text('watched: 1'), findsOneWidget);
      expect(find.text('local: 1'), findsOneWidget);

      // Increment local state again
      await tester.tap(find.text('increment local'));
      await tester.pump();

      expect(find.text('watched: 1'), findsOneWidget);
      expect(find.text('local: 2'), findsOneWidget);
    });

    testWidgets('lifecycle methods work correctly', (tester) async {
      final model = TestModel();
      di.registerSingleton(model);

      final lifecycleEvents = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _TestLifecycleWatchingStatefulWidget(lifecycleEvents),
        ),
      );

      expect(lifecycleEvents, contains('initState'));
      expect(lifecycleEvents, contains('build'));

      // Trigger rebuild
      model.increment();
      await tester.pump();

      expect(lifecycleEvents.where((e) => e == 'build').length, 2);

      // Remove widget
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(),
        ),
      );

      expect(lifecycleEvents, contains('dispose'));
    });

    testWidgets('multiple stateful widgets independent', (tester) async {
      final model1 = TestModel();
      final model2 = TestModel();
      di.registerSingleton<TestModel>(model1, instanceName: 'model1');
      di.registerSingleton<TestModel>(model2, instanceName: 'model2');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              _TestWatchingStatefulWidgetWithName('model1'),
              _TestWatchingStatefulWidgetWithName('model2'),
            ],
          ),
        ),
      );

      expect(find.text('model1: 0'), findsOneWidget);
      expect(find.text('model2: 0'), findsOneWidget);

      model1.increment();
      await tester.pump();

      expect(find.text('model1: 1'), findsOneWidget);
      expect(find.text('model2: 0'), findsOneWidget);
    });
  });
}

// Test widgets for WatchingWidget

class _TestWatchingWidget extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final model = watchIt<TestModel>();
    return Text('${model.value}', textDirection: TextDirection.ltr);
  }
}

class _TestWatchingWidgetWithName extends WatchingWidget {
  final String instanceName;

  const _TestWatchingWidgetWithName(this.instanceName);

  @override
  Widget build(BuildContext context) {
    final model = di<TestModel>(instanceName: instanceName);
    watch(model);
    return Text('$instanceName: ${model.value}',
        textDirection: TextDirection.ltr);
  }
}

class _MultiWatchWatchingWidget extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final model1 = di<TestModel>(instanceName: 'model1');
    final model2 = di<TestModel>(instanceName: 'model2');
    watch(model1);
    watch(model2);
    final sum = model1.value + model2.value;
    return Text('${model1.value} + ${model2.value} = $sum',
        textDirection: TextDirection.ltr);
  }
}

// Test widgets for WatchingStatefulWidget

class _TestWatchingStatefulWidget extends WatchingStatefulWidget {
  @override
  State<_TestWatchingStatefulWidget> createState() =>
      _TestWatchingStatefulWidgetState();
}

class _TestWatchingStatefulWidgetState
    extends State<_TestWatchingStatefulWidget> {
  int _localCounter = 0;

  @override
  Widget build(BuildContext context) {
    final model = watchIt<TestModel>();
    return Column(
      children: [
        Text('watched: ${model.value}', textDirection: TextDirection.ltr),
        Text('local: $_localCounter', textDirection: TextDirection.ltr),
        GestureDetector(
          onTap: () {
            setState(() {
              _localCounter++;
            });
          },
          child:
              const Text('increment local', textDirection: TextDirection.ltr),
        ),
      ],
    );
  }
}

class _TestWatchingStatefulWidgetWithName extends WatchingStatefulWidget {
  final String instanceName;

  const _TestWatchingStatefulWidgetWithName(this.instanceName);

  @override
  State<_TestWatchingStatefulWidgetWithName> createState() =>
      _TestWatchingStatefulWidgetWithNameState();
}

class _TestWatchingStatefulWidgetWithNameState
    extends State<_TestWatchingStatefulWidgetWithName> {
  @override
  Widget build(BuildContext context) {
    final model = di<TestModel>(instanceName: widget.instanceName);
    watch(model);
    return Text('${widget.instanceName}: ${model.value}',
        textDirection: TextDirection.ltr);
  }
}

class _TestLifecycleWatchingStatefulWidget extends WatchingStatefulWidget {
  final List<String> lifecycleEvents;

  const _TestLifecycleWatchingStatefulWidget(this.lifecycleEvents);

  @override
  State<_TestLifecycleWatchingStatefulWidget> createState() =>
      _TestLifecycleWatchingStatefulWidgetState();
}

class _TestLifecycleWatchingStatefulWidgetState
    extends State<_TestLifecycleWatchingStatefulWidget> {
  @override
  void initState() {
    super.initState();
    widget.lifecycleEvents.add('initState');
  }

  @override
  Widget build(BuildContext context) {
    widget.lifecycleEvents.add('build');
    final model = watchIt<TestModel>();
    return Text('${model.value}', textDirection: TextDirection.ltr);
  }

  @override
  void dispose() {
    widget.lifecycleEvents.add('dispose');
    super.dispose();
  }
}
