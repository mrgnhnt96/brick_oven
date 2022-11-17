import 'dart:io';

import 'package:brick_oven/src/version.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

import 'package:brick_oven/src/runner.dart';
import 'package:usage/usage_io.dart';

const _gaTrackingId = 'UA-134218670-3';

/// runs the brick oven, generating bricks
Future<void> runBrickOven(List<String> arguments) async {
  final exitCode = await BrickOvenRunner(
    logger: Logger(),
    pubUpdater: PubUpdater(),
    fileSystem: const LocalFileSystem(),
    analytics: AnalyticsIO(
      _gaTrackingId,
      packageName,
      packageVersion,
    ),
  ).run(arguments);

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
