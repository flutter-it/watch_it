// ignore_for_file: unused_local_variable

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

class ScopedService {
  final String name;
  bool disposed = false;

  ScopedService(this.name);

  void dispose() {
    disposed = true;
  }
}

void main() {
  setUp(() {
    di.reset();
  });

  tearDown(() {
    di.reset();
  });

  group('pushScope()', () {
    testWidgets('basic scope push', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PushScopeWidget(),
        ),
      );

      // Verify scope was pushed
      expect(di.currentScopeName, isNotNull);
    });

    testWidgets('scope with init function', (tester) async {
      ScopedService? registeredService;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PushScopeWithInitWidget(
            init: (getIt) {
              final service = ScopedService('test');
              getIt.registerSingleton(service);
              registeredService = service;
            },
          ),
        ),
      );

      // Verify init was called and service registered
      expect(registeredService, isNotNull);
      expect(di.isRegistered<ScopedService>(), true);
      expect(di<ScopedService>().name, 'test');
    });

    testWidgets('scope with dispose function', (tester) async {
      bool disposeCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PushScopeWithDisposeWidget(
            dispose: () {
              disposeCalled = true;
            },
          ),
        ),
      );

      expect(disposeCalled, false);

      // Remove widget from tree
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(),
        ),
      );

      // Verify dispose was called
      expect(disposeCalled, true);
    });

    testWidgets('scope isFinal parameter', (tester) async {
      String? scopeName;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PushScopeWithFinalWidget(
            onScopeName: (name) => scopeName = name,
          ),
        ),
      );

      expect(scopeName, isNotNull);
      // Verify scope exists
      expect(di.currentScopeName, scopeName);
    });

    testWidgets('multiple widgets push independent scopes', (tester) async {
      final scopeNames = <String?>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              _PushScopeWithCallbackWidget(
                id: '1',
                onScopePushed: (name) => scopeNames.add(name),
              ),
              _PushScopeWithCallbackWidget(
                id: '2',
                onScopePushed: (name) => scopeNames.add(name),
              ),
            ],
          ),
        ),
      );

      // Both widgets should have pushed scopes
      expect(scopeNames.length, 2);
      expect(scopeNames[0], isNotNull);
      expect(scopeNames[1], isNotNull);
      expect(scopeNames[0], isNot(equals(scopeNames[1])));
    });

    testWidgets('scope lifecycle tied to widget', (tester) async {
      String? scopeName;
      bool disposeCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PushScopeCompleteWidget(
            onScopeName: (name) => scopeName = name,
            onDispose: () => disposeCalled = true,
          ),
        ),
      );

      expect(scopeName, isNotNull);
      expect(disposeCalled, false);

      // Remove widget
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(),
        ),
      );

      expect(disposeCalled, true);
    });
  });

  group('rebuildOnScopeChanges()', () {
    testWidgets('rebuild on scope push', (tester) async {
      int buildCount = 0;
      bool? lastScopeChange;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _RebuildOnScopeChangesWidget(
            onBuild: (scopeChange) {
              buildCount++;
              lastScopeChange = scopeChange;
            },
          ),
        ),
      );

      expect(buildCount, 1);
      // Initial build may or may not have scope change (implementation detail)
      final initialScopeChange = lastScopeChange;

      // Push a scope externally
      di.pushNewScope();
      await tester.pump();

      expect(buildCount, 2);
      expect(lastScopeChange, true); // true = scope was pushed
    });

    testWidgets('rebuild on scope pop', (tester) async {
      int buildCount = 0;
      bool? lastScopeChange;

      // Start with a scope
      di.pushNewScope();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _RebuildOnScopeChangesWidget(
            onBuild: (scopeChange) {
              buildCount++;
              lastScopeChange = scopeChange;
            },
          ),
        ),
      );

      expect(buildCount, 1);
      buildCount = 0; // Reset

      // Pop the scope
      await di.popScope();
      await tester.pump();

      expect(buildCount, 1);
      expect(lastScopeChange, false); // false = scope was popped
    });

    testWidgets('no rebuild when no scope change', (tester) async {
      int buildCount = 0;
      bool? lastScopeChange;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _RebuildOnScopeChangesWidget(
            onBuild: (scopeChange) {
              buildCount++;
              lastScopeChange = scopeChange;
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(lastScopeChange, isNull);

      // Trigger rebuild without scope change
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _RebuildOnScopeChangesWidget(
            key: const ValueKey('new'),
            onBuild: (scopeChange) {
              buildCount++;
              lastScopeChange = scopeChange;
            },
          ),
        ),
      );

      expect(buildCount, 2);
      expect(lastScopeChange, isNull); // Still null, no scope change
    });

    testWidgets('multiple widgets watching scope changes', (tester) async {
      int widget1Builds = 0;
      int widget2Builds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              _RebuildOnScopeChangesWidget(
                onBuild: (scopeChange) => widget1Builds++,
              ),
              _RebuildOnScopeChangesWidget(
                onBuild: (scopeChange) => widget2Builds++,
              ),
            ],
          ),
        ),
      );

      expect(widget1Builds, 1);
      expect(widget2Builds, 1);

      widget1Builds = 0;
      widget2Builds = 0;

      // Push scope
      di.pushNewScope();
      await tester.pump();

      // Both widgets should rebuild
      expect(widget1Builds, 1);
      expect(widget2Builds, 1);
    });
  });
}

// Test widgets

class _PushScopeWidget extends StatelessWidget with WatchItMixin {
  @override
  Widget build(BuildContext context) {
    pushScope();
    return const SizedBox();
  }
}

class _PushScopeWithInitWidget extends StatelessWidget with WatchItMixin {
  final void Function(GetIt getIt) init;

  const _PushScopeWithInitWidget({required this.init});

  @override
  Widget build(BuildContext context) {
    pushScope(init: init);
    return const SizedBox();
  }
}

class _PushScopeWithDisposeWidget extends StatelessWidget with WatchItMixin {
  final void Function() dispose;

  const _PushScopeWithDisposeWidget({required this.dispose});

  @override
  Widget build(BuildContext context) {
    pushScope(dispose: dispose);
    return const SizedBox();
  }
}

class _PushScopeWithFinalWidget extends StatelessWidget with WatchItMixin {
  final void Function(String? name) onScopeName;

  const _PushScopeWithFinalWidget({required this.onScopeName});

  @override
  Widget build(BuildContext context) {
    pushScope(isFinal: true);
    onScopeName(di.currentScopeName);
    return const SizedBox();
  }
}

class _PushScopeWithCallbackWidget extends StatelessWidget with WatchItMixin {
  final String id;
  final void Function(String? name) onScopePushed;

  const _PushScopeWithCallbackWidget({
    required this.id,
    required this.onScopePushed,
  });

  @override
  Widget build(BuildContext context) {
    pushScope();
    onScopePushed(di.currentScopeName);
    return Text(id, textDirection: TextDirection.ltr);
  }
}

class _PushScopeCompleteWidget extends StatelessWidget with WatchItMixin {
  final void Function(String? name) onScopeName;
  final void Function() onDispose;

  const _PushScopeCompleteWidget({
    required this.onScopeName,
    required this.onDispose,
  });

  @override
  Widget build(BuildContext context) {
    pushScope(dispose: onDispose);
    onScopeName(di.currentScopeName);
    return const SizedBox();
  }
}

class _RebuildOnScopeChangesWidget extends StatelessWidget with WatchItMixin {
  final void Function(bool? scopeChange) onBuild;

  const _RebuildOnScopeChangesWidget({super.key, required this.onBuild});

  @override
  Widget build(BuildContext context) {
    final scopeChange = rebuildOnScopeChanges();
    onBuild(scopeChange);
    return const SizedBox();
  }
}
