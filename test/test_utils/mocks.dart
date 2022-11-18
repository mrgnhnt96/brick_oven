import 'dart:io';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:brick_oven/domain/brick_yaml_config.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:usage/usage_io.dart';
import 'package:watcher/watcher.dart';
import 'package:file/file.dart' as file;

class MockBrick extends Mock implements Brick {}

class MockSource extends Mock implements BrickSource {}

class MockKeyPressListener extends Mock implements KeyPressListener {}

class MockWatcher extends Mock implements BrickWatcher {}

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockBrickWatcher extends Mock implements BrickWatcher {}

class MockProgress extends Mock implements Progress {}

class MockBrickYamlConfig extends Mock implements BrickYamlConfig {}

class MockFileWatcher extends Mock implements FileWatcher {}

class MockStdout extends Mock implements Stdout {}

class MockStdin extends Mock implements Stdin {}

class MockBrickPartial extends Mock implements Partial {}

class MockBrickFile extends Mock implements BrickFile {}

class MockFile extends Mock implements file.File {}

class MockAnalytics extends Mock implements Analytics {}

extension MockAnalyticsX on MockAnalytics {
  void stubMethods() {
    when(() => firstRun).thenReturn(false);

    when(
      () => sendEvent(
        any(),
        any(),
        label: any(named: 'label'),
        parameters: any(named: 'parameters'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) => Future.value());

    when(() => waitForLastPing(timeout: any(named: 'timeout')))
        .thenAnswer((_) => Future.value());
  }
}
