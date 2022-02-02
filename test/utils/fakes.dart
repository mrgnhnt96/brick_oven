import 'package:mocktail/mocktail.dart';
import 'package:yaml/yaml.dart';

class FakeYamlMap extends Fake implements YamlMap {
  FakeYamlMap(Map<String, dynamic> value) : _map = value;

  final Map<String, dynamic> _map;

  @override
  Map get value => _map;

  @override
  Iterable<MapEntry> get entries => _map.entries;
}
