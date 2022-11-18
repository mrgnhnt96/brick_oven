// ignore_for_file: cascade_invocations

import 'package:brick_oven/domain/brick_partial.dart';
import 'package:brick_oven/domain/content_replacement.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/file_replacements.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../test_utils/mocks.dart';

void main() {
  late MockLogger mockLogger;
  late FileSystem fileSystem;
  late File sourceFile;
  late File targetFile;
  const sourceFilePath = 'source.dart';
  const targetFilePath = 'target.dart';
  const defaultContent = 'content';
  const testFileReplacements = _TestFileReplacements();

  setUp(() {
    mockLogger = MockLogger();
    fileSystem = MemoryFileSystem();
    sourceFile = fileSystem.file(sourceFilePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(defaultContent);

    targetFile = fileSystem.file(targetFilePath);
  });

  test('copies file when no variables or partials are provided', () {
    testFileReplacements.writeFile(
      partials: [],
      variables: [],
      sourceFile: sourceFile,
      targetFile: targetFile,
      fileSystem: fileSystem,
      logger: mockLogger,
    );

    expect(targetFile.readAsStringSync(), defaultContent);
  });

  group('#writePartials', () {
    test('replaces partial placeholder with partial value', () {
      const content = '''
partial.do_not_replace
{{> partial }}

// partial.replace_me
partial.replace_me_too //
''';

      const expectedContent = '''
partial.do_not_replace
{{> partial }}

{{> replace_me }}
{{> replace_me_too }}
''';

      const partials = [
        BrickPartial(path: 'path/to/replace_me'),
        BrickPartial(path: 'path/to/replace_me_too'),
        BrickPartial(path: 'path/to/replace_me_three'),
      ];

      final result = testFileReplacements.writePartials(
        content: content,
        partials: partials,
      );

      const expected = ContentReplacement(
        content: expectedContent,
        used: {'path/to/replace_me', 'path/to/replace_me_too'},
      );

      expect(result, expected);
    });
  });

  group('#checkForLoops', () {
    group('#loopPattern', () {
      test('is correct value', () {
        final expected =
            RegExp('.*${FileReplacements.loopSetUp}' r'({{[\^#\\]\S+}}).*');

        expect(testFileReplacements.loopPattern, expected);
      });

      test('matches', () {
        const matches = [
          '{{^asdf}}',
          '{{#asdf}}',
          r'{{\asdf}}',
          r'{{#.,<>$({})}}',
        ];

        for (final match in matches) {
          final content = '${FileReplacements.loopSetUp}$match';
          expect(testFileReplacements.loopPattern.hasMatch(content), isTrue);
        }
      });
    });

    test('returns original content if loop is not found', () {
      const content = 'content';
      const expected = ContentReplacement(content: content, used: {});

      final result = testFileReplacements.checkForLoops(
        content,
        const Variable(name: 'name', placeholder: 'value'),
      );

      expect(result, expected);
    });

    test('returns new content when loop is found', () {
      const content = '''
start_NAME_
some content
end_NAME_

// start_NAME_
// some more content
// end_NAME_

start_NAME_ //
other content //
end_NAME_ //

nstart_NAME_
last content
end_NAME_
''';

      const variable = Variable(name: 'name', placeholder: '_NAME_');

      const expectedContent = '''
{{#name}}
some content
{{/name}}

{{#name}}
// some more content
{{/name}}

{{#name}}
other content //
{{/name}}

{{^name}}
last content
{{/name}}
''';

      const expected = ContentReplacement(
        content: expectedContent,
        used: {'name'},
      );

      final result = testFileReplacements.checkForLoops(
        content,
        variable,
      );

      expect(result, expected);
    });
  });

  group('#checkForVariables', () {
    group('#variablePattern', () {
      const placeholder = '_PEANUT_';
      const variable = Variable(name: 'peanut', placeholder: placeholder);

      test('is correct value', () {
        final expected = RegExp('({*)' '$placeholder' r'(\w*}*)');

        expect(testFileReplacements.variablePattern(variable), expected);
      });

      test('matches', () {
        const matches = {
          placeholder: ['', ''],
          '${placeholder}snake': ['', 'snake'],
          '${placeholder}snakeCase': ['', 'snakeCase'],
          '${placeholder}snake}': ['', 'snake}'],
          '${placeholder}snakeCase}': ['', 'snakeCase}'],
          '{${placeholder}snake': ['{', 'snake'],
          '{${placeholder}snakeCase': ['{', 'snakeCase'],
          '{$placeholder': ['{', ''],
          '{{$placeholder': ['{{', ''],
          '{$placeholder}': ['{', '}'],
          '{{$placeholder}}': ['{{', '}}'],
          '$placeholder}': ['', '}'],
          '$placeholder}}': ['', '}}'],
        };

        const otherMatches = {
          '${placeholder}snake}a': [
            '${placeholder}snake}',
            '',
            'snake}',
          ],
          '${placeholder}snakeCase}a': [
            '${placeholder}snakeCase}',
            '',
            'snakeCase}',
          ],
        };

        for (final match in matches.entries) {
          final matches = testFileReplacements
              .variablePattern(variable)
              .allMatches(match.key);

          expect(matches.length, 1);

          final matchResult = matches.first;

          expect(matchResult.group(0), match.key);
          expect(matchResult.group(1), match.value[0]);
          expect(matchResult.group(2), match.value[1]);
        }

        for (final match in otherMatches.entries) {
          final matches = testFileReplacements
              .variablePattern(variable)
              .allMatches(match.key);

          expect(matches.length, 1);

          final matchResult = matches.first;

          expect(matchResult.group(0), match.value[0]);
          expect(matchResult.group(1), match.value[1]);
          expect(matchResult.group(2), match.value[2]);
        }
      });
    });

    test('returns', () {});
  });

  group('#variables', () {
    test('replaces variable placeholders with name', () {
      const newName = 'new-name';
      const placeholder = 'MEEEEE';
      const content = 'replace: $placeholder';

      const variable = Variable(name: newName, placeholder: placeholder);

      sourceFile.writeAsStringSync(content);

      testFileReplacements.writeFile(
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
        testFileReplacements.writeFile(
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

      testFileReplacements.writeFile(
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

      testFileReplacements.writeFile(
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

              testFileReplacements.writeFile(
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

              testFileReplacements.writeFile(
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

              testFileReplacements.writeFile(
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

              testFileReplacements.writeFile(
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

              testFileReplacements.writeFile(
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

    test(
      'replaces variable placeholder with section end syntax',
      () {
        const newName = 'new-name';
        const placeholder = 'MEEEEE';
        const content = 'replace: ${placeholder}ifNot';

        const variable = Variable(name: newName, placeholder: placeholder);

        sourceFile.writeAsStringSync(content);

        testFileReplacements.writeFile(
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
          testFileReplacements.writeFile(
            partials: [],
            sourceFile: sourceFile,
            targetFile: targetFile,
            variables: [variable],
            fileSystem: fileSystem,
            logger: mockLogger,
          );
        }

        expect(writeFile, throwsA(isA<ConfigException>()));
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

      testFileReplacements.writeFile(
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

        testFileReplacements.writeFile(
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

        testFileReplacements.writeFile(
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

    testFileReplacements.writeFile(
      partials: [],
      sourceFile: sourceFile,
      targetFile: targetFile,
      variables: [variable, extraVariable],
      fileSystem: fileSystem,
      logger: mockLogger,
    );

    verify(
      () => mockLogger.warn(
        'Unused variables ("${extraVariable.name}") in `${sourceFile.path}`',
      ),
    ).called(1);
  });

  test('prints warning if file does not exist', () {
    verifyNever(() => mockLogger.warn(any()));

    const variable = Variable(placeholder: '_HELLO_', name: 'hello');
    const extraVariable = Variable(placeholder: '_GOODBYE_', name: 'goodbye');

    sourceFile.deleteSync();

    testFileReplacements.writeFile(
      partials: [],
      sourceFile: sourceFile,
      targetFile: targetFile,
      variables: [variable, extraVariable],
      fileSystem: fileSystem,
      logger: mockLogger,
    );

    verify(
      () => mockLogger.warn(
        'source file does not exist: ${sourceFile.path}',
      ),
    ).called(1);
  });
}

class _TestFileReplacements with FileReplacements {
  const _TestFileReplacements();
}
