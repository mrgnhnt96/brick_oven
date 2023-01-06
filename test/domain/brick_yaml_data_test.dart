import 'package:test/test.dart';

import 'package:brick_oven/domain/brick_yaml_data.dart';

void main() {
  test('can be instantiated', () {
    expect(
      () => const BrickYamlData(name: 'Duh doy', vars: ['Mah doy', 'Yah doy']),
      returnsNormally,
    );
  });
}
