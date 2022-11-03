import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';

part 'brick_yaml_data.g.dart';

/// {@template brick_yaml_data}
/// Represents the data within the `brick.yaml` file
/// {@endtemplate}
@autoequal
class BrickYamlData extends Equatable {
  /// {@macro brick_yaml_data}
  const BrickYamlData({
    required this.name,
    required this.vars,
  });

  /// the name of the brick
  final String name;

  /// the variables within the brick
  final List<String> vars;

  @override
  List<Object?> get props => _$props;
}
