import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'geometry.g.dart';

@JsonSerializable()
class Geometry extends Equatable {
  final List<double> coordinates;
  Geometry(this.coordinates);
  factory Geometry.fromJson(Map<String, dynamic> json) => _$GeometryFromJson(json);
  Map<String, dynamic> toJson() => _$GeometryToJson(this);

  @override
  List<Object?> get props => [coordinates];
}
