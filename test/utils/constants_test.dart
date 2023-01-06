import 'package:test/test.dart';

import 'package:brick_oven/utils/constants.dart';

void main() {
  group('constants', () {
    test('kIndexValue is correct value', () {
      expect(kIndexValue, '_INDEX_VALUE_');
    });

    test('kDefaultBraces is correct value', () {
      expect(kDefaultBraces, 3);
    });
  });
}
