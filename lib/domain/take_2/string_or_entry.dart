import 'package:equatable/equatable.dart';

part 'string_or_entry.g.dart';

class StringOr<T extends Object> extends Equatable {
  const StringOr({
    this.string,
    this.object,
  });

  factory StringOr.fromJson(
    dynamic json,
    T Function(Object? value) fromJsonT,
  ) {
    if (json is String) {
      return StringOr<T>(string: json);
    } else if (json is Map) {
      return StringOr<T>(object: fromJsonT(json));
    } else {
      throw ArgumentError.value(
        json,
        'json',
        'Must be a String or Map',
      );
    }
  }

  final String? string;
  final T? object;

  bool get isString => string != null;
  bool get isObject => object != null;

  dynamic toJson(
    Object? Function(T value) toJsonT,
  ) {
    if (isString) {
      return string;
    } else if (isObject) {
      return toJsonT(object!);
    } else {
      throw StateError('StringOr must have a value');
    }
  }

  @override
  List<Object?> get props => _$props;
}
