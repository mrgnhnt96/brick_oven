import 'package:brick_oven/domain/interfaces/variable.dart';

/// {@macro variable}
class VariableImpl implements Variable {
  /// {@macro variable}
  const VariableImpl({
    required this.name,
    required this.placeholder,
  });

  @override
  final String name;

  @override
  final String placeholder;
}
