import 'package:flutter/material.dart';
import 'package:flutter_weather_demo/weather_manager.dart';
import 'package:watch_it/watch_it.dart';

import 'homepage.dart';

void main() {
  registerManager();
  runApp(MyApp());
  enableSubTreeTracing = true;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: WatchItSubTreeTraceControl(
        logRebuilds: true,
        logHandlers: true,
        logHelperFunctions: true,
        child: HomePage(),
      ),
    );
  }
}

void registerManager() {
  GetIt.I.registerSingleton<WeatherManager>(WeatherManager());
}
