import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/core/network/data/models/weather.dart';
import 'package:weather/core/network/presentation/weather_client.dart';

import 'weather.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc(
      {WeatherClient? client,
      LocationPermissions? permissions,
      Future<SharedPreferences>? preferences,
      GeolocatorPlatform? geoLocator})
      : _weatherClient = client ?? WeatherClient(),
        _permissions = permissions ?? LocationPermissions(),
        _geoLocator = geoLocator ?? GeolocatorPlatform.instance,
        _preferences = preferences ?? SharedPreferences.getInstance(),
        super(CheckingStoredWeather());
  final WeatherClient _weatherClient;
  final LocationPermissions _permissions;
  final Future<SharedPreferences> _preferences;
  final GeolocatorPlatform _geoLocator;
  static const timeoutDuration = Duration(minutes: 5);

  @override
  Stream<WeatherState> mapEventToState(WeatherEvent event) async* {
    yield CheckingStoredWeather();
    final permission = await _permissions.checkPermissionStatus(level: LocationPermissionLevel.locationWhenInUse);
    final gpsAvailable = await _permissions.checkServiceStatus(level: LocationPermissionLevel.locationWhenInUse);
    if (gpsAvailable == ServiceStatus.disabled) {
      // Need to turn gps on
      yield RequestGpsTurnedOn();
    } else if (gpsAvailable == ServiceStatus.notApplicable || gpsAvailable == ServiceStatus.unknown) {
      // No gps or location available at ALL
      yield NoAvailableGpsOnDevice();
    } else {
      if (permission == PermissionStatus.granted) {
        // Go for gps
        final position = await _geoLocator.getCurrentPosition();
        final oldWeather = await _lastFetch();
        if (oldWeather != null) {
          final lat = oldWeather.geometry.coordinates[1];
          final lon = oldWeather.geometry.coordinates[0];
          final distance = Geolocator.distanceBetween(position.latitude, position.longitude, lat, lon);
          if (distance < 500) {
            // Not enough shift in distance, keep data
            yield LoadedWeather(weather: oldWeather, latitude: lat, longitude: lon);
          } else {
            // Enough shift in distance, get new data despite recent
            yield* _yieldCurrentWeather(latitude: position.latitude, longitude: position.longitude);
          }
        } else {
          yield* _yieldCurrentWeather(latitude: position.latitude, longitude: position.longitude);
        }
      } else {
        // Does not have permission to use location
        yield RequestPermissionToUseGps();
      }
    }
  }

  void dispose() => _weatherClient.dispose();

  Future<Weather?> _lastFetch() async {
    final _prefs = await _preferences;
    final data = _prefs.getString('data');
    final timeMillis = _prefs.getInt('time');
    if (data != null && timeMillis != null) {
      final weather = Weather.fromJson(json.decode(data));
      DateTime lastSaved = DateTime.fromMillisecondsSinceEpoch(timeMillis);
      if (lastSaved.add(timeoutDuration).isBefore(DateTime.now())) {
        return null;
      }
      return weather;
    }
    return null;
  }

  Stream<WeatherState> _yieldCurrentWeather({required double latitude, required double longitude}) async* {
    yield LoadingWeather();
    try {
      final weather = await _weatherClient.weatherAtLocation(latitude: latitude, longitude: longitude);
      await _saveData(weather: weather, timeFetched: DateTime.now());
      yield LoadedWeather(weather: weather, latitude: latitude, longitude: longitude);
    } catch (e) {
      yield FailedLoadWeather(error: e.toString());
    }
  }

  /// Stores weather data which include fetch time
  Future<void> _saveData({required Weather weather, required DateTime timeFetched}) async {
    final _prefs = await _preferences;
    _prefs.setString('data', json.encode(weather.toJson()));
    _prefs.setInt('time', timeFetched.millisecondsSinceEpoch);
  }
}
