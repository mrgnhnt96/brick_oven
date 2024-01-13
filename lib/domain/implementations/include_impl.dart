import 'package:brick_oven/domain/interfaces/include.dart';

/// {@macro include}
class IncludeImpl extends Include {
  /// {@macro include}
  IncludeImpl(super.config);

  @override
  String apply(String path) {
    final tag = isIf ? '#' : '^';

    final variable = isIf ? $if : ifNot;

    return '{{$tag$variable}}$path{{/$variable}}';
  }
}
