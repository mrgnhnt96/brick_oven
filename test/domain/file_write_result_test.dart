import 'package:test/test.dart';

import 'package:brick_oven/domain/file_write_result.dart';

void main() {
  group(FileWriteResult, () {
    test('can be instantiated', () {
      final usedPartials = <String>{'hi'};
      final usedVariables = <String>{'dude'};

      final result = FileWriteResult(
        usedPartials: usedPartials,
        usedVariables: usedVariables,
      );

      expect(result.usedPartials, usedPartials);
      expect(result.usedVariables, usedVariables);
    });

    test('#empty can be instantiated', () {
      const result = FileWriteResult.empty();

      expect(result.usedPartials, isEmpty);
      expect(result.usedVariables, isEmpty);
    });
  });
}
