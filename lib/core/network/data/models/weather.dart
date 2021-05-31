import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'geometry.dart';
import 'properties.dart';

part 'weather.g.dart';

@JsonSerializable()
class Weather extends Equatable {
  final String type;
  final Geometry geometry;
  final Properties properties;

  Weather(this.type, this.geometry, this.properties);
  factory Weather.fromJson(Map<String, dynamic> json) => _$WeatherFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherToJson(this);

  @override
  List<Object?> get props => [type, geometry, properties];
}
