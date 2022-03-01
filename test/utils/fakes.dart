import 'dart:collection';

import 'package:args/args.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';

class FakeYamlList extends Fake with ListMixin<dynamic> implements YamlList {
  FakeYamlList(List list) : _value = list;

  final List _value;

  @override
  List get value => _value;

  @override
  int get length => _value.length;

  @override
  dynamic operator [](int key) => _value[key];
}

class FakeYamlMap extends Fake implements YamlMap {
  FakeYamlMap(Map<String, dynamic> value) : _map = value;
  FakeYamlMap.empty() : _map = <String, dynamic>{};

  final Map<String, dynamic> _map;

  @override
  Map get value => _map;

  @override
  Iterable<MapEntry> get entries => _map.entries;
}

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
