import 'package:flutter/material.dart';
import 'package:flutter_weather_demo/weather_manager.dart';
import 'package:watch_it/watch_it.dart';

class WeatherListView extends StatelessWidget with WatchItMixin {
  WeatherListView();
  @override
  Widget build(BuildContext context) {
    final data = watchValue((WeatherManager x) => x.updateWeatherCommand);

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (BuildContext context, int index) {
        final entry = data[index];
        return ListTile(
          title: Text('${entry.cityName}, ${entry.country}'),
          subtitle: Text(entry.description),
          leading: Text(
            entry.icon,
            style: TextStyle(fontSize: 32),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${entry.temperature.toStringAsFixed(1)}°C'),
              Text('${entry.wind.toStringAsFixed(1)} km/h'),
            ],
          ),
        );
      },
    );
  }
}
