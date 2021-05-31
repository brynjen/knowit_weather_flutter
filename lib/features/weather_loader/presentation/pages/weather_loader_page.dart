import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:weather/core/network/data/models/weather.dart';
import 'package:weather/features/weather_loader/presentation/blocs/weather_bloc/weather.dart';
import 'package:weather/features/weather_loader/presentation/widgets/need_gps_on_dialog.dart';
import 'package:weather/features/weather_loader/presentation/widgets/need_permission_dialog.dart';

class WeatherLoaderPage extends StatefulWidget {
  @override
  _WeatherLoaderPageState createState() => _WeatherLoaderPageState();
}

class _WeatherLoaderPageState extends State<WeatherLoaderPage> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    BlocProvider.of<WeatherBloc>(context).add(RequestWeather());
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      BlocProvider.of<WeatherBloc>(context).add(RequestWeather());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: BlocConsumer<WeatherBloc, WeatherState>(
        listener: (_, state) {
          if (state is RequestGpsTurnedOn) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => NeedGpsServiceDialog(onConfirm: () async {
                final canOpen = await Geolocator.openLocationSettings();
                if (!canOpen) {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (_) => Dialog(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Klarer ikke å åpne lokasjonssettings',
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                      ),
                    ),
                  );
                } else {}
              }),
            );
          }
          if (state is RequestPermissionToUseGps) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => NeedPermissionDialog(
                onConfirm: () async {
                  await LocationPermissions().requestPermissions(
                    permissionLevel: LocationPermissionLevel.locationWhenInUse,
                  );
                  BlocProvider.of<WeatherBloc>(context).add(RequestWeather());
                },
              ),
            );
          }
        },
        builder: (_, state) {
          if (state is CheckingStoredWeather) {
            return _CheckLocalStorage();
          }
          if (state is FailedLoadWeather) {
            return _FailedLoadWeather(error: state.error);
          }
          if (state is LoadedWeather) {
            return _LoadedWeather(weather: state.weather, latitude: state.latitude, longitude: state.longitude);
          }
          return _LoadingWeather();
        },
      ),
    );
  }
}

class _CheckLocalStorage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Sjekker sist lagret', style: Theme.of(context).textTheme.bodyText1),
        ],
      ),
    );
  }
}

class _LoadingWeather extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Henter nytt vær nær deg', style: Theme.of(context).textTheme.bodyText1),
        ],
      ),
    );
  }
}

class _FailedLoadWeather extends StatelessWidget {
  _FailedLoadWeather({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Feilet å hente værdata: $error', style: Theme.of(context).textTheme.bodyText1),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () => BlocProvider.of<WeatherBloc>(context).add(RequestWeather()),
                child: Text('Prøv igjen', style: Theme.of(context).textTheme.bodyText1)),
          ],
        ),
      ),
    );
  }
}

class _LoadedWeather extends StatelessWidget {
  const _LoadedWeather({required this.weather, required this.latitude, required this.longitude});

  final Weather weather;
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final period = weather.properties.timeSeries[0].data.next1hours;
    final double degrees = weather.properties.timeSeries[0].data.instant.details!['air_temperature'];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/png/${period!.summary.symbolCode}.png', width: 200),
          const SizedBox(height: 20),
          Text('$degrees', style: Theme.of(context).textTheme.bodyText1),
        ],
      ),
    );
  }
}
