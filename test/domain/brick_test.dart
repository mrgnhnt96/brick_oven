// ignore_for_file: unnecessary_cast

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:test/test.dart';

import '../utils/fakes.dart';
import '../utils/to_yaml.dart';

void main() {
  group('#fromYaml', () {
    test('parses when provided', () {
      final brick = Brick(
        configuredDirs: [BrickPath(name: 'name', path: 'path/to/dir')],
        configuredFiles: const [BrickFile('file/path/name.dart')],
        name: 'brick',
        source: const BrickSource(localPath: 'localPath'),
      );

      final data = brick.toYaml();

      final result = Brick.fromYaml(brick.name, data);

      expectLater(result, brick);
    });

    test('throws argument error when extra keys are provided', () {
      final brick = Brick(
        configuredDirs: [BrickPath(name: 'name', path: 'path/to/dir')],
        configuredFiles: const [BrickFile('file/path/name.dart')],
        name: 'brick',
        source: const BrickSource(localPath: 'localPath'),
      );

      final data = brick.toJson();
      data['extra'] = 'extra';
      final yaml = FakeYamlMap(data);

      expect(() => Brick.fromYaml(brick.name, yaml), throwsArgumentError);
    });
  });

  group('#writeBrick', () {
    test('checks for directory bricks/{name}/__brick__', () {});

    test('deletes directory if exists', () {});

    test('loops through files to write', () {});
  });
}
