// ignore_for_file: cascade_invocations

import 'package:brick_oven/domain/brick_partial.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/enums/mustache_sections.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/file_replacements.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../test_utils/mocks.dart';

void main() {
  late MockLogger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
  });

  late FileSystem fileSystem;
  late File sourceFile;
  late File targetFile;
  const sourceFilePath = 'source.dart';
  const targetFilePath = 'target.dart';
  const defaultContent = 'content';
  const instance = _TestFileReplacements();

  setUp(() {
    fileSystem = MemoryFileSystem();
    sourceFile = fileSystem.file(sourceFilePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(defaultContent);

    targetFile = fileSystem.file(targetFilePath);
  });

  test('copies file when no variables or partials are provided', () {
    instance.writeFile(
      partials: [],
      variables: [],
      sourceFile: sourceFile,
      targetFile: targetFile,
      fileSystem: fileSystem,
      logger: mockLogger,
    );

    expect(targetFile.readAsStringSync(), defaultContent);
  });

  group('#variables', () {
    test('replaces variable placeholders with name', () {
      const newName = 'new-name';
      const placeholder = 'MEEEEE';
      const content = 'replace: $placeholder';

      const variable = Variable(name: newName, placeholder: placeholder);

      sourceFile.writeAsStringSync(content);

      instance.writeFile(
        partials: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [variable],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(targetFile.readAsStringSync(), 'replace: {{$newName}}');
    });

    const formats = [
      'camel',
      'constant',
      'dot',
      'header',
      'lower',
      'pascal',
      'param',
      'path',
      'sentence',
      'snake',
      'title',
      'upper',
    ];

    test('replaces sub string', () {
      const newName = 'new-name';
      const placeholder = '_name_';
      const contents = {
        'x$placeholder': 'x{{$newName}}',
        '${placeholder}s': '{{$newName}}s'
      };
      const variable = Variable(name: newName, placeholder: placeholder);

      for (final content in contents.entries) {
        sourceFile.writeAsStringSync(content.key);
        instance.writeFile(
          partials: [],
          sourceFile: sourceFile,
          targetFile: targetFile,
          variables: [variable],
          fileSystem: fileSystem,
          logger: mockLogger,
        );

        expect(targetFile.readAsStringSync(), content.value);
      }
    });

    test('replaces all occurrences when found in the same line', () {
      const newName = 'new-name';
      const placeholder = 'name';

      const variable = Variable(name: newName, placeholder: placeholder);

      const content =
          '$placeholder 1 $placeholder 2 $placeholder 3 $placeholder/$placeholder.dart';

      sourceFile.writeAsStringSync(content);

      instance.writeFile(
        partials: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [variable],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(
        targetFile.readAsStringSync(),
        '{{$newName}} 1 {{$newName}} 2 {{$newName}} 3 {{$newName}}/{{$newName}}.dart',
      );
    });

    test('replaces loops & vars when found in the same line', () {
      const newName = 'new-name';
      const placeholder = 'name';

      const variable = Variable(name: newName, placeholder: placeholder);

      const content =
          '\n\n\n\nstart$placeholder 1 $placeholder 2 $placeholder 3\n\n\n\n';

      sourceFile.writeAsStringSync(content);

      instance.writeFile(
        partials: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [variable],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(targetFile.readAsStringSync(), '\n{{#$newName}}\n');
    });

    group('formats', () {
      const newName = 'new-name';
      const placeholder = '_SCREEN_';
      const variable = Variable(name: newName, placeholder: placeholder);

      Map<String, String> getContents({
        required String format,
        String prefix = '',
        String suffix = '',
        String before = '',
        String after = '',
      }) {
        final caseFormats = [
          format,
          '${format}Case',
          '${format}CASE'.toUpperCase(),
          '${format}case'.toLowerCase(),
        ];

        final value =
            '$before$prefix{{#${format}Case}}{{{$newName}}}{{/${format}Case}}$suffix$after';

        return caseFormats.fold(<String, String>{}, (p, caseFormat) {
          final key = '$before'
              '$prefix'
              '$placeholder'
              '$caseFormat'
              '$suffix'
              '$after';
          p[key] = value;

          return p;
        });
      }

      for (final format in formats) {
        group('($format)', () {
          test('replaces variable placeholder with name', () {
            final contents = getContents(format: format);

            for (final content in contents.entries) {
              sourceFile.writeAsStringSync(content.key);

              instance.writeFile(
                partials: [],
                sourceFile: sourceFile,
                targetFile: targetFile,
                variables: [variable],
                fileSystem: fileSystem,
                logger: mockLogger,
              );

              expect(
                targetFile.readAsStringSync(),
                content.value,
              );
            }
          });

          test('replaces variable placeholder with name, maintaining prefix',
              () {
            final contents = getContents(format: format, prefix: 'prefix_');

            for (final content in contents.entries) {
              sourceFile.writeAsStringSync(content.key);

              instance.writeFile(
                partials: [],
                sourceFile: sourceFile,
                targetFile: targetFile,
                variables: [variable],
                fileSystem: fileSystem,
                logger: mockLogger,
              );

              expect(
                targetFile.readAsStringSync(),
                content.value,
              );
            }
          });

          test('replaces variable placeholder with name, maintaining suffix',
              () {
            final contents = getContents(format: format, suffix: '_suffix');

            for (final content in contents.entries) {
              sourceFile.writeAsStringSync(content.key);

              instance.writeFile(
                partials: [],
                sourceFile: sourceFile,
                targetFile: targetFile,
                variables: [variable],
                fileSystem: fileSystem,
                logger: mockLogger,
              );

              expect(
                targetFile.readAsStringSync(),
                content.value,
              );
            }
          });

          test(
              'replaces variable placeholder with name, maintaining pre/post text',
              () {
            final contents = getContents(
              format: format,
              before: 'some text before ',
              after: ' some text after',
            );

            for (final content in contents.entries) {
              sourceFile.writeAsStringSync(content.key);

              instance.writeFile(
                partials: [],
                sourceFile: sourceFile,
                targetFile: targetFile,
                variables: [variable],
                fileSystem: fileSystem,
                logger: mockLogger,
              );

              expect(
                targetFile.readAsStringSync(),
                content.value,
              );
            }
          });

          test(
              'replaces variable placeholder with name, maintaining pre/post text and prefix/suffix',
              () {
            final contents = getContents(
              format: format,
              before: 'some text before ',
              after: ' some text after',
            );

            for (final content in contents.entries) {
              sourceFile.writeAsStringSync(content.key);

              instance.writeFile(
                partials: [],
                sourceFile: sourceFile,
                targetFile: targetFile,
                variables: [variable],
                fileSystem: fileSystem,
                logger: mockLogger,
              );

              expect(
                targetFile.readAsStringSync(),
                content.value,
              );
            }
          });
        });
      }
    });

    group('sections', () {
      const newName = 'new-name';
      const placeholder = 'MEEEEE';

      for (final section in MustacheSections.values) {
        Map<String, String> getContent() {
          return {
            '${section.configName}$placeholder':
                '{{${section.symbol}$newName}}',
          };
        }

        group('(${section.name})', () {
          test(
            'replaces variable placeholder',
            () {
              final contents = getContent();

              for (final content in contents.entries) {
                const variable =
                    Variable(name: newName, placeholder: placeholder);

                sourceFile.writeAsStringSync(content.key);

                instance.writeFile(
                  partials: [],
                  sourceFile: sourceFile,
                  targetFile: targetFile,
                  variables: [variable],
                  fileSystem: fileSystem,
                  logger: mockLogger,
                );

                expect(targetFile.readAsStringSync(), content.value);
              }
            },
          );
        });
      }
    });

    test(
      'replaces variable placeholder with section end syntax',
      () {
        const newName = 'new-name';
        const placeholder = 'MEEEEE';
        const content = 'replace: n$placeholder';

        const variable = Variable(name: newName, placeholder: placeholder);

        sourceFile.writeAsStringSync(content);

        instance.writeFile(
          partials: [],
          sourceFile: sourceFile,
          targetFile: targetFile,
          variables: [variable],
          fileSystem: fileSystem,
          logger: mockLogger,
        );

        expect(targetFile.readAsStringSync(), 'replace: {{^$newName}}');
      },
    );

    test(
      'throws error when variable is wrapped with brackets',
      () {
        const newName = 'new-name';
        const placeholder = 'MEEEEE';
        const content = 'replace: {${placeholder}camel}';

        const variable = Variable(name: newName, placeholder: placeholder);

        sourceFile.writeAsStringSync(content);

        void writeFile() {
          instance.writeFile(
            partials: [],
            sourceFile: sourceFile,
            targetFile: targetFile,
            variables: [variable],
            fileSystem: fileSystem,
            logger: mockLogger,
          );
        }

        expect(writeFile, throwsA(isA<FileException>()));
      },
    );
  });

  test('replaces mustache loop comment', () {
    const placeholder = '_HELLO_';
    const replacement = 'hello';

    Map<String, String> lines(String configName, String symbol) {
      final expected = '{{$symbol$replacement}}';
      return {
        '//': expected,
        '#': expected,
        r'\*': expected,
        r'*\': expected,
        '/*': expected,
        '*/': expected,
      }.map((key, value) {
        return MapEntry('$key $configName$placeholder', value);
      });
    }

    final loops = {
      ...lines('start', '#'),
      ...lines('end', '/'),
      ...lines('nstart', '^'),
    };

    const variable = Variable(placeholder: placeholder, name: replacement);

    for (final loop in loops.keys) {
      sourceFile.writeAsStringSync(loop);

      instance.writeFile(
        partials: [],
        sourceFile: sourceFile,
        targetFile: targetFile,
        variables: [variable],
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(targetFile.readAsStringSync(), loops[loop]);
    }
  });

  group('partials', () {
    group('replaces when placeholder is', () {
      test('file name with extension', () {
        const placeholder = 'file.dart';
        const content = '// partial.$placeholder';

        const partial = BrickPartial(path: 'path/to/file.dart');

        sourceFile.writeAsStringSync(content);

        instance.writeFile(
          partials: [partial],
          sourceFile: sourceFile,
          targetFile: targetFile,
          variables: [],
          fileSystem: fileSystem,
          logger: mockLogger,
        );

        expect(targetFile.readAsStringSync(), '{{> file.dart }}');
      });

      test('file name without extension', () {
        const placeholder = 'file';
        const content = '// partial.$placeholder';

        const partial = BrickPartial(path: 'path/to/file.dart');

        sourceFile.writeAsStringSync(content);

        instance.writeFile(
          partials: [partial],
          sourceFile: sourceFile,
          targetFile: targetFile,
          variables: [],
          fileSystem: fileSystem,
          logger: mockLogger,
        );

        expect(targetFile.readAsStringSync(), '{{> file.dart }}');
      });
    });
  });

  test('prints warning if excess variables exist', () {
    verifyNever(() => mockLogger.warn(any()));

    const variable = Variable(placeholder: '_HELLO_', name: 'hello');
    const extraVariable = Variable(placeholder: '_GOODBYE_', name: 'goodbye');

    sourceFile.writeAsStringSync('replace: _HELLO_');

    instance.writeFile(
      partials: [],
      sourceFile: sourceFile,
      targetFile: targetFile,
      variables: [variable, extraVariable],
      fileSystem: fileSystem,
      logger: mockLogger,
    );

    verify(
      () => mockLogger.warn(
        'The following variables are configured in brick_oven.yaml '
        'but not used in file `${sourceFile.path}`:\n'
        '"${extraVariable.name}"',
      ),
    ).called(1);
  });
}

class _TestFileReplacements with FileReplacements {
  const _TestFileReplacements();
}
