// Tests for public API validation (runtime type checks)
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

/// Test model for validation tests
class TestModel {
  final String value = 'test';
}

void main() {
  setUp(() async {
    await di.reset();
    di.registerSingleton<TestModel>(TestModel());
    // Register wrong types to test validation
    di.registerSingleton<String>('not a stream');
    di.registerSingleton<int>(42);
  });

  tearDown(() async {
    await di.reset();
  });

  group('watchStream - runtime validation', () {
    testWidgets('throws ArgumentError when target is not a Stream',
        (tester) async {
      await tester.pumpWidget(
        TestWidget(
          builder: (context) {
            expect(
              () => watchStream<String, String>(
                null, // no select function
                target: 'not a stream', // Wrong type!
                initialValue: 'initial',
              ),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'message',
                  contains('target must be a Stream<String>'),
                ),
              ),
            );
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('throws ArgumentError when GetIt object is not a Stream',
        (tester) async {
      await tester.pumpWidget(
        TestWidget(
          builder: (context) {
            expect(
              () => watchStream<String, String>(
                null, // no select function
                // Will get 'not a stream' from GetIt
                initialValue: 'initial',
              ),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'message',
                  contains('target must be a Stream<String>'),
                ),
              ),
            );
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('watchFuture - runtime validation', () {
    testWidgets('throws ArgumentError when target is not a Future',
        (tester) async {
      await tester.pumpWidget(
        TestWidget(
          builder: (context) {
            expect(
              () => watchFuture<int, int>(
                null, // no select function
                target: 42, // Wrong type!
                initialValue: 0,
              ),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'message',
                  contains('target must be a Future<int>'),
                ),
              ),
            );
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('throws ArgumentError when GetIt object is not a Future',
        (tester) async {
      await tester.pumpWidget(
        TestWidget(
          builder: (context) {
            expect(
              () => watchFuture<int, int>(
                null, // no select function
                // Will get 42 from GetIt
                initialValue: 0,
              ),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'message',
                  contains('target must be a Future<int>'),
                ),
              ),
            );
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('registerHandler - runtime validation', () {
    testWidgets('throws ArgumentError when target is not a Listenable',
        (tester) async {
      await tester.pumpWidget(
        TestWidget(
          builder: (context) {
            expect(
              () => registerHandler<TestModel, String>(
                select: null, // no select function
                target: TestModel(), // Wrong type - not a Listenable!
                handler: (context, value, cancel) {},
              ),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'message',
                  contains('target must be a Listenable'),
                ),
              ),
            );
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('throws ArgumentError when GetIt object is not a Listenable',
        (tester) async {
      await tester.pumpWidget(
        TestWidget(
          builder: (context) {
            expect(
              () => registerHandler<TestModel, String>(
                select: null, // no select function
                // Will get TestModel from GetIt - not a Listenable
                handler: (context, value, cancel) {},
              ),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'message',
                  contains('target must be a Listenable'),
                ),
              ),
            );
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('registerStreamHandler - runtime validation', () {
    testWidgets('throws ArgumentError when target is not a Stream',
        (tester) async {
      await tester.pumpWidget(
        TestWidget(
          builder: (context) {
            expect(
              () => registerStreamHandler<String, String>(
                select: null, // no select function
                target: 'not a stream', // Wrong type!
                handler: (context, snapshot, cancel) {},
              ),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'message',
                  contains('target must be a Stream<String>'),
                ),
              ),
            );
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('registerFutureHandler - runtime validation', () {
    testWidgets('throws ArgumentError when target is not a Future',
        (tester) async {
      await tester.pumpWidget(
        TestWidget(
          builder: (context) {
            expect(
              () => registerFutureHandler<int, int>(
                select: null, // no select function
                target: 42, // Wrong type!
                handler: (context, snapshot, cancel) {},
              ),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'message',
                  contains('target must be a Future<int>'),
                ),
              ),
            );
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('Compile-time type safety - select function', () {
    // These tests document that select function type errors
    // are caught at COMPILE TIME, not runtime

    test('Type safety documentation', () {
      // This test documents the compile-time checks.
      // Uncomment the code below to see analyzer errors:

      // Example 1: Wrong return type in select function
      // This will NOT compile:
      // watchStream<TestModel, String>(
      //   (model) => 42, // ERROR: Expected Stream<String>, got int
      //   initialValue: '',
      // );

      // Example 2: Wrong generic type
      // This will NOT compile:
      // watchFuture<TestModel, int>(
      //   (model) => Future.value('string'), // ERROR: Expected Future<int>, got Future<String>
      //   initialValue: 0,
      // );

      // Example 3: registerHandler with wrong return type
      // This will NOT compile:
      // registerHandler<TestModel, String>(
      //   select: (model) => 42, // ERROR: Expected ValueListenable<String>, got int
      //   handler: (context, value, cancel) {},
      // );
    });
  });
}

/// Test widget wrapper for watch functions
class TestWidget extends StatelessWidget with WatchItMixin {
  final Widget Function(BuildContext) builder;

  const TestWidget({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}
