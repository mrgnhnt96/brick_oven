import 'dart:io';

import 'package:brick_oven/src/constants/constants.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/src/version.dart';

void main() {
  test('version matches the pubspec version', () {
    final yaml = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;

    final yamlVersion = yaml.value['version'] as String;

    expect(yamlVersion, packageVersion);
  });

  test('package name matches the pubspec name', () {
    final yaml = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;

    final yamlName = yaml.value['name'] as String;

    expect(yamlName, Constants.packageName);
  });
}
