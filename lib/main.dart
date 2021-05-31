import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather/features/weather_loader/presentation/blocs/weather_bloc/weather.dart';

import 'features/weather_loader/presentation/pages/weather_loader_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late WeatherBloc _weatherBloc;

  @override
  void initState() {
    _weatherBloc = WeatherBloc();
    super.initState();
  }

  @override
  void dispose() {
    _weatherBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Know WeatherIt',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          backgroundColor: Colors.white,
          textTheme: TextTheme(
              bodyText1: TextStyle(color: Colors.black, fontSize: 24),
              button: TextStyle(color: Colors.white, fontSize: 12))),
      darkTheme: ThemeData(
          primarySwatch: Colors.lightBlue,
          backgroundColor: Colors.black,
          textTheme: TextTheme(
              bodyText1: TextStyle(color: Colors.white, fontSize: 24),
              button: TextStyle(color: Colors.white, fontSize: 12))),
      home: BlocProvider(
        create: (context) => _weatherBloc,
        child: WeatherLoaderPage(),
      ),
    );
  }
}
