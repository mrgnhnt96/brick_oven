import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/utils/dependency_injection.dart';

/// runs the brick oven, generating bricks
Future<void> runBrickOven(List<String> arguments) async {
  setupDi();

  di
    ..registerLazySingleton<FileSystem>(LocalFileSystem.new)
    ..registerLazySingleton<PubUpdater>(PubUpdater.new)
    ..registerLazySingleton<Logger>(Logger.new);

  final runner = BrickOvenRunner();

  final exitCode = await runner.run(arguments);

  if (exitCode == ExitCode.tempFail.code) {
    await runBrickOven(arguments);
  }

  await flushThenExit(ExitCode.success.code);
}

/// Flushes the stdout and stderr streams, then exits the program with the given
/// status code.
///
/// This returns a Future that will never complete, since the program will have
/// exited already. This is useful to prevent Future chains from proceeding
/// after you've decided to exit.
Future<void> flushThenExit(int status) {
  return Future.wait<void>([stdout.close(), stderr.close()])
      .then<void>((_) => exit(status));
}
