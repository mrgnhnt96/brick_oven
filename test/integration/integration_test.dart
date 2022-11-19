// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'util/cook_all.dart';
import 'util/cook_brick.dart';

void main() {
  group('cook runs gracefully', () {
    const bricks = [
      'bio',
    ];

    for (final brick in bricks) {
      test('$brick cook (single)', () => cookBrick(brick));
      test('$brick cook (all)', () => cookAll(brick));
    }
  });
}
