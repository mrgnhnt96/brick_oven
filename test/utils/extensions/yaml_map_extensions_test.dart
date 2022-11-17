// ignore_for_file: cascade_invocations

import 'package:brick_oven/utils/extensions/yaml_map_extensions.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('YamlMapX', () {
    final yamlMap = YamlMap.wrap({'key': 'value'});

    test('returns a modifiable Map of the [value]', () {
      expect(yamlMap.value, {'key': 'value'});

      expect(
        () => yamlMap.value['key'] = 'other',
        throwsA(isA<UnsupportedError>()),
      );

      expect(yamlMap.data, isA<Map<String, dynamic>>());

      expect(yamlMap.data, {'key': 'value'});

      expect(() => yamlMap.data['key'] = 'other', returnsNormally);
    });
  });
}
