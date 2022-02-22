import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';

class MockBrick extends Mock implements Brick {}

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockBrickWatcher extends Mock implements BrickWatcher {}
