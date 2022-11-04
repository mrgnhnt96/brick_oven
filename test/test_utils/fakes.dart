import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:mocktail/mocktail.dart';

class FakeArgResults extends Fake implements ArgResults {
  FakeArgResults({required this.data});

  final Map<String, dynamic> data;

  @override
  dynamic operator [](String key) => data[key];
}

class FakeBrick extends Fake implements Brick {}

// ignore: prefer_function_declarations_over_variables
final void Function() voidCallback = () {};

class FakeBrickSource extends Fake implements BrickSource {
  FakeBrickSource(this.watcher);

  @override
  final BrickWatcher watcher;
}
