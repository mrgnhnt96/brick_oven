// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'util/cook_all.dart';
import 'util/cook_brick.dart';

void main() {
  group('cook runs gracefully', () {
    const bricks = {
      // 'app_icon': 1,
      // 'bio': 1,
      // 'brick_oven_reference': 1,
      // 'documentation': 4,
      // 'favorite_color': 1,
      // 'flavors': 2,
      'flavors_reference': 2,
      // 'greeting': 1,
      // 'hello': 1,
      // 'hello_world': 3,
      // 'hooks': 1,
      // 'legacy': 1,
      // 'photos': 1,
      // 'plugin': 9,
      // 'plugin_reference': 9,
      // 'random_color': 1,
      // 'simple': 1,
      // 'todos': 3,
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
