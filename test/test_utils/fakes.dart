import 'package:args/args.dart';
import 'package:mocktail/mocktail.dart';

class FakeArgResults extends Fake implements ArgResults {
  FakeArgResults({required this.data});

  final Map<String, dynamic> data;

  @override
  dynamic operator [](String key) => data[key];
}

// ignore: prefer_function_declarations_over_variables
final void Function() voidCallback = () {};
