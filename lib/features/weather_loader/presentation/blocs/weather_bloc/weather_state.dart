import 'package:equatable/equatable.dart';
import 'package:weather/core/network/data/models/weather.dart';

abstract class WeatherState extends Equatable {
  const WeatherState();

  @override
  List<Object> get props => [];
}

class CheckingStoredWeather extends WeatherState {}

class LoadingWeather extends WeatherState {}

class FailedLoadWeather extends WeatherState {
  FailedLoadWeather({required this.error});

  final String error;

  @override
  List<Object> get props => [error];
}

class LoadedWeather extends WeatherState {
  LoadedWeather({required this.weather, required this.latitude, required this.longitude});

  final Weather weather;
  final double latitude;
  final double longitude;

  @override
  bool? get stringify => true;

  @override
  List<Object> get props => [weather, latitude, longitude];
}

// Gps is not turned on device
class RequestGpsTurnedOn extends WeatherState {}

// This device is unable to use service
class NoAvailableGpsOnDevice extends WeatherState {}

// No permission to use gps, ask for it
class RequestPermissionToUseGps extends WeatherState {}
