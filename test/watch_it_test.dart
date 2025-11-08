// ignore_for_file: unused_local_variable
// ignore_for_file: invalid_use_of_protected_member
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

class TestDisposable {
  TestDisposable({required this.value});
  final String value;
  void dispose() {
    lifetimeValueDisposeCount++;
  }

  Future<TestDisposable> init() async {
    await testCompleter.future;
    return this;
  }
}

late Completer<void> testCompleter;

class Model extends ChangeNotifier {
  String? constantValue;
  String? _country;
  set country(String? val) {
    _country = val;
    notifyListeners();
  }

  String? get country => _country;
  String? _country2;
  set country2(String? val) {
    _country2 = val;
    notifyListeners();
  }

  void setNameNull() {
    name = null;
  }

  ValueNotifier<String>? nullValueNotifier;

  String? get country2 => _country2;
  ValueNotifier<String>? name;
  final Model? nestedModel;
  // ignore: close_sinks
  final StreamController<String> streamController =
      StreamController<String>.broadcast();

  Model(
      {this.constantValue,
      String? country,
      this.name,
      this.nestedModel,
      String? country2})
      : _country = country,
        _country2 = country2;

  Stream<String> get stream => streamController.stream;
  final Completer<String?> completer = Completer<String?>();
  Future<String?> get future => completer.future;
}

class TestStateLessWidget extends StatelessWidget with WatchItMixin {
  final bool watchTwice;
  final bool watchListenableInGetIt;
  final bool watchOnlyTwice;
  final bool watchValueTwice;
  final bool watchStreamTwice;
  final bool watchFutureTwice;
  final bool testIsReady;
  final bool testAllReady;
  final bool testAllReadyHandler;
  final bool watchListenableWithWatchPropertyValue;
  final bool testNullValueNotifier;
  final ValueListenable<int>? localTarget;
  final bool callAllReadyHandlerOnlyOnce;
  TestStateLessWidget(
      {super.key,
      this.localTarget,
      this.watchTwice = false,
      this.watchListenableInGetIt = false,
      this.watchOnlyTwice = false,
      this.watchValueTwice = false,
      this.watchStreamTwice = false,
      this.watchFutureTwice = false,
      this.testIsReady = false,
      this.testAllReady = false,
      this.watchListenableWithWatchPropertyValue = false,
      this.testNullValueNotifier = false,
      this.testAllReadyHandler = false,
      this.callAllReadyHandlerOnlyOnce = false});

  @override
  Widget build(BuildContext context) {
    callOnce(
      (context) {
        initCount++;
      },
      dispose: () {
        initDiposeCount++;
      },
    );
    onDispose(() {
      disposeCount++;
    });
    final wasScopePushed = rebuildOnScopeChanges();
    buildCount++;
    final onlyRead = di<Model>().constantValue!;
    final notifierVal = watch(di<ValueNotifier<String>>());
    final createOnceValue = createOnce<TestDisposable>(() {
      lifetimeValueCount++;
      return TestDisposable(value: '42');
    });
    final createOnceAsyncValue = createOnceAsync<TestDisposable>(
      () async {
        return TestDisposable(value: '4711').init();
      },
      initialValue: TestDisposable(value: 'initialValue'),
    );

    String? country;
    String country2;
    if (watchListenableInGetIt) {
      final model = watchIt<Model>();
      country = model.country!;
      country2 = model.country2!;
    }
    if (watchListenableWithWatchPropertyValue) {
      final name2 = watchPropertyValue((Model x) => x.name);
    }
    country = watchPropertyValue((Model x) => x.country);
    country2 = watchPropertyValue((Model x) => x.country2)!;
    final name = watchValue((Model x) => x.name!);
    final nestedCountry =
        watchPropertyValue(target: di<Model>().nestedModel, (x) => x.country)!;

    final localTargetValue =
        localTarget != null ? watch(localTarget!).value : 0;
    final streamResult =
        watchStream((Model x) => x.stream, initialValue: 'streamResult');
    final futureResult =
        watchFuture((Model x) => x.future, initialValue: 'futureResult');
    registerStreamHandler<Model, String>(
        select: (x) => x.stream,
        handler: (context, x, cancel) {
          streamHandlerResult = x.data;
          if (streamHandlerResult == 'Cancel') {
            cancel();
          }
        });
    registerFutureHandler<Model, String?>(
        select: (Model x) => x.future,
        handler: (context, x, cancel) {
          futureHandlerResult = x.data;
          if (streamHandlerResult == 'Cancel') {
            cancel();
          }
        });
    registerHandler(
        select: (Model x) => x.name!,
        handler: (context, String x, cancel) {
          listenableHandlerResult = x;
          if (x == 'Cancel') {
            cancel();
          }
        });
    bool? allReadyResult;
    if (testAllReady) {
      allReadyResult =
          allReady(onReady: (context) => allReadyHandlerResult = 'Ready');
    }
    if (testAllReadyHandler) {
      allReadyHandler((context) {
        allReadyHandlerCount++;
        allReadyHandlerResult2 = 'Ready';
      }, callHandlerOnlyOnce: callAllReadyHandlerOnlyOnce);
    }
    bool? isReadyResult;

    if (testIsReady) {
      isReadyResult = isReady<Model>(
          instanceName: 'isReadyTest',
          onReady: (context) => isReadyHandlerResult = 'Ready');
    }
    if (watchTwice) {
      final notifierVal = watchIt<ValueNotifier<String>>().value;
    }
    if (watchOnlyTwice) {
      final country = watchPropertyValue((Model x) => x.country);
    }
    if (watchValueTwice) {
      final name = watchValue((Model x) => x.name!);
    }
    if (watchStreamTwice) {
      final streamResult =
          watchStream((Model x) => x.stream, initialValue: 'streamResult');
    }
    if (watchFutureTwice) {
      final futureResult =
          watchFuture((Model x) => x.future, initialValue: 'futureResult');
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text(onlyRead, key: const Key('onlyRead')),
          Text(notifierVal.value, key: const Key('notifierVal')),
          Text(createOnceValue.value, key: const Key('lifetimeValue')),
          Text(createOnceAsyncValue.data!.value,
              key: const Key('createOnceAsyncValue')),
          Text(country ?? 'null', key: const Key('country')),
          Text(country2, key: const Key('country2')),
          Text(name, key: const Key('name')),
          Text(nestedCountry, key: const Key('nestedCountry')),
          Text(localTargetValue.toString(), key: const Key('localTarget')),
          Text(streamResult.data!, key: const Key('streamResult')),
          Text(futureResult.data!, key: const Key('futureResult')),
          Text(allReadyResult.toString(), key: const Key('allReadyResult')),
          Text(isReadyResult.toString(), key: const Key('isReadyResult')),
          Text(wasScopePushed.toString(), key: const Key('wasScopePushed')),
        ],
      ),
    );
  }
}

late Model theModel;
late ValueNotifier<String> valNotifier;
int buildCount = 0;
String? streamHandlerResult;
String? futureHandlerResult;
String? listenableHandlerResult;
String? allReadyHandlerResult;
String? allReadyHandlerResult2;
String? isReadyHandlerResult;
int allReadyHandlerCount = 0;
int initCount = 0;
int initDiposeCount = 0;
int disposeCount = 0;
int lifetimeValueCount = 0;
int lifetimeValueDisposeCount = 0;
int afterFirstBuildCallCount = 0;
String? afterFirstBuildContext;
int afterEveryBuildCallCount = 0;
String? afterEveryBuildContext;
bool afterEveryBuildCancelled = false;

void main() {
  setUp(() async {
    buildCount = 0;
    allReadyHandlerCount = 0;
    streamHandlerResult = null;
    listenableHandlerResult = null;
    streamHandlerResult = null;
    futureHandlerResult = null;
    allReadyHandlerResult = null;
    allReadyHandlerResult2 = null;
    isReadyHandlerResult = null;
    allReadyHandlerCount = 0;
    initCount = 0;
    initDiposeCount = 0;
    disposeCount = 0;
    lifetimeValueCount = 0;
    lifetimeValueDisposeCount = 0;
    afterFirstBuildCallCount = 0;
    afterFirstBuildContext = null;
    afterEveryBuildCallCount = 0;
    afterEveryBuildContext = null;
    afterEveryBuildCancelled = false;
    testCompleter = Completer<void>();
    await GetIt.I.reset();
    valNotifier = ValueNotifier<String>('notifierVal');
    theModel = Model(
        constantValue: 'onlyRead',
        country: 'country',
        country2: 'country',

        /// check if watchOnly can differentiate between the two country fields
        name: ValueNotifier('name'),
        nestedModel: Model(country: 'nestedCountry'));
    GetIt.I.registerSingleton<Model>(theModel);
    GetIt.I.registerSingleton(valNotifier);
  });

  testWidgets('onetime access without any data changes', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final lifetimeValue =
        tester.widget<Text>(find.byKey(const Key('lifetimeValue'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final country2 =
        tester.widget<Text>(find.byKey(const Key('country2'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(const Key('futureResult'))).data;
    final scopeResult =
        tester.widget<Text>(find.byKey(const Key('wasScopePushed'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(lifetimeValue, '42');
    expect(country, 'country');
    expect(country2, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(scopeResult, 'null');
    expect(buildCount, 1);
  });
  testWidgets('rebuild on scope changes', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    await tester.pump();

    var scopeResult =
        tester.widget<Text>(find.byKey(const Key('wasScopePushed'))).data;
    expect(scopeResult, 'null');

    GetIt.I.pushNewScope();
    await tester.pump();

    scopeResult =
        tester.widget<Text>(find.byKey(const Key('wasScopePushed'))).data;
    expect(scopeResult, 'true');

    /// trigger a rebuild without changing any scopes
    valNotifier.value = '42';

    await tester.pump();

    scopeResult =
        tester.widget<Text>(find.byKey(const Key('wasScopePushed'))).data;
    expect(scopeResult, 'null');
    expect(buildCount, 3);

    await GetIt.I.popScope();
    await tester.pump();

    scopeResult =
        tester.widget<Text>(find.byKey(const Key('wasScopePushed'))).data;
    expect(scopeResult, 'false');
    expect(buildCount, 4);
  });
  testWidgets('callOnce test', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    valNotifier.value = '1';
    await tester.pump();
    valNotifier.value = '2';
    await tester.pump();

    expect(buildCount, 3);
    expect(initCount, 1);
    await tester.pumpWidget(Container());
    await tester.pump();
    expect(initDiposeCount, 1);
  });
  testWidgets('onDispose test', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    valNotifier.value = '1';
    await tester.pump();
    valNotifier.value = '2';
    await tester.pump();

    expect(buildCount, 3);
    await tester.pumpWidget(Container());
    await tester.pump();
    expect(disposeCount, 1);
  });

  testWidgets('createOnce test', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    await tester.pump();
    expect(lifetimeValueCount, 1);
    expect(lifetimeValueDisposeCount, 0);
    await tester.pumpWidget(Container());
    await tester.pump();
    expect(lifetimeValueDisposeCount, 2);
  });

  testWidgets('createOnceAsync test', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    await tester.pump();

    var createOnceAsyncValue =
        tester.widget<Text>(find.byKey(const Key('createOnceAsyncValue'))).data;
    expect(createOnceAsyncValue, 'initialValue');
    testCompleter.complete();
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump();

    createOnceAsyncValue =
        tester.widget<Text>(find.byKey(const Key('createOnceAsyncValue'))).data;
    expect(createOnceAsyncValue, '4711');
    await tester.pumpWidget(Container());
    await tester.pump();
    expect(lifetimeValueDisposeCount, 2);
  });

  testWidgets('watchTwice', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchTwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });

  testWidgets('watchValueTwice', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchValueTwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });

// Unfortunately we can't check if two selectors point to the same
// object.
  // testWidgets('watchOnlyTwice', (tester) async {
  //   await tester.pumpWidget(TestStateLessWidget(
  //     watchOnlyTwice: true,
  //   ));
  //   await tester.pump();

  //   expect(tester.takeException(), isA<ArgumentError>());
  // });

  // testWidgets('watchXOnlyTwice', (tester) async {
  //   await tester.pumpWidget(TestStateLessWidget(
  //     watchXOnlyTwice: true,
  //   ));
  //   await tester.pump();

  //   expect(tester.takeException(), isA<ArgumentError>());
  // });

  testWidgets('watchStream twice', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchStreamTwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });
  testWidgets('watchFuture twice', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchFutureTwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });
  testWidgets('useWatchPropertyValue on a listenable', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchListenableWithWatchPropertyValue: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('update of non watched field', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.constantValue = '42';
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 1);
  });

  testWidgets('test watchValue', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    valNotifier.value = '42';
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, '42');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('test watch local target', (tester) async {
    final localTarget = ValueNotifier(0);
    await tester.pumpWidget(TestStateLessWidget(
      localTarget: localTarget,
    ));
    localTarget.value = 42;
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final localTargetValue =
        tester.widget<Text>(find.byKey(const Key('localTarget'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(localTargetValue, '42');

    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('test watchValue', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.name!.value = '42';
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    // final futureResult = tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, '42');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    // expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });

  testWidgets('test watchPropertyValue', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.nestedModel!.country = '42';
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, '42');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('test watchPropertyValue with null value', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.country = null;
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'null');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('test watchPropertyValue with notification but no value change',
      (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.notifyListeners();
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 1);
  });
  testWidgets('test watchIt', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchListenableInGetIt: true,
    ));
    theModel.notifyListeners();
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('watchStream', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.streamController.sink.add('42');
    await tester.pump();
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, '42');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('watchFuture', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.completer.complete('42');
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    final error = tester.takeException();
    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, '42');
    expect(buildCount, 2);
  });
  testWidgets('change multiple data', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());

    theModel.country = 'Lummerland';
    theModel.name!.value = '42';
    await tester.pump();

    final onlyRead =
        tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'Lummerland');
    expect(name, '42');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('check that everything is released', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());

    expect(theModel.hasListeners, true);
    expect(theModel.name!.hasListeners, true);
    expect(theModel.streamController.hasListener, true);
    expect(valNotifier.hasListeners, true);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(theModel.hasListeners, false);
    expect(theModel.name!.hasListeners, false);
    expect(theModel.streamController.hasListener, false);
    expect(valNotifier.hasListeners, false);

    expect(buildCount, 1);
  });
  testWidgets('test handlers', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());

    theModel.name!.value = '42';
    theModel.streamController.sink.add('4711');
    theModel.completer.complete('66');

    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));

    expect(streamHandlerResult, '4711');
    expect(listenableHandlerResult, '42');
    expect(futureHandlerResult, '66');

    theModel.name!.value = 'Cancel';
    theModel.streamController.sink.add('Cancel');
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));

    theModel.name!.value = '42';
    theModel.streamController.sink.add('4711');
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));

    expect(streamHandlerResult, 'Cancel');
    expect(listenableHandlerResult, 'Cancel');
    expect(buildCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(theModel.hasListeners, false);
    expect(theModel.name!.hasListeners, false);
    expect(theModel.streamController.hasListener, false);
    expect(valNotifier.hasListeners, false);
  });
  testWidgets('allReady no async object', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      testAllReady: true,
    ));
    await tester.pump(const Duration(milliseconds: 10));

    final allReadyResult =
        tester.widget<Text>(find.byKey(const Key('allReadyResult'))).data;

    expect(allReadyResult, 'true');
    expect(allReadyHandlerResult, 'Ready');

    expect(buildCount, 2);
  });
  testWidgets('allReady async object that is finished', (tester) async {
    GetIt.I.registerSingletonAsync(
        () => Future.delayed(const Duration(milliseconds: 10), () => Model()),
        instanceName: 'asyncObject');
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(TestStateLessWidget(
      testAllReady: true,
    ));
    await tester.pump();

    final allReadyResult =
        tester.widget<Text>(find.byKey(const Key('allReadyResult'))).data;

    expect(allReadyResult, 'true');
    expect(allReadyHandlerResult, 'Ready');

    expect(buildCount, 2);
  });
  testWidgets('allReady async object that is not finished at the start',
      (tester) async {
    GetIt.I.registerSingletonAsync(
        () => Future.delayed(const Duration(milliseconds: 40), () => Model()),
        instanceName: 'asyncObject');
    await tester.pumpWidget(TestStateLessWidget(
      testAllReady: true,
    ));
    await tester.pump(const Duration(milliseconds: 20));

    var allReadyResult =
        tester.widget<Text>(find.byKey(const Key('allReadyResult'))).data;

    expect(allReadyResult, 'false');
    expect(allReadyHandlerResult, null);

    await tester.pump(const Duration(milliseconds: 120));
    allReadyResult =
        tester.widget<Text>(find.byKey(const Key('allReadyResult'))).data;

    expect(allReadyResult, 'true');
    expect(allReadyHandlerResult, 'Ready');
    expect(buildCount, 2);
  });
  testWidgets('allReadyHandler test', (tester) async {
    GetIt.I.registerSingletonAsync(
        () => Future.delayed(const Duration(milliseconds: 10), () => Model()),
        instanceName: 'asyncObject');
    var testStateLessWidget = TestStateLessWidget(
      testAllReadyHandler: true,
    );
    await tester.pumpWidget(testStateLessWidget);
    await tester.pump();

    expect(allReadyHandlerResult2, null);

    await tester.pump(const Duration(milliseconds: 120));
    expect(allReadyHandlerResult2, 'Ready');
    expect(allReadyHandlerCount, 1);
    expect(buildCount, 1);

    valNotifier.value = '000'; // should trigger a rebuild
    await tester.pump(const Duration(milliseconds: 120));
    expect(allReadyHandlerCount, 2);
    expect(buildCount, 2);
  });
  testWidgets('allReadyHandler test: callHandlerOnlyOnce == true',
      (tester) async {
    GetIt.I.registerSingletonAsync(
        () => Future.delayed(const Duration(milliseconds: 10), () => Model()),
        instanceName: 'asyncObject');
    await tester.pumpWidget(TestStateLessWidget(
      testAllReadyHandler: true,
      callAllReadyHandlerOnlyOnce: true,
    ));
    await tester.pump();

    expect(allReadyHandlerResult2, null);

    await tester.pump(const Duration(milliseconds: 120));
    expect(allReadyHandlerResult2, 'Ready');
    expect(allReadyHandlerCount, 1);
    expect(buildCount, 1);

    valNotifier.value = '000'; // should trigger a rebuild
    await tester.pump(const Duration(milliseconds: 120));
    expect(allReadyHandlerCount, 1);
    expect(buildCount, 2);
  });
  testWidgets('isReady async object that is finished', (tester) async {
    GetIt.I.registerSingletonAsync<Model>(
        () => Future.delayed(const Duration(milliseconds: 10), () => Model()),
        instanceName: 'isReadyTest');
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(TestStateLessWidget(
      testIsReady: true,
    ));
    await tester.pump();

    final isReadyResult =
        tester.widget<Text>(find.byKey(const Key('isReadyResult'))).data;

    expect(isReadyResult, 'true');
    expect(isReadyHandlerResult, 'Ready');

    expect(buildCount, 2);
  });
  testWidgets('isReady async object that is not finished at the start',
      (tester) async {
    GetIt.I.registerSingletonAsync(
        () => Future.delayed(const Duration(milliseconds: 10), () => Model()),
        instanceName: 'isReadyTest');
    await tester.pumpWidget(TestStateLessWidget(
      testIsReady: true,
    ));
    await tester.pump();
    await tester.pump();

    var isReadyResult =
        tester.widget<Text>(find.byKey(const Key('isReadyResult'))).data;

    expect(isReadyResult, 'false');
    expect(isReadyHandlerResult, null);

    await tester.pump(const Duration(milliseconds: 120));
    isReadyResult =
        tester.widget<Text>(find.byKey(const Key('isReadyResult'))).data;

    expect(isReadyResult, 'true');
    expect(isReadyHandlerResult, 'Ready');
    expect(buildCount, 2);
  });

  testWidgets('callAfterFirstBuild executes after first frame', (tester) async {
    final widget = _CallAfterFirstBuildTestWidget();

    await tester.pumpWidget(widget);

    // After pumpWidget, the build completes and post-frame callback executes
    expect(afterFirstBuildCallCount, 1);
    expect(afterFirstBuildContext, isNotNull);
  });

  testWidgets('callAfterFirstBuild only executes once on multiple rebuilds',
      (tester) async {
    final widget = _CallAfterFirstBuildTestWidget();

    await tester.pumpWidget(widget);

    expect(afterFirstBuildCallCount, 1);

    // Trigger rebuilds
    valNotifier.value = 'changed1';
    await tester.pump();

    valNotifier.value = 'changed2';
    await tester.pump();

    // Should still only have been called once
    expect(afterFirstBuildCallCount, 1);
  });

  testWidgets(
      'callAfterFirstBuild does not crash if widget disposed after first build',
      (tester) async {
    final widget = _CallAfterFirstBuildTestWidget();

    await tester.pumpWidget(widget);

    // Callback executes after first build
    expect(afterFirstBuildCallCount, 1);

    // Dispose the widget
    await tester.pumpWidget(Container());
    await tester.pump();

    // No crashes should occur
    expect(afterFirstBuildCallCount, 1);
  });

  testWidgets('callAfterFirstBuild has valid context', (tester) async {
    final widget = _CallAfterFirstBuildTestWidget();

    await tester.pumpWidget(widget);

    expect(afterFirstBuildCallCount, 1);
    expect(afterFirstBuildContext, isNotNull);
    // Context should contain the widget type name
    expect(afterFirstBuildContext, contains('_CallAfterFirstBuildTestWidget'));
  });

  testWidgets('callAfterEveryBuild executes after every frame', (tester) async {
    final widget = _CallAfterEveryBuildTestWidget();

    await tester.pumpWidget(widget);

    // After first build
    expect(afterEveryBuildCallCount, 1);
    expect(afterEveryBuildContext, isNotNull);

    // Trigger rebuild
    valNotifier.value = 'changed1';
    await tester.pump();

    // Should have been called again
    expect(afterEveryBuildCallCount, 2);

    // Another rebuild
    valNotifier.value = 'changed2';
    await tester.pump();

    // Should have been called again
    expect(afterEveryBuildCallCount, 3);
  });

  testWidgets('callAfterEveryBuild cancel stops future calls', (tester) async {
    final widget = _CallAfterEveryBuildWithCancelTestWidget();

    await tester.pumpWidget(widget);

    // After first build
    expect(afterEveryBuildCallCount, 1);
    expect(afterEveryBuildCancelled, false);

    // Trigger rebuild - this will call cancel
    valNotifier.value = 'trigger_cancel';
    await tester.pump();

    // Should have been called and cancelled
    expect(afterEveryBuildCallCount, 2);
    expect(afterEveryBuildCancelled, true);

    // Reset counter to verify no more calls
    final countAtCancel = afterEveryBuildCallCount;

    // Another rebuild - should NOT call callback
    valNotifier.value = 'after_cancel';
    await tester.pump();

    // Count should not have increased
    expect(afterEveryBuildCallCount, countAtCancel);
  });

  testWidgets('callAfterEveryBuild has valid context on every call',
      (tester) async {
    final widget = _CallAfterEveryBuildTestWidget();

    await tester.pumpWidget(widget);

    expect(afterEveryBuildCallCount, 1);
    expect(afterEveryBuildContext, isNotNull);
    expect(afterEveryBuildContext, contains('_CallAfterEveryBuildTestWidget'));

    // Trigger rebuild and verify context is still valid
    valNotifier.value = 'changed';
    await tester.pump();

    expect(afterEveryBuildCallCount, 2);
    expect(afterEveryBuildContext, isNotNull);
    expect(afterEveryBuildContext, contains('_CallAfterEveryBuildTestWidget'));
  });

  testWidgets('callAfterEveryBuild stops on widget disposal', (tester) async {
    final widget = _CallAfterEveryBuildTestWidget();

    await tester.pumpWidget(widget);

    expect(afterEveryBuildCallCount, 1);

    // Dispose the widget
    await tester.pumpWidget(Container());
    await tester.pump();

    final countAtDisposal = afterEveryBuildCallCount;

    // Trigger some pumps - callback should not be called
    await tester.pump();
    await tester.pump();

    expect(afterEveryBuildCallCount, countAtDisposal);
  });

  group('Observable Change Detection', () {
    testWidgets(
        'watchPropertyValue disposes old subscription when target changes',
        (tester) async {
      final notifier1 = ValueNotifier<int>(1);
      final notifier2 = ValueNotifier<int>(2);
      GetIt.I.registerSingleton(notifier1);
      GetIt.I.registerSingleton(notifier2, instanceName: 'second');

      bool useFirst = true;

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setState) {
            return _WatchPropertyValueChangeWidget(
              useFirst: useFirst,
              onSwitch: () => setState(() => useFirst = !useFirst),
            );
          },
        ),
      ));

      expect(find.text('1'), findsOneWidget);

      // Switch the observable - this will dispose the old subscription
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Should now show the second notifier's value
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets(
        'registerHandler with allowObservableChange: true disposes old subscription',
        (tester) async {
      final notifier1 = ValueNotifier<int>(1);
      final notifier2 = ValueNotifier<int>(2);
      GetIt.I.registerSingleton(notifier1);
      GetIt.I.registerSingleton(notifier2, instanceName: 'second');

      bool useFirst = true;
      int? capturedValue;

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setState) {
            return _ObservableChangeAllowedWidget(
              useFirst: useFirst,
              onSwitch: () => setState(() => useFirst = !useFirst),
              onValue: (value) => capturedValue = value,
            );
          },
        ),
      ));

      expect(capturedValue, 1);

      // Switch the observable - this will dispose the old subscription
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Should now receive the second notifier's value
      expect(capturedValue, 2);
    });

    testWidgets(
        'registerHandler throws StateError when observable changes without allowObservableChange',
        (tester) async {
      final notifier1 = ValueNotifier<int>(10);
      final notifier2 = ValueNotifier<int>(20);
      GetIt.I.registerSingleton(notifier1);
      GetIt.I.registerSingleton(notifier2, instanceName: 'second');

      bool useFirst = true;

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setState) {
            return _ObservableChangeErrorWidget(
              useFirst: useFirst,
              onSwitch: () => setState(() => useFirst = !useFirst),
            );
          },
        ),
      ));

      // Switch the observable - should throw StateError
      await tester.tap(find.byType(GestureDetector));

      // Try to pump to trigger the rebuild where the error occurs
      try {
        await tester.pump();
      } catch (e) {
        // Exception might be thrown during pump
      }

      // The error should have been thrown during build
      final exception = tester.takeException();
      expect(exception, isA<StateError>());
    });
  });
}

/// Test widget for callAfterFirstBuild tests
class _CallAfterFirstBuildTestWidget extends StatelessWidget with WatchItMixin {
  const _CallAfterFirstBuildTestWidget();

  @override
  Widget build(BuildContext context) {
    // Watch something to ensure the widget can rebuild
    final notifierVal = watch(valNotifier);

    callAfterFirstBuild((ctx) {
      afterFirstBuildCallCount++;
      afterFirstBuildContext = ctx.toString();
    });

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(notifierVal.value),
    );
  }
}

/// Test widget for callAfterEveryBuild tests
class _CallAfterEveryBuildTestWidget extends StatelessWidget with WatchItMixin {
  const _CallAfterEveryBuildTestWidget();

  @override
  Widget build(BuildContext context) {
    // Watch something to ensure the widget can rebuild
    final notifierVal = watch(valNotifier);

    callAfterEveryBuild((ctx, cancel) {
      afterEveryBuildCallCount++;
      afterEveryBuildContext = ctx.toString();
    });

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(notifierVal.value),
    );
  }
}

/// Test widget for callAfterEveryBuild with cancel
class _CallAfterEveryBuildWithCancelTestWidget extends StatelessWidget
    with WatchItMixin {
  const _CallAfterEveryBuildWithCancelTestWidget();

  @override
  Widget build(BuildContext context) {
    // Watch something to ensure the widget can rebuild
    final notifierVal = watch(valNotifier);

    callAfterEveryBuild((ctx, cancel) {
      afterEveryBuildCallCount++;
      afterEveryBuildContext = ctx.toString();

      // Cancel on second call
      if (afterEveryBuildCallCount >= 2) {
        afterEveryBuildCancelled = true;
        cancel();
      }
    });

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(notifierVal.value),
    );
  }
}

/// Test widget for watchPropertyValue with changing target
class _WatchPropertyValueChangeWidget extends StatelessWidget
    with WatchItMixin {
  final bool useFirst;
  final VoidCallback onSwitch;

  const _WatchPropertyValueChangeWidget({
    required this.useFirst,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    // Get different notifiers based on useFirst
    final notifier = useFirst
        ? GetIt.I<ValueNotifier<int>>()
        : GetIt.I<ValueNotifier<int>>(instanceName: 'second');

    // watchPropertyValue with a changing target will dispose the old subscription
    final value = watchPropertyValue<ValueNotifier<int>, int>(
      (n) => n.value,
      target: notifier,
    );

    return GestureDetector(
      onTap: onSwitch,
      child: Text('$value'),
    );
  }
}

/// Test widget for registerHandler with allowObservableChange: true
class _ObservableChangeAllowedWidget extends StatelessWidget with WatchItMixin {
  final bool useFirst;
  final VoidCallback onSwitch;
  final void Function(int) onValue;

  const _ObservableChangeAllowedWidget({
    required this.useFirst,
    required this.onSwitch,
    required this.onValue,
  });

  @override
  Widget build(BuildContext context) {
    // Get different notifiers based on useFirst - this changes the observable
    final notifier = useFirst
        ? GetIt.I<ValueNotifier<int>>()
        : GetIt.I<ValueNotifier<int>>(instanceName: 'second');

    // registerHandler with allowObservableChange: true allows switching observables
    // This will dispose when observable changes
    registerHandler<ValueNotifier<int>, int>(
      select: null, // null means the target itself is the ValueListenable
      target: notifier,
      allowObservableChange: true,
      executeImmediately: true,
      handler: (context, value, cancel) {
        onValue(value);
      },
    );

    return GestureDetector(
      onTap: onSwitch,
      child: const Text('Widget'),
    );
  }
}

/// Test widget for registerHandler error when observable changes
class _ObservableChangeErrorWidget extends StatelessWidget with WatchItMixin {
  final bool useFirst;
  final VoidCallback onSwitch;

  const _ObservableChangeErrorWidget({
    required this.useFirst,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    // Get different notifiers based on useFirst
    final notifier = useFirst
        ? GetIt.I<ValueNotifier<int>>()
        : GetIt.I<ValueNotifier<int>>(instanceName: 'second');

    // registerHandler with allowObservableChange: false (default) will throw when observable changes
    // Using null select means target must be a ValueListenable
    registerHandler<ValueNotifier<int>, int>(
      select: null, // null means the target itself is the ValueListenable
      target: notifier,
      allowObservableChange:
          false, // This will cause StateError on observable change
      handler: (context, value, cancel) {
        // Handler won't be reached because StateError is thrown first
      },
    );

    return GestureDetector(
      onTap: onSwitch,
      child: const Text('Widget'),
    );
  }
}
