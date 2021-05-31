import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:weather/core/network/data/apis.dart';
import 'package:weather/core/network/data/models/weather.dart';

class WeatherClient {
  late http.Client client;
  WeatherClient() {
    client = http.Client();
  }
  Future<Weather> weatherAtLocation({required double latitude, required double longitude}) async {
    final url = Uri.parse(Apis.base + Apis.weatherCompact + '?lon=$longitude&lat=$latitude');
    final response = await client.get(url);
    return Weather.fromJson(json.decode(response.body));
  }

  void dispose() => client.close();
}
