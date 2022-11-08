import 'dart:io';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:brick_oven/domain/brick_yaml_config.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:watcher/watcher.dart';

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
