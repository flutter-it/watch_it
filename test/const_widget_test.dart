import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

class Model extends ChangeNotifier {
  String _country;
  Model(this._country);

  String get country => _country;

  set country(String value) {
    _country = value;
    notifyListeners();
  }

  ValueNotifier<int> counter = ValueNotifier<int>(0);
}

/// A const widget that uses WatchItMixin to watch data from get_it
class ConstWidgetWithWatchItMixin extends StatelessWidget with WatchItMixin {
  const ConstWidgetWithWatchItMixin({super.key});

  @override
  Widget build(BuildContext context) {
    final country = watchPropertyValue((Model m) => m.country);
    final counter = watchValue((Model m) => m.counter);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text(country, key: const Key('country')),
          Text(counter.toString(), key: const Key('counter')),
        ],
      ),
    );
  }
}

void main() {
  late Model model;

  setUp(() async {
    await GetIt.I.reset();
    model = Model('Germany');
    GetIt.I.registerSingleton<Model>(model);
  });

  testWidgets('const widget with WatchItMixin rebuilds on property change',
      (tester) async {
    // Use const constructor
    await tester.pumpWidget(const ConstWidgetWithWatchItMixin());
    await tester.pump();

    // Verify initial value
    var countryText =
        tester.widget<Text>(find.byKey(const Key('country'))).data;
    expect(countryText, 'Germany');

    // Change the model
    model.country = 'France';
    await tester.pump();

    // Verify the const widget rebuilt with new value
    countryText = tester.widget<Text>(find.byKey(const Key('country'))).data;
    expect(countryText, 'France');

    // Change again to verify it keeps working
    model.country = 'Spain';
    await tester.pump();

    countryText = tester.widget<Text>(find.byKey(const Key('country'))).data;
    expect(countryText, 'Spain');
  });

  testWidgets('const widget with WatchItMixin rebuilds on ValueNotifier change',
      (tester) async {
    await tester.pumpWidget(const ConstWidgetWithWatchItMixin());
    await tester.pump();

    // Verify initial value
    var counterText =
        tester.widget<Text>(find.byKey(const Key('counter'))).data;
    expect(counterText, '0');

    // Change the counter
    model.counter.value = 5;
    await tester.pump();

    // Verify the const widget rebuilt with new value
    counterText = tester.widget<Text>(find.byKey(const Key('counter'))).data;
    expect(counterText, '5');

    // Change again
    model.counter.value = 10;
    await tester.pump();

    counterText = tester.widget<Text>(find.byKey(const Key('counter'))).data;
    expect(counterText, '10');
  });

  testWidgets('multiple const widget instances both rebuild when data changes',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: const [
            ConstWidgetWithWatchItMixin(key: Key('widget1')),
            ConstWidgetWithWatchItMixin(key: Key('widget2')),
          ],
        ),
      ),
    );
    await tester.pump();

    // Both widgets should rebuild when data changes
    model.country = 'Italy';
    await tester.pump();

    // Find both Text widgets with 'country' key - there should be 2
    final countryTexts =
        tester.widgetList<Text>(find.byKey(const Key('country')));
    expect(countryTexts.length, 2);

    // Both should show the updated value
    for (final text in countryTexts) {
      expect(text.data, 'Italy');
    }
  });
}
