import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/core/network/data/models/weather.dart';
import 'package:weather/core/network/presentation/weather_client.dart';
import 'package:weather/features/weather_loader/presentation/blocs/weather_bloc/weather.dart';

class MockedClient extends Mock implements WeatherClient {}

class MockedPermissions extends Mock implements LocationPermissions {}

class MockedPreferences extends Mock implements SharedPreferences {}

class MockedGeoLocator extends Mock implements GeolocatorPlatform {}

final mockedClient = MockedClient();
final mockedPermissions = MockedPermissions();
final mockedPreferences = MockedPreferences();
final mockedGeoLocator = MockedGeoLocator();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Initial state', () {
    expect(
      _mockedWeatherBloc.state,
      CheckingStoredWeather(),
    );
  });

  blocTest<WeatherBloc, WeatherState>(
    'Gps is turned off completely (but exists), return request to go to gps to turn it on',
    build: () => _mockedWeatherBloc,
    act: (bloc) async {
      when(() => mockedPermissions.checkPermissionStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(PermissionStatus.granted));
      when(() => mockedPermissions.checkServiceStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(ServiceStatus.disabled));
      bloc.add(RequestWeather());
    },
    expect: () => [CheckingStoredWeather(), RequestGpsTurnedOn()],
  );

  blocTest<WeatherBloc, WeatherState>(
    'Gps is turned off completely (and does not exist), return request to go to gps to turn it on',
    build: () => _mockedWeatherBloc,
    act: (bloc) async {
      when(() => mockedPermissions.checkPermissionStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(PermissionStatus.granted));
      when(() => mockedPermissions.checkServiceStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(ServiceStatus.notApplicable));
      bloc.add(RequestWeather());
    },
    expect: () => [CheckingStoredWeather(), NoAvailableGpsOnDevice()],
  );

  blocTest<WeatherBloc, WeatherState>(
    'Gps is turned on, but no permission is granted. Request permission',
    build: () => _mockedWeatherBloc,
    act: (bloc) async {
      when(() => mockedPermissions.checkPermissionStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(PermissionStatus.denied));
      when(() => mockedPermissions.checkServiceStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(ServiceStatus.enabled));
      bloc.add(RequestWeather());
    },
    expect: () => [CheckingStoredWeather(), RequestPermissionToUseGps()],
  );

  blocTest<WeatherBloc, WeatherState>(
    'Gps is turned on but permission is restricted. Request permission',
    build: () => _mockedWeatherBloc,
    act: (bloc) async {
      when(() => mockedPermissions.checkPermissionStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(PermissionStatus.restricted));
      when(() => mockedPermissions.checkServiceStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(ServiceStatus.enabled));
      bloc.add(RequestWeather());
    },
    expect: () => [CheckingStoredWeather(), RequestPermissionToUseGps()],
  );

  blocTest<WeatherBloc, WeatherState>(
    'Gps is turned on and permission is granted. Stored weather is close to actual pos and not stale',
    build: () => _mockedWeatherBloc,
    act: (bloc) async {
      final nonStaleTime = DateTime.now().subtract(const Duration(minutes: 4));
      when(() => mockedPermissions.checkPermissionStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(PermissionStatus.granted));
      when(() => mockedPermissions.checkServiceStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(ServiceStatus.enabled));
      when(() => mockedPreferences.getInt('time')).thenReturn(nonStaleTime.millisecondsSinceEpoch);
      when(() => mockedPreferences.getString('data')).thenReturn(fakeWeather(10, 12));
      when(() => mockedGeoLocator.getCurrentPosition()).thenAnswer((_) => Future.value(fakePosition(10, 12)));
      bloc.add(RequestWeather());
    },
    expect: () => [
      CheckingStoredWeather(),
      LoadedWeather(latitude: 10, longitude: 12, weather: Weather.fromJson(json.decode(fakeWeather(10, 12))))
    ],
    verify: (bloc) async {
      verifyNever(() => mockedClient.weatherAtLocation(latitude: 10, longitude: 12));
    },
  );

  blocTest<WeatherBloc, WeatherState>(
    'Gps is turned on and permission is granted. Stored weather is far away from actual pos and not stale',
    build: () => _mockedWeatherBloc,
    act: (bloc) async {
      final nonStaleTime = DateTime.now().subtract(const Duration(minutes: 4));
      when(() => mockedPermissions.checkPermissionStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(PermissionStatus.granted));
      when(() => mockedPermissions.checkServiceStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(ServiceStatus.enabled));
      when(() => mockedPreferences.getInt('time')).thenReturn(nonStaleTime.millisecondsSinceEpoch);
      when(() => mockedPreferences.getString('data')).thenReturn(fakeWeather(10, 12));
      when(() => mockedPreferences.setInt(any(), any())).thenAnswer((_) => Future.value(true));
      when(() => mockedPreferences.setString(any(), any())).thenAnswer((_) => Future.value(true));
      when(() => mockedGeoLocator.getCurrentPosition()).thenAnswer((_) => Future.value(fakePosition(20, 12)));
      when(() => mockedClient.weatherAtLocation(latitude: any(named: 'latitude'), longitude: any(named: 'longitude')))
          .thenAnswer((_) => Future.value(Weather.fromJson(json.decode(fakeWeather(20, 12)))));
      bloc.add(RequestWeather());
    },
    expect: () => [
      CheckingStoredWeather(),
      LoadingWeather(),
      LoadedWeather(latitude: 20, longitude: 12, weather: Weather.fromJson(json.decode(fakeWeather(20, 12))))
    ],
    verify: (bloc) async {
      verify(() => mockedClient.weatherAtLocation(latitude: 20, longitude: 12)).called(1);
      verify(() => mockedPreferences.setString(any(), any())).called(1);
      verify(() => mockedPreferences.setInt(any(), any())).called(1);
    },
  );

  blocTest<WeatherBloc, WeatherState>(
    'Gps is turned on and permission is granted. Stored weather is missing',
    build: () => _mockedWeatherBloc,
    act: (bloc) async {
      when(() => mockedPermissions.checkPermissionStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(PermissionStatus.granted));
      when(() => mockedPermissions.checkServiceStatus(level: LocationPermissionLevel.locationWhenInUse))
          .thenAnswer((_) => Future.value(ServiceStatus.enabled));
      when(() => mockedPreferences.getInt('time')).thenReturn(null);
      when(() => mockedPreferences.getString('data')).thenReturn(null);
      when(() => mockedPreferences.setInt(any(), any())).thenAnswer((_) => Future.value(true));
      when(() => mockedPreferences.setString(any(), any())).thenAnswer((_) => Future.value(true));
      when(() => mockedGeoLocator.getCurrentPosition()).thenAnswer((_) => Future.value(fakePosition(10, 12)));
      when(() => mockedClient.weatherAtLocation(latitude: any(named: 'latitude'), longitude: any(named: 'longitude')))
          .thenAnswer((_) => Future.value(Weather.fromJson(json.decode(fakeWeather(10, 12)))));
      bloc.add(RequestWeather());
    },
    expect: () => [
      CheckingStoredWeather(),
      LoadingWeather(),
      LoadedWeather(latitude: 10, longitude: 12, weather: Weather.fromJson(json.decode(fakeWeather(10, 12))))
    ],
    verify: (bloc) async {
      verify(() => mockedClient.weatherAtLocation(latitude: 10, longitude: 12)).called(1);
      verify(() => mockedPreferences.setString(any(), any())).called(1);
      verify(() => mockedPreferences.setInt(any(), any())).called(1);
    },
  );
}

WeatherBloc get _mockedWeatherBloc => WeatherBloc(
    client: mockedClient,
    permissions: mockedPermissions,
    preferences: Future.value(mockedPreferences),
    geoLocator: mockedGeoLocator);

Position fakePosition(double lat, double lon) => Position(
    latitude: lat,
    longitude: lon,
    accuracy: 0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    timestamp: DateTime.now());

String fakeWeather(double lat, double lon) => '''{
    "type": "Feature",
"geometry": {
"type": "Point",
"coordinates": [
$lon,
$lat,
195
]
},
"properties": {
"meta": {
"updated_at": "2021-05-29T13:01:40Z",
"units": {
"air_pressure_at_sea_level": "hPa",
"air_temperature": "celsius",
"cloud_area_fraction": "%",
"precipitation_amount": "mm",
"relative_humidity": "%",
"wind_from_direction": "degrees",
"wind_speed": "m/s"
}
},
"timeseries": [
{
"time": "2021-05-29T19:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.3,
"air_temperature": 31.3,
"cloud_area_fraction": 81.2,
"relative_humidity": 56.6,
"wind_from_direction": 172,
"wind_speed": 0.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-29T20:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009,
"air_temperature": 30.5,
"cloud_area_fraction": 32,
"relative_humidity": 63.8,
"wind_from_direction": 147,
"wind_speed": 1.1
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-29T21:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009.4,
"air_temperature": 29.7,
"cloud_area_fraction": 35.9,
"relative_humidity": 66.3,
"wind_from_direction": 130.2,
"wind_speed": 1.2
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-29T22:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009.3,
"air_temperature": 29.8,
"cloud_area_fraction": 86.7,
"relative_humidity": 63.6,
"wind_from_direction": 122.3,
"wind_speed": 1.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-29T23:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.6,
"air_temperature": 30,
"cloud_area_fraction": 99.2,
"relative_humidity": 61.3,
"wind_from_direction": 152.7,
"wind_speed": 1.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T00:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.8,
"air_temperature": 30.1,
"cloud_area_fraction": 95.3,
"relative_humidity": 64,
"wind_from_direction": 135.7,
"wind_speed": 1.3
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T01:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.1,
"air_temperature": 29.7,
"cloud_area_fraction": 70.3,
"relative_humidity": 65.9,
"wind_from_direction": 102.1,
"wind_speed": 1.1
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T02:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.7,
"air_temperature": 28.8,
"cloud_area_fraction": 45.3,
"relative_humidity": 70.6,
"wind_from_direction": 92.5,
"wind_speed": 1.3
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T03:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.9,
"air_temperature": 28.4,
"cloud_area_fraction": 19.5,
"relative_humidity": 72.3,
"wind_from_direction": 86,
"wind_speed": 0.9
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T04:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.2,
"air_temperature": 27.6,
"cloud_area_fraction": 18.7,
"relative_humidity": 77.2,
"wind_from_direction": 77.5,
"wind_speed": 0.9
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T05:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.7,
"air_temperature": 27.4,
"cloud_area_fraction": 7,
"relative_humidity": 79.7,
"wind_from_direction": 92.1,
"wind_speed": 0.9
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T06:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.4,
"air_temperature": 29,
"cloud_area_fraction": 0,
"relative_humidity": 72,
"wind_from_direction": 100.8,
"wind_speed": 0.8
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T07:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009.1,
"air_temperature": 31,
"cloud_area_fraction": 0,
"relative_humidity": 58.5,
"wind_from_direction": 98,
"wind_speed": 0.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T08:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009.3,
"air_temperature": 32.7,
"cloud_area_fraction": 0,
"relative_humidity": 52.5,
"wind_from_direction": 162.4,
"wind_speed": 1.1
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T09:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009.1,
"air_temperature": 34.4,
"cloud_area_fraction": 14.1,
"relative_humidity": 47,
"wind_from_direction": 169.6,
"wind_speed": 1.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T10:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.3,
"air_temperature": 36.1,
"cloud_area_fraction": 36.7,
"relative_humidity": 40.6,
"wind_from_direction": 162.1,
"wind_speed": 1.4
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T11:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.2,
"air_temperature": 37.5,
"cloud_area_fraction": 37.5,
"relative_humidity": 34.9,
"wind_from_direction": 125.3,
"wind_speed": 0.8
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T12:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1005.9,
"air_temperature": 38.4,
"cloud_area_fraction": 5.5,
"relative_humidity": 32.1,
"wind_from_direction": 115.6,
"wind_speed": 0.5
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T13:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1004.6,
"air_temperature": 39.4,
"cloud_area_fraction": 11.7,
"relative_humidity": 28.3,
"wind_from_direction": 275.1,
"wind_speed": 0.7
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T14:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1003.3,
"air_temperature": 40.1,
"cloud_area_fraction": 32.8,
"relative_humidity": 21.6,
"wind_from_direction": 268.8,
"wind_speed": 0.8
}
},
"next_12_hours": {
"summary": {
"symbol_code": "clearsky_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T15:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1002.4,
"air_temperature": 40.2,
"cloud_area_fraction": 26.6,
"relative_humidity": 19.9,
"wind_from_direction": 173.3,
"wind_speed": 1.4
}
},
"next_12_hours": {
"summary": {
"symbol_code": "clearsky_night"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T16:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1002.3,
"air_temperature": 39,
"cloud_area_fraction": 18.7,
"relative_humidity": 24.5,
"wind_from_direction": 177.3,
"wind_speed": 2.4
}
},
"next_12_hours": {
"summary": {
"symbol_code": "clearsky_night"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T17:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1002.8,
"air_temperature": 36.8,
"cloud_area_fraction": 16.4,
"relative_humidity": 30.6,
"wind_from_direction": 183.6,
"wind_speed": 3.5
}
},
"next_12_hours": {
"summary": {
"symbol_code": "clearsky_night"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T18:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1003.3,
"air_temperature": 34.4,
"cloud_area_fraction": 14.8,
"relative_humidity": 34.8,
"wind_from_direction": 158.9,
"wind_speed": 1.8
}
},
"next_12_hours": {
"summary": {
"symbol_code": "clearsky_night"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T19:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1004,
"air_temperature": 32.5,
"cloud_area_fraction": 13.3,
"relative_humidity": 43.4,
"wind_from_direction": 111.6,
"wind_speed": 2
}
},
"next_12_hours": {
"summary": {
"symbol_code": "clearsky_night"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T20:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1005,
"air_temperature": 33.3,
"cloud_area_fraction": 10.9,
"relative_humidity": 41.8,
"wind_from_direction": 81.9,
"wind_speed": 0.7
}
},
"next_12_hours": {
"summary": {
"symbol_code": "clearsky_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T21:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1005.6,
"air_temperature": 31,
"cloud_area_fraction": 10.2,
"relative_humidity": 50.1,
"wind_from_direction": 31.4,
"wind_speed": 1.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "clearsky_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T22:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1005.9,
"air_temperature": 33,
"cloud_area_fraction": 9.4,
"relative_humidity": 42.3,
"wind_from_direction": 30.2,
"wind_speed": 1
}
},
"next_12_hours": {
"summary": {
"symbol_code": "clearsky_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-30T23:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1005.7,
"air_temperature": 32.1,
"cloud_area_fraction": 7.8,
"relative_humidity": 45.2,
"wind_from_direction": 133.4,
"wind_speed": 0.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "clearsky_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T00:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1005.6,
"air_temperature": 29.4,
"cloud_area_fraction": 7,
"relative_humidity": 56.3,
"wind_from_direction": 127.7,
"wind_speed": 1.8
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T01:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1005.4,
"air_temperature": 29.9,
"cloud_area_fraction": 7,
"relative_humidity": 57.5,
"wind_from_direction": 126.2,
"wind_speed": 1.1
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T02:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1005.3,
"air_temperature": 29.1,
"cloud_area_fraction": 7.8,
"relative_humidity": 63.2,
"wind_from_direction": 116.1,
"wind_speed": 0.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T03:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1005.6,
"air_temperature": 28.9,
"cloud_area_fraction": 7,
"relative_humidity": 65.4,
"wind_from_direction": 85.2,
"wind_speed": 1.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T04:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.1,
"air_temperature": 28.1,
"cloud_area_fraction": 18.7,
"relative_humidity": 70.3,
"wind_from_direction": 87.3,
"wind_speed": 1.3
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T05:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.9,
"air_temperature": 27.8,
"cloud_area_fraction": 10.2,
"relative_humidity": 73.9,
"wind_from_direction": 97.1,
"wind_speed": 1.7
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T06:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.9,
"air_temperature": 29.7,
"cloud_area_fraction": 4.7,
"relative_humidity": 68.1,
"wind_from_direction": 120.8,
"wind_speed": 1.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T07:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.7,
"air_temperature": 31,
"cloud_area_fraction": 3.1,
"relative_humidity": 60.7,
"wind_from_direction": 161.2,
"wind_speed": 1.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T08:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009,
"air_temperature": 32.5,
"cloud_area_fraction": 1.6,
"relative_humidity": 56.8,
"wind_from_direction": 188.5,
"wind_speed": 1.8
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T09:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.7,
"air_temperature": 34.7,
"cloud_area_fraction": 3.1,
"relative_humidity": 50.2,
"wind_from_direction": 214.1,
"wind_speed": 1.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T10:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.6,
"air_temperature": 36.8,
"cloud_area_fraction": 10.2,
"relative_humidity": 41.3,
"wind_from_direction": 233.3,
"wind_speed": 1.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T11:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.2,
"air_temperature": 38.5,
"cloud_area_fraction": 15.6,
"relative_humidity": 32.6,
"wind_from_direction": 251.8,
"wind_speed": 1.8
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T12:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1004.7,
"air_temperature": 39.6,
"cloud_area_fraction": 86.7,
"relative_humidity": 28.6,
"wind_from_direction": 259.9,
"wind_speed": 2.3
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T13:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1003.3,
"air_temperature": 39.2,
"cloud_area_fraction": 69.5,
"relative_humidity": 28.4,
"wind_from_direction": 247.3,
"wind_speed": 2.2
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T14:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1002.4,
"air_temperature": 40,
"cloud_area_fraction": 32.8,
"relative_humidity": 25.9,
"wind_from_direction": 356.6,
"wind_speed": 0.5
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T15:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1002,
"air_temperature": 39.4,
"cloud_area_fraction": 27.3,
"relative_humidity": 25,
"wind_from_direction": 61.9,
"wind_speed": 1.4
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T16:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1002.2,
"air_temperature": 38.4,
"cloud_area_fraction": 29.7,
"relative_humidity": 28.7,
"wind_from_direction": 130.4,
"wind_speed": 3
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T17:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1003.5,
"air_temperature": 36.5,
"cloud_area_fraction": 19.5,
"relative_humidity": 37.2,
"wind_from_direction": 153.1,
"wind_speed": 4.4
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T18:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1004.6,
"air_temperature": 35.6,
"cloud_area_fraction": 11.7,
"relative_humidity": 39.7,
"wind_from_direction": 158,
"wind_speed": 4.1
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T19:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1005.6,
"air_temperature": 34.7,
"cloud_area_fraction": 5.5,
"relative_humidity": 43.3,
"wind_from_direction": 172.8,
"wind_speed": 3.4
}
},
"next_1_hours": {
"summary": {
"symbol_code": "clearsky_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T20:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.6,
"air_temperature": 34,
"cloud_area_fraction": 9.4,
"relative_humidity": 47.2,
"wind_from_direction": 185.9,
"wind_speed": 4.5
}
},
"next_1_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T21:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.5,
"air_temperature": 33,
"cloud_area_fraction": 21.1,
"relative_humidity": 54.1,
"wind_from_direction": 186.7,
"wind_speed": 3.8
}
},
"next_1_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T22:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.9,
"air_temperature": 32.4,
"cloud_area_fraction": 53.1,
"relative_humidity": 55.8,
"wind_from_direction": 193.1,
"wind_speed": 3.3
}
},
"next_1_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-05-31T23:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.3,
"air_temperature": 31.7,
"cloud_area_fraction": 92.2,
"relative_humidity": 59.4,
"wind_from_direction": 185.6,
"wind_speed": 4.1
}
},
"next_1_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-01T00:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.9,
"air_temperature": 30.9,
"cloud_area_fraction": 99.2,
"relative_humidity": 64.1,
"wind_from_direction": 174.1,
"wind_speed": 2.9
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_1_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
},
"next_6_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-01T01:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.5,
"air_temperature": 30.3,
"cloud_area_fraction": 93.7,
"relative_humidity": 66.7,
"wind_from_direction": 142,
"wind_speed": 1.3
}
},
"next_1_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-01T02:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.4,
"air_temperature": 29.8,
"cloud_area_fraction": 87.5,
"relative_humidity": 67.9,
"wind_from_direction": 112,
"wind_speed": 1
}
},
"next_1_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-01T03:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.5,
"air_temperature": 29.4,
"cloud_area_fraction": 95.3,
"relative_humidity": 69.2,
"wind_from_direction": 106.6,
"wind_speed": 1.6
}
},
"next_1_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-01T04:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.4,
"air_temperature": 28.9,
"cloud_area_fraction": 100,
"relative_humidity": 71.8,
"wind_from_direction": 128.7,
"wind_speed": 2.3
}
},
"next_1_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-01T05:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.3,
"air_temperature": 28.5,
"cloud_area_fraction": 93,
"relative_humidity": 73.6,
"wind_from_direction": 164.1,
"wind_speed": 3
}
},
"next_1_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-01T06:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009.2,
"air_temperature": 28.7,
"cloud_area_fraction": 56.2,
"relative_humidity": 72.2,
"wind_from_direction": 184.5,
"wind_speed": 2.5
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-01T12:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1005.1,
"air_temperature": 37.3,
"cloud_area_fraction": 2.3,
"relative_humidity": 38.4,
"wind_from_direction": 229.5,
"wind_speed": 2
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0.3
}
}
}
},
{
"time": "2021-06-01T18:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.1,
"air_temperature": 31,
"cloud_area_fraction": 38.3,
"relative_humidity": 60.6,
"wind_from_direction": 157.2,
"wind_speed": 4.3
}
},
"next_12_hours": {
"summary": {
"symbol_code": "cloudy"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-02T00:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.8,
"air_temperature": 28.1,
"cloud_area_fraction": 93.7,
"relative_humidity": 74.8,
"wind_from_direction": 144.7,
"wind_speed": 2.5
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-02T06:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009.1,
"air_temperature": 28.3,
"cloud_area_fraction": 80.5,
"relative_humidity": 70.8,
"wind_from_direction": 158.1,
"wind_speed": 2.7
}
},
"next_12_hours": {
"summary": {
"symbol_code": "lightrainshowers_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-02T12:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.9,
"air_temperature": 37.1,
"cloud_area_fraction": 60.9,
"relative_humidity": 40.1,
"wind_from_direction": 199.3,
"wind_speed": 1.5
}
},
"next_12_hours": {
"summary": {
"symbol_code": "lightrainshowers_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "lightrainshowers_day"
},
"details": {
"precipitation_amount": 0.6
}
}
}
},
{
"time": "2021-06-02T18:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.6,
"air_temperature": 33,
"cloud_area_fraction": 99.2,
"relative_humidity": 50.1,
"wind_from_direction": 148.2,
"wind_speed": 1.7
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-03T00:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009,
"air_temperature": 29.2,
"cloud_area_fraction": 64.8,
"relative_humidity": 71.7,
"wind_from_direction": 133.5,
"wind_speed": 1.9
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-03T06:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1010.4,
"air_temperature": 28.4,
"cloud_area_fraction": 74.2,
"relative_humidity": 68.6,
"wind_from_direction": 19,
"wind_speed": 0.4
}
},
"next_12_hours": {
"summary": {
"symbol_code": "lightrainshowers_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-03T12:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.2,
"air_temperature": 36.9,
"cloud_area_fraction": 64.1,
"relative_humidity": 41,
"wind_from_direction": 156.1,
"wind_speed": 2.4
}
},
"next_12_hours": {
"summary": {
"symbol_code": "lightrainshowers_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "lightrainshowers_day"
},
"details": {
"precipitation_amount": 0.8
}
}
}
},
{
"time": "2021-06-03T18:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.7,
"air_temperature": 33.3,
"cloud_area_fraction": 70.3,
"relative_humidity": 49.9,
"wind_from_direction": 191.3,
"wind_speed": 2.9
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-04T00:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.3,
"air_temperature": 28.8,
"cloud_area_fraction": 71.1,
"relative_humidity": 70.6,
"wind_from_direction": 112.9,
"wind_speed": 1.3
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-04T06:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009.2,
"air_temperature": 28.7,
"cloud_area_fraction": 64.1,
"relative_humidity": 69,
"wind_from_direction": 111.9,
"wind_speed": 0.9
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-04T12:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.2,
"air_temperature": 38.5,
"cloud_area_fraction": 0,
"relative_humidity": 34.5,
"wind_from_direction": 223.3,
"wind_speed": 3.1
}
},
"next_12_hours": {
"summary": {
"symbol_code": "cloudy"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0.2
}
}
}
},
{
"time": "2021-06-04T18:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.7,
"air_temperature": 34.8,
"cloud_area_fraction": 82,
"relative_humidity": 42.6,
"wind_from_direction": 183.3,
"wind_speed": 3.8
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-05T00:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.8,
"air_temperature": 29.6,
"cloud_area_fraction": 100,
"relative_humidity": 64.5,
"wind_from_direction": 139,
"wind_speed": 2.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "lightrainshowers_night"
},
"details": {
"precipitation_amount": 0.8
}
}
}
},
{
"time": "2021-06-05T06:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1009.9,
"air_temperature": 27.7,
"cloud_area_fraction": 33.6,
"relative_humidity": 75.7,
"wind_from_direction": 125.2,
"wind_speed": 1.7
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-05T12:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1006.7,
"air_temperature": 36.7,
"cloud_area_fraction": 36.7,
"relative_humidity": 39.1,
"wind_from_direction": 234.1,
"wind_speed": 2.1
}
},
"next_12_hours": {
"summary": {
"symbol_code": "rain"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0.2
}
}
}
},
{
"time": "2021-06-05T18:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.1,
"air_temperature": 32.2,
"cloud_area_fraction": 93,
"relative_humidity": 53.6,
"wind_from_direction": 85.4,
"wind_speed": 2.9
}
},
"next_12_hours": {
"summary": {
"symbol_code": "rain"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "heavyrain"
},
"details": {
"precipitation_amount": 16.4
}
}
}
},
{
"time": "2021-06-06T00:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1010.6,
"air_temperature": 25.7,
"cloud_area_fraction": 100,
"relative_humidity": 89,
"wind_from_direction": 305.3,
"wind_speed": 0.2
}
},
"next_12_hours": {
"summary": {
"symbol_code": "lightrain"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "rain"
},
"details": {
"precipitation_amount": 1
}
}
}
},
{
"time": "2021-06-06T06:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1011.1,
"air_temperature": 25.3,
"cloud_area_fraction": 100,
"relative_humidity": 90.3,
"wind_from_direction": 152.7,
"wind_speed": 3.2
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "cloudy"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-06T12:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007.9,
"air_temperature": 32.4,
"cloud_area_fraction": 99.2,
"relative_humidity": 53.8,
"wind_from_direction": 161.5,
"wind_speed": 1.5
}
},
"next_12_hours": {
"summary": {
"symbol_code": "fair_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-06T18:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1007,
"air_temperature": 29.3,
"cloud_area_fraction": 39.8,
"relative_humidity": 66.1,
"wind_from_direction": 145.6,
"wind_speed": 1.6
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_night"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "fair_night"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-07T00:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.9,
"air_temperature": 27.5,
"cloud_area_fraction": 25.8,
"relative_humidity": 77.4,
"wind_from_direction": 145.5,
"wind_speed": 3.1
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "rainshowers_night"
},
"details": {
"precipitation_amount": 1.7
}
}
}
},
{
"time": "2021-06-07T06:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1010.4,
"air_temperature": 26,
"cloud_area_fraction": 53.9,
"relative_humidity": 82.9,
"wind_from_direction": 90.7,
"wind_speed": 0.5
}
},
"next_12_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0
}
}
}
},
{
"time": "2021-06-07T12:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.2,
"air_temperature": 33,
"cloud_area_fraction": 51.6,
"relative_humidity": 54.8,
"wind_from_direction": 113.9,
"wind_speed": 0.8
}
},
"next_6_hours": {
"summary": {
"symbol_code": "partlycloudy_day"
},
"details": {
"precipitation_amount": 0.2
}
}
}
},
{
"time": "2021-06-07T18:00:00Z",
"data": {
"instant": {
"details": {
"air_pressure_at_sea_level": 1008.4,
"air_temperature": 29.7,
"cloud_area_fraction": 99.2,
"relative_humidity": 69.3,
"wind_from_direction": 119.8,
"wind_speed": 1.6
}
}
}
}
]
}
}''';
