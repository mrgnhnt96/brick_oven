// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'util/cook_all.dart';
import 'util/cook_brick.dart';

void main() {
  group('cook runs gracefully', () {
    const bricks = {
      'bio': 1,
      'documentation': 4,
      'favorite_color': 1,
      'flavors': 2,
    };

    for (final brick in bricks.entries) {
      test(
        '"${brick.key}" cook (single)',
        () => cookBrick(brick.key, numberOfFiles: brick.value),
      );
      test(
        '"${brick.key}" cook (all)',
        () => cookAll(brick.key, numberOfFiles: brick.value),
      );
    }
  });
}
