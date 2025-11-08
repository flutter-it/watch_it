// ignore_for_file: unused_local_variable

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

class TestChangeNotifier extends ChangeNotifier {
  int _value = 0;
  int get value => _value;

  void increment() {
    _value++;
    notifyListeners();
  }

  void setValue(int newValue) {
    _value = newValue;
    notifyListeners();
  }
}

class HandlerEvent {
  final BuildContext context;
  final dynamic value;

  HandlerEvent(this.context, this.value);
}

void main() {
  setUp(() {
    di.reset();
  });

  tearDown(() {
    di.reset();
  });

  group('registerChangeNotifierHandler', () {
    testWidgets('basic ChangeNotifier handler', (tester) async {
      final model = TestChangeNotifier();
      di.registerSingleton(model);

      final handlerCalls = <HandlerEvent>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _ChangeNotifierHandlerWidget(
            onHandler: (context, value, cancel) {
              handlerCalls.add(HandlerEvent(context, value));
            },
          ),
        ),
      );

      expect(handlerCalls.length, 0);

      model.increment();
      await tester.pump();

      expect(handlerCalls.length, 1);
      expect(handlerCalls[0].value, model);
      expect(handlerCalls[0].value.value, 1);
      expect(handlerCalls[0].context, isNotNull);
    });

    testWidgets('handler with target parameter', (tester) async {
      final localModel = TestChangeNotifier();
      final handlerCalls = <HandlerEvent>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _ChangeNotifierHandlerWithTargetWidget(
            target: localModel,
            onHandler: (context, value, cancel) {
              handlerCalls.add(HandlerEvent(context, value));
            },
          ),
        ),
      );

      expect(handlerCalls.length, 0);

      localModel.increment();
      await tester.pump();

      expect(handlerCalls.length, 1);
      expect(handlerCalls[0].value, localModel);
    });

    testWidgets('handler with instanceName', (tester) async {
      final model1 = TestChangeNotifier();
      final model2 = TestChangeNotifier();
      di.registerSingleton<TestChangeNotifier>(model1, instanceName: 'model1');
      di.registerSingleton<TestChangeNotifier>(model2, instanceName: 'model2');

      final handlerCalls = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              _ChangeNotifierHandlerWithInstanceNameWidget(
                instanceName: 'model1',
                onHandler: (context, value, cancel) {
                  handlerCalls.add('model1');
                },
              ),
              _ChangeNotifierHandlerWithInstanceNameWidget(
                instanceName: 'model2',
                onHandler: (context, value, cancel) {
                  handlerCalls.add('model2');
                },
              ),
            ],
          ),
        ),
      );

      expect(handlerCalls.length, 0);

      model1.increment();
      await tester.pump();

      expect(handlerCalls.length, 1);
      expect(handlerCalls[0], 'model1');

      model2.increment();
      await tester.pump();

      expect(handlerCalls.length, 2);
      expect(handlerCalls[1], 'model2');
    });

    testWidgets('handler executeImmediately', (tester) async {
      final model = TestChangeNotifier();
      model.setValue(42); // Set initial value
      di.registerSingleton(model);

      final handlerCalls = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _ChangeNotifierHandlerExecuteImmediatelyWidget(
            onHandler: (context, value, cancel) {
              handlerCalls.add(value.value);
            },
          ),
        ),
      );

      // Handler should be called immediately with current value
      await tester.pump();
      expect(handlerCalls.length, 1);
      expect(handlerCalls[0], 42);

      model.increment();
      await tester.pump();

      expect(handlerCalls.length, 2);
      expect(handlerCalls[1], 43);
    });

    testWidgets('handler cancel function', (tester) async {
      final model = TestChangeNotifier();
      di.registerSingleton(model);

      final handlerCalls = <int>[];
      bool shouldCancel = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _ChangeNotifierHandlerWithCancelWidget(
            onHandler: (context, value, cancel) {
              handlerCalls.add(value.value);
              if (shouldCancel) {
                cancel();
              }
            },
          ),
        ),
      );

      model.increment(); // value = 1
      await tester.pump();

      expect(handlerCalls.length, 1);
      expect(handlerCalls[0], 1);

      shouldCancel = true;

      model.increment(); // value = 2
      await tester.pump();

      expect(handlerCalls.length, 2);
      expect(handlerCalls[1], 2);

      // After cancel, handler should not be called anymore
      model.increment(); // value = 3
      await tester.pump();

      expect(handlerCalls.length, 2); // Still 2, no new call
    });

    testWidgets('multiple handlers on same ChangeNotifier', (tester) async {
      final model = TestChangeNotifier();
      di.registerSingleton(model);

      final handler1Calls = <int>[];
      final handler2Calls = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _MultipleHandlersWidget(
            onHandler1: (context, value, cancel) {
              handler1Calls.add(value.value);
            },
            onHandler2: (context, value, cancel) {
              handler2Calls.add(value.value);
            },
          ),
        ),
      );

      model.increment();
      await tester.pump();

      expect(handler1Calls.length, 1);
      expect(handler2Calls.length, 1);
      expect(handler1Calls[0], 1);
      expect(handler2Calls[0], 1);

      model.increment();
      await tester.pump();

      expect(handler1Calls.length, 2);
      expect(handler2Calls.length, 2);
      expect(handler1Calls[1], 2);
      expect(handler2Calls[1], 2);
    });

    testWidgets('handler disposes when widget removed', (tester) async {
      final model = TestChangeNotifier();
      di.registerSingleton(model);

      final handlerCalls = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _ChangeNotifierHandlerWidget(
            onHandler: (context, value, cancel) {
              handlerCalls.add(value.value);
            },
          ),
        ),
      );

      model.increment();
      await tester.pump();

      expect(handlerCalls.length, 1);

      // Remove widget from tree
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(),
        ),
      );

      // Handler should not be called after widget disposal
      model.increment();
      await tester.pump();

      expect(handlerCalls.length, 1); // Still 1, no new call
    });
  });

  group('Handler Edge Cases', () {
    testWidgets('handler context is valid', (tester) async {
      final model = TestChangeNotifier();
      di.registerSingleton(model);

      BuildContext? capturedContext;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _ChangeNotifierHandlerWidget(
            onHandler: (context, value, cancel) {
              capturedContext = context;
            },
          ),
        ),
      );

      model.increment();
      await tester.pump();

      expect(capturedContext, isNotNull);
      expect(capturedContext!.mounted, true);
    });

    testWidgets('multiple change notifications in quick succession',
        (tester) async {
      final model = TestChangeNotifier();
      di.registerSingleton(model);

      final handlerCalls = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _ChangeNotifierHandlerWidget(
            onHandler: (context, value, cancel) {
              handlerCalls.add(value.value);
            },
          ),
        ),
      );

      // Trigger multiple changes before pump
      model.increment(); // 1
      model.increment(); // 2
      model.increment(); // 3
      await tester.pump();

      // Handler should be called at least once, possibly for each change
      // Framework may coalesce rapid notifications, so we verify:
      // 1. Handler was called
      // 2. Final value is correct
      expect(handlerCalls, isNotEmpty);
      expect(handlerCalls.last, 3); // Final value should be 3
    });
  });
}

// Test widgets

class _ChangeNotifierHandlerWidget extends StatelessWidget with WatchItMixin {
  final void Function(BuildContext context, TestChangeNotifier value,
      void Function() cancel) onHandler;

  const _ChangeNotifierHandlerWidget({required this.onHandler});

  @override
  Widget build(BuildContext context) {
    registerChangeNotifierHandler<TestChangeNotifier>(
      handler: onHandler,
    );
    return const SizedBox();
  }
}

class _ChangeNotifierHandlerWithTargetWidget extends StatelessWidget
    with WatchItMixin {
  final TestChangeNotifier target;
  final void Function(BuildContext context, TestChangeNotifier value,
      void Function() cancel) onHandler;

  const _ChangeNotifierHandlerWithTargetWidget({
    required this.target,
    required this.onHandler,
  });

  @override
  Widget build(BuildContext context) {
    registerChangeNotifierHandler<TestChangeNotifier>(
      target: target,
      handler: onHandler,
    );
    return const SizedBox();
  }
}

class _ChangeNotifierHandlerWithInstanceNameWidget extends StatelessWidget
    with WatchItMixin {
  final String instanceName;
  final void Function(BuildContext context, TestChangeNotifier value,
      void Function() cancel) onHandler;

  const _ChangeNotifierHandlerWithInstanceNameWidget({
    required this.instanceName,
    required this.onHandler,
  });

  @override
  Widget build(BuildContext context) {
    registerChangeNotifierHandler<TestChangeNotifier>(
      instanceName: instanceName,
      handler: onHandler,
    );
    return const SizedBox();
  }
}

class _ChangeNotifierHandlerExecuteImmediatelyWidget extends StatelessWidget
    with WatchItMixin {
  final void Function(BuildContext context, TestChangeNotifier value,
      void Function() cancel) onHandler;

  const _ChangeNotifierHandlerExecuteImmediatelyWidget(
      {required this.onHandler});

  @override
  Widget build(BuildContext context) {
    registerChangeNotifierHandler<TestChangeNotifier>(
      handler: onHandler,
      executeImmediately: true,
    );
    return const SizedBox();
  }
}

class _ChangeNotifierHandlerWithCancelWidget extends StatelessWidget
    with WatchItMixin {
  final void Function(BuildContext context, TestChangeNotifier value,
      void Function() cancel) onHandler;

  const _ChangeNotifierHandlerWithCancelWidget({required this.onHandler});

  @override
  Widget build(BuildContext context) {
    registerChangeNotifierHandler<TestChangeNotifier>(
      handler: onHandler,
    );
    return const SizedBox();
  }
}

class _MultipleHandlersWidget extends StatelessWidget with WatchItMixin {
  final void Function(BuildContext context, TestChangeNotifier value,
      void Function() cancel) onHandler1;
  final void Function(BuildContext context, TestChangeNotifier value,
      void Function() cancel) onHandler2;

  const _MultipleHandlersWidget({
    required this.onHandler1,
    required this.onHandler2,
  });

  @override
  Widget build(BuildContext context) {
    registerChangeNotifierHandler<TestChangeNotifier>(
      handler: onHandler1,
    );
    registerChangeNotifierHandler<TestChangeNotifier>(
      handler: onHandler2,
    );
    return const SizedBox();
  }
}
