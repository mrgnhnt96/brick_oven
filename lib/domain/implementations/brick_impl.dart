import 'package:file/file.dart' hide Directory;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

import 'package:brick_oven/domain/config/mason_brick_config.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/implementations/directory_impl.dart';
import 'package:brick_oven/domain/implementations/mason_brick_impl.dart';
import 'package:brick_oven/domain/implementations/partial_impl.dart';
import 'package:brick_oven/domain/implementations/source_impl.dart';
import 'package:brick_oven/domain/implementations/url_impl.dart';
import 'package:brick_oven/domain/interfaces/brick.dart';
import 'package:brick_oven/domain/interfaces/directory.dart';
import 'package:brick_oven/domain/interfaces/mason_brick.dart';
import 'package:brick_oven/domain/interfaces/partial.dart';
import 'package:brick_oven/domain/interfaces/source.dart';
import 'package:brick_oven/domain/interfaces/url.dart';
import 'package:brick_oven/domain/source_watcher.dart';
import 'package:brick_oven/utils/constants.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/dependency_injection.dart';

/// {@macro brick}
class BrickImpl extends Brick {
  /// {@macro brick}
  BrickImpl(
    super.config, {
    required this.name,
    required String? outputDir,
    required this.watch,
    required this.shouldSync,
  })  : outputDir = join(outputDir ?? 'bricks', name, '__brick__'),
        masonBrick = config.masonBrickConfig == null
            ? null
            : config.masonBrickConfig!.isString
                ? MasonBrickImpl(
                    MasonBrickConfig(
                      path: config.masonBrickConfig!.string!,
                    ),
                    shouldSync: shouldSync,
                  )
                : MasonBrickImpl(
                    config.masonBrickConfig!.object!,
                    shouldSync: shouldSync,
                  );

  @override
  final String name;

  @override
  final String outputDir;

  @override
  final bool watch;

  @override
  final bool shouldSync;

  @override
  final MasonBrick? masonBrick;

  @override
  Source get source => SourceImpl(
        sourcePath,
        targetDir: outputDir,
        excludePaths: exclude ?? [],
        fileConfigs: fileConfigs ?? {},
      );

  @override
  Iterable<Directory> get directories sync* {
    final configs = directoryConfigs;
    if (configs == null) {
      return;
    }

    for (final MapEntry(key: path, value: config) in configs.entries) {
      yield DirectoryImpl(
        config,
        path: path,
      );
    }
  }

  @override
  Iterable<Url> get urls sync* {
    final configs = urlConfigs;
    if (configs == null) {
      return;
    }

    for (final MapEntry(key: path, value: config) in configs.entries) {
      yield UrlImpl(
        config,
        path: join(sourcePath, path),
      );
    }
  }

  @override
  Iterable<Partial> get partials sync* {
    final configs = partialConfigs;
    if (configs == null) {
      return;
    }

    for (final MapEntry(key: path, value: config) in configs.entries) {
      yield PartialImpl(
        config,
        sourceFile: join(sourcePath, path),
        outputDir: outputDir,
      );
    }
  }

  SourceWatcher? _watcher;
  @override
  SourceWatcher get watcher => _watcher ??= SourceWatcher(sourcePath);

  @override
  void cook() {
    final output = di<FileSystem>().directory(outputDir);
    if (output.existsSync()) {
      output.deleteSync(recursive: true);
    }

    final names = <String>{};

    if (partialConfigs != null) {
      for (final MapEntry(key: fileName) in partialConfigs!.entries) {
        if (names.contains(fileName)) {
          throw BrickException(
            brick: name,
            reason: 'Duplicate partials ("$fileName") in $name',
          );
        }

        names.add(fileName);
      }
    }

    final done = di<Logger>().progress('Writing Brick: $name');

    final excludedPaths = [...?exclude, '__brick__', 'bricks', '.git'];

    if (outputDir != '.') {
      excludedPaths.add(outputDir);
    }

    if (watch) {
      watcher.addEvent(
        (_) => _putInTheOven(
          done: done,
          excludedPaths: excludedPaths.toSet(),
        ),
      );

      if (masonBrick != null) {
        watcher.addEvent((_) => masonBrick?.check(this));
      }

      watcher.start(excludedPaths);

      if (watcher.hasRun) {
        return;
      }
    }

    _putInTheOven(
      done: done,
      excludedPaths: excludedPaths.toSet(),
    );
    masonBrick?.check(this);
  }

  void _fail(Progress progress, String type, String path) {
    progress.fail(
      '${darkGray.wrap('($name)')} '
      'Failed to write $type: $path',
    );
  }

  void _putInTheOven({
    required Progress done,
    required Set<String> excludedPaths,
  }) {
    final targetFiles = source.combineFiles();
    final count = targetFiles.length;

    final usedVariables = <String>{};
    final usedPartials = <String>{};

    final partialPaths = {...?partialConfigs?.keys};

    for (final file in targetFiles) {
      if (partialPaths.contains(file.sourcePath)) {
        // skip partial file generation
        continue;
      }

      FileWriteResult writeResult;

      try {
        writeResult = file.write(
          brick: this,
          outOfFileVariables: Constants.defaultVariables,
        );
      } on ConfigException catch (e) {
        _fail(done, 'file', file.sourcePath);

        throw BrickException(
          brick: name,
          reason: e.message,
        );
      } catch (_) {
        _fail(done, 'file', file.sourcePath);
        rethrow;
      }

      usedVariables.addAll(writeResult.usedVariables);
      usedPartials.addAll(writeResult.usedPartials);
    }

    for (final partial in partials) {
      FileWriteResult writeResult;
      try {
        writeResult = partial.write(
          partials: partials,
          outOfFileVariables: Constants.defaultVariables,
        );
      } on ConfigException catch (e) {
        _fail(done, 'partial', partial.sourceFile);
        throw BrickException(
          brick: name,
          reason: e.message,
        );
      } catch (_) {
        _fail(done, 'partial', partial.sourceFile);

        rethrow;
      }

      usedPartials.addAll(writeResult.usedPartials);
      usedVariables.addAll(writeResult.usedVariables);
    }

    final partialNames = partialConfigs?.keys.toSet() ?? {};

    final unusedVariables = {...vars}.difference(usedVariables);
    final unusedPartials = partialNames.difference(usedPartials);

    if (unusedVariables.isNotEmpty) {
      final vars = '"${unusedVariables.join('", "')}"';
      di<Logger>().warn(
        'Unused variables ($vars) in $name',
      );
    }

    if (unusedPartials.isNotEmpty) {
      final partials = '"${unusedPartials.map(basename).join('", "')}"';
      di<Logger>().warn(
        'Unused partials ($partials) in $name',
      );
    }

    done.complete(
      '${cyan.wrap(name)}: cooked '
      '${yellow.wrap('$count')} file${count == 1 ? '' : 's'}',
    );
  }
}
