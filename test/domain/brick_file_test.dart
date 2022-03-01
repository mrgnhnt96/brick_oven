// ignore_for_file: cascade_invocations

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/enums/mustache_loops.dart';
import 'package:brick_oven/enums/mustache_sections.dart';
import '../utils/fakes.dart';

void main() {
  const defaultFile = 'file.dart';
  final defaultPath = join('path', 'to', defaultFile);

  const fileExtensions = {
    'file.dart': '.dart',
    'file.dart.mustache': '.dart.mustache',
    'file.mustache': '.mustache',
    'file.js': '.js',
    'file.md': '.md',
  };

  group('$BrickFile unnamed ctor', () {
    final instance = BrickFile(defaultPath);

    test('can be instanciated', () {
      expect(instance, isA<BrickFile>());
    });

    test('variables is an empty list', () {
      expect(instance.variables, isEmpty);
    });

    test('prefix is null', () {
      expect(instance.name?.prefix, isNull);
    });

    test('suffix is null', () {
      expect(instance.name?.suffix, isNull);
    });

    test('providedName is null', () {
      expect(instance.name?.value, isNull);
    });
  });

  group('#fromYaml', () {
    const prefix = 'prefix';
    const suffix = 'suffix';
    const name = 'name';

    FakeYamlMap yaml({
      bool includePrefix = true,
      bool includeSuffix = true,
      bool includeNameProp = true,
      bool includeName = true,
      bool includeVariables = true,
      bool emptyVariables = false,
      bool extraKeys = false,
      bool extraFileKeys = false,
      bool useNameString = false,
      bool useInferredName = false,
    }) {
      dynamic nameValue;

      if (useNameString) {
        nameValue = name;
      } else if (useInferredName) {
        nameValue = null;
      } else {
        nameValue = FakeYamlMap(<String, dynamic>{
          if (includePrefix) 'prefix': prefix,
          if (includeSuffix) 'suffix': suffix,
          if (includeNameProp) 'value': name,
          if (extraFileKeys) 'extra': 'extra',
        });
      }

      return FakeYamlMap(<String, dynamic>{
        if (includeName) 'name': nameValue,
        if (includeVariables)
          'vars': emptyVariables
              ? FakeYamlMap.empty()
              : FakeYamlMap(<String, dynamic>{name: FakeYamlMap.empty()}),
        if (extraKeys) 'extra': 'extra',
      });
    }

    BrickFile brickFromYaml(FakeYamlMap yaml, [String? path]) {
      return BrickFile.fromYaml(yaml, path: path ?? defaultPath);
    }

    test('throws exception on null value', () {
      expect(
        () => BrickFile.fromYaml(null, path: 'path'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('gets files name when not provided value in the name key', () {
      const fileName = 'file';
      const ext = '.dart';
      const file = '$fileName$ext';
      final paths = [
        join('path', file),
        join('path', 'to', file),
        join('path', 'to', 'some', file),
      ];

      for (final path in paths) {
        final yaml = FakeYamlMap(<String, dynamic>{
          'name': null,
        });
        final file = BrickFile.fromYaml(yaml, path: path);

        expect(
          file.fileName,
          '{{#snakeCase}}{{{$fileName}}}{{/snakeCase}}$ext',
        );
      }
    });

    test('can parse all provided values', () {
      final instance = brickFromYaml(yaml());

      expect(instance.variables, hasLength(1));
      expect(instance.path, defaultPath);
      expect(instance.name?.prefix, prefix);
      expect(instance.name?.suffix, suffix);
      expect(instance.name?.value, name);
    });

    test('can parse empty variables', () {
      final instance = brickFromYaml(yaml(includeVariables: false));

      expect(instance.variables, isEmpty);

      final instance2 = brickFromYaml(yaml(emptyVariables: true));

      expect(instance2.variables, isEmpty);
    });

    group('name', () {
      test('can parse when key is not provided', () {
        final instance = brickFromYaml(yaml(includeName: false));

        expect(instance.name, isNull);
      });

      test('can parse when string provided', () {
        final instance = brickFromYaml(yaml(useNameString: true));

        expect(instance.name?.value, name);
      });

      test('can parse when value is not provided', () {
        final instance = brickFromYaml(
          yaml(useInferredName: true),
          join('path', 'to', 'some', 'file.dart'),
        );

        expect(instance.name?.value, 'file');
      });
    });

    test('throws if extra keys are provided', () {
      expect(
        () => brickFromYaml(yaml(extraKeys: true)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws if extra keys are provided to file config', () {
      expect(
        () => brickFromYaml(yaml(extraFileKeys: true)),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('#fileName', () {
    test('return the file name formatted when no provided name', () {
      final instance = BrickFile(defaultPath);

      expect(instance.fileName, contains(defaultFile));
    });

    test('return the provided name', () {
      const name = Name('name');
      final instance = BrickFile.config(defaultPath, name: name);

      expect(instance.fileName, contains(name.value));
    });

    test('prepends the prefix', () {
      const name = Name('name', prefix: 'prefix');
      final instance = BrickFile.config(defaultPath, name: name);

      expect(instance.fileName, contains('${name.prefix}{{{${name.value}}}}'));
    });

    test('appends the suffix', () {
      const name = Name('name', suffix: 'suffix');
      final instance = BrickFile.config(defaultPath, name: name);

      expect(instance.fileName, contains('{{{${name.value}}}}${name.suffix}'));
    });

    test('formats the name to mustache', () {
      const name = Name('name');

      final instance = BrickFile.config(defaultPath, name: name);

      expect(
        instance.fileName,
        contains('{{#snakeCase}}{{{${name.value}}}}{{/snakeCase}}'),
      );
    });

    test('includes the extension', () {
      for (final file in fileExtensions.keys) {
        final expected = fileExtensions[file]!;
        final instance = BrickFile.config(file);

        expect(instance.fileName, endsWith(expected));
      }
    });
  });

  group('#extension', () {
    test('returns the extension', () {
      for (final file in fileExtensions.keys) {
        final expected = fileExtensions[file];
        final instance = BrickFile.config(file);

        expect(instance.extension, expected);
      }
    });

    test('returns multi extension', () {
      final extensions =
          List<String>.generate(10, (index) => "${'.g' * index}.dart");

      for (final extension in extensions) {
        final fileName = 'file$extension';
        final instance = BrickFile.config(fileName);

        expect(instance.extension, extension);
      }
    });
  });

  group('#hasConfiguredName', () {
    test('returns true when a name is provided', () {
      const file = BrickFile.config('path/to/file.dart', name: Name('name'));

      expect(file.hasConfiguredName, isTrue);
    });

    test('returns false when no name is provided', () {
      const file = BrickFile.config('path/to/file.dart');

      expect(file.hasConfiguredName, isFalse);
    });
  });

  group('#nonformattedName', () {
    test('returns the basename when no name is provided', () {
      const file = BrickFile.config('path/to/file.dart');

      expect(file.simpleName, 'file.dart');
    });

    test('returns the provided name', () {
      const file = BrickFile.config('path/to/file.dart', name: Name('name'));

      expect(file.simpleName, '{name}.dart');
    });

    test('returns the provided name with prefix', () {
      const file = BrickFile.config(
        'path/to/file.dart',
        name: Name(
          'name',
          prefix: 'prefix_',
        ),
      );

      expect(file.simpleName, 'prefix_{name}.dart');
    });

    test('returns the provided name with suffix', () {
      const file = BrickFile.config(
        'path/to/file.dart',
        name: Name(
          'name',
          suffix: '_suffix',
        ),
      );

      expect(file.simpleName, '{name}_suffix.dart');
    });
  });

  group('#writeTargetFiles', () {
    late FileSystem fileSystem;
    late File sourceFile;
    const sourceFilePath = 'source.dart';
    const content = 'content';

    BrickPath brickPath({
      String? name,
      String? path,
    }) {
      return BrickPath(
        name: Name(name ?? 'name'),
        path: path ?? defaultPath,
      );
    }

    setUp(() {
      fileSystem = MemoryFileSystem();
      sourceFile = fileSystem.file(sourceFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    });

    test('writes a file on the root level', () {
      const instance = BrickFile.config(defaultFile);

      instance.writeTargetFile(
        sourceFile: sourceFile,
        configuredDirs: [],
        targetDir: '',
        fileSystem: fileSystem,
      );

      final newFile = fileSystem.file(defaultFile);

      expect(newFile.existsSync(), isTrue);
    });

    test('writes a file on a nested level', () {
      const instance = BrickFile.config(defaultFile);

      instance.writeTargetFile(
        sourceFile: sourceFile,
        configuredDirs: [],
        targetDir: 'nested',
        fileSystem: fileSystem,
      );

      final newFile = fileSystem.file(
        join(
          'nested',
          defaultFile,
        ),
      );

      expect(newFile.existsSync(), isTrue);
    });

    test('updates path with configured directory', () {
      final instance = BrickFile.config(defaultPath);
      const replacement = 'something';
      final dir = brickPath(name: replacement, path: join('path', 'to'));

      instance.writeTargetFile(
        sourceFile: sourceFile,
        configuredDirs: [dir],
        targetDir: '',
        fileSystem: fileSystem,
      );

      final newFile = fileSystem.file(
        join(
          'path',
          '{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}',
          defaultFile,
        ),
      );

      expect(newFile.existsSync(), isTrue);
    });

    test('updates file name when provided', () {
      const replacement = 'something';
      final instance =
          BrickFile.config(defaultPath, name: const Name(replacement));

      instance.writeTargetFile(
        sourceFile: sourceFile,
        configuredDirs: [],
        targetDir: '',
        fileSystem: fileSystem,
      );

      final newFile = fileSystem.file(
        join(
          'path',
          'to',
          '{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}.dart',
        ),
      );

      expect(newFile.existsSync(), isTrue);
    });

    test('copies file when no variables are provided', () {
      const instance = BrickFile.config(defaultFile);

      instance.writeTargetFile(
        sourceFile: sourceFile,
        configuredDirs: [],
        targetDir: '',
        fileSystem: fileSystem,
      );

      final newFile = fileSystem.file(defaultFile);

      expect(newFile.readAsStringSync(), content);
    });

    group('#variables', () {
      test('replaces variable placeholders with name', () {
        const newName = 'new-name';
        const placeholder = 'MEEEEE';
        const content = 'replace: $placeholder';

        const variable = Variable(name: newName, placeholder: placeholder);
        const instance = BrickFile.config(defaultFile, variables: [variable]);

        sourceFile.writeAsStringSync(content);

        instance.writeTargetFile(
          sourceFile: sourceFile,
          configuredDirs: [],
          targetDir: '',
          fileSystem: fileSystem,
        );

        final newFile = fileSystem.file(defaultFile);

        expect(newFile.readAsStringSync(), content);
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

      test('variable does not replace sub string', () {
        const newName = 'new-name';
        const placeholder = 'name';
        const contents = ['xname', 'names'];
        const variable = Variable(name: newName, placeholder: placeholder);
        const instance = BrickFile.config(defaultFile, variables: [variable]);
        for (final content in contents) {
          sourceFile.writeAsStringSync(content);
          instance.writeTargetFile(
            sourceFile: sourceFile,
            configuredDirs: [],
            targetDir: '',
            fileSystem: fileSystem,
          );

          final newFile = fileSystem.file(defaultFile);

          expect(newFile.readAsStringSync(), content);
        }
      });

      group('formats', () {
        const newName = 'new-name';
        const placeholder = 'MEEEEE';
        const variable = Variable(name: newName, placeholder: placeholder);
        const instance = BrickFile.config(defaultFile, variables: [variable]);

        Map<String, String> getContents({
          required String format,
          String prefix = '',
          String suffix = '',
          String before = '',
          String after = '',
          MustacheSections? section,
        }) {
          final sectionConfig = section?.configName ?? '';
          final sectionSymbol = (section?.isInvert ?? false) ? '^' : '#';

          final caseFormats = [
            format,
            '${format}Case',
            '${format}CASE'.toUpperCase(),
            '${format}case'.toLowerCase(),
          ];

          final value =
              '$before$prefix{{$sectionSymbol${format}Case}}{{{$newName}}}{{/${format}Case}}$suffix$after';

          return caseFormats.fold(<String, String>{}, (p, caseFormat) {
            final key = '$before'
                '$prefix'
                '$sectionConfig'
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
                instance.writeTargetFile(
                  sourceFile: sourceFile,
                  configuredDirs: [],
                  targetDir: '',
                  fileSystem: fileSystem,
                );

                final newFile = fileSystem.file(defaultFile);

                expect(
                  newFile.readAsStringSync(),
                  content.value,
                );
              }
            });

            test('replaces variable placeholder with name, maintaining prefix',
                () {
              final contents = getContents(format: format, prefix: 'prefix_');

              for (final content in contents.entries) {
                sourceFile.writeAsStringSync(content.key);
                instance.writeTargetFile(
                  sourceFile: sourceFile,
                  configuredDirs: [],
                  targetDir: '',
                  fileSystem: fileSystem,
                );

                final newFile = fileSystem.file(defaultFile);

                expect(
                  newFile.readAsStringSync(),
                  content.value,
                );
              }
            });

            test('replaces variable placeholder with name, maintaining suffix',
                () {
              final contents = getContents(format: format, suffix: '_suffix');

              for (final content in contents.entries) {
                sourceFile.writeAsStringSync(content.key);
                instance.writeTargetFile(
                  sourceFile: sourceFile,
                  configuredDirs: [],
                  targetDir: '',
                  fileSystem: fileSystem,
                );

                final newFile = fileSystem.file(defaultFile);

                expect(
                  newFile.readAsStringSync(),
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
                instance.writeTargetFile(
                  sourceFile: sourceFile,
                  configuredDirs: [],
                  targetDir: '',
                  fileSystem: fileSystem,
                );

                final newFile = fileSystem.file(defaultFile);

                expect(
                  newFile.readAsStringSync(),
                  content.value,
                );
              }
            });

            for (final section in MustacheSections.values) {
              group('(${section.name})', () {
                test('replaces variable placeholder with name', () {
                  final contents =
                      getContents(format: format, section: section);

                  for (final content in contents.entries) {
                    sourceFile.writeAsStringSync(content.key);
                    instance.writeTargetFile(
                      sourceFile: sourceFile,
                      configuredDirs: [],
                      targetDir: '',
                      fileSystem: fileSystem,
                    );

                    final newFile = fileSystem.file(defaultFile);

                    expect(
                      newFile.readAsStringSync(),
                      content.value,
                    );
                  }
                });

                test('replaces variable placeholder with name and prefix', () {
                  final contents = getContents(
                    format: format,
                    section: section,
                    prefix: 'prefix_',
                  );

                  for (final content in contents.entries) {
                    sourceFile.writeAsStringSync(content.key);
                    instance.writeTargetFile(
                      sourceFile: sourceFile,
                      configuredDirs: [],
                      targetDir: '',
                      fileSystem: fileSystem,
                    );

                    final newFile = fileSystem.file(defaultFile);

                    expect(
                      newFile.readAsStringSync(),
                      content.value,
                    );
                  }
                });

                test(
                    'replaces variable placeholder with name and preceeding text',
                    () {
                  final contents = getContents(
                    format: format,
                    section: section,
                    before: 'some text with spaces ',
                  );

                  contents
                    ..addAll(
                      getContents(
                        format: format,
                        section: section,
                        before: 'some text with line breaks\n',
                      ),
                    )
                    ..addAll(
                      getContents(
                        format: format,
                        section: section,
                        before: 'some text with tabs\t',
                      ),
                    );

                  for (final content in contents.entries) {
                    sourceFile.writeAsStringSync(content.key);
                    instance.writeTargetFile(
                      sourceFile: sourceFile,
                      configuredDirs: [],
                      targetDir: '',
                      fileSystem: fileSystem,
                    );

                    final newFile = fileSystem.file(defaultFile);

                    expect(
                      newFile.readAsStringSync(),
                      content.value,
                    );
                  }
                });
              });
            }
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
                  const instance =
                      BrickFile.config(defaultFile, variables: [variable]);

                  sourceFile.writeAsStringSync(content.key);

                  instance.writeTargetFile(
                    sourceFile: sourceFile,
                    configuredDirs: [],
                    targetDir: '',
                    fileSystem: fileSystem,
                  );

                  final newFile = fileSystem.file(defaultFile);

                  expect(newFile.readAsStringSync(), content.value);
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
          const instance = BrickFile.config(defaultFile, variables: [variable]);

          sourceFile.writeAsStringSync(content);

          instance.writeTargetFile(
            sourceFile: sourceFile,
            configuredDirs: [],
            targetDir: '',
            fileSystem: fileSystem,
          );

          final newFile = fileSystem.file(defaultFile);

          expect(newFile.readAsStringSync(), 'replace: {{^$newName}}');
        },
      );

      const badFormats = [
        'sanke',
        'sank',
        'some',
      ];

      for (final format in badFormats) {
        test(
            'ignores variable placeholder with name ignoring bad format ($format)',
            () {
          const newName = 'new-name';
          const placeholder = 'MEEEEE';
          final content = 'replace: $placeholder${format}Case';

          const variable = Variable(name: newName, placeholder: placeholder);
          const instance = BrickFile.config(defaultFile, variables: [variable]);

          sourceFile.writeAsStringSync(content);

          instance.writeTargetFile(
            sourceFile: sourceFile,
            configuredDirs: [],
            targetDir: '',
            fileSystem: fileSystem,
          );

          final newFile = fileSystem.file(defaultFile);

          expect(newFile.readAsStringSync(), content);
        });
      }
    });

    test('replaces mustache loop comment', () {
      const placeholder = '_HELLO_';
      const replacement = 'hello';

      Map<String, String> lines(String loop) {
        final expected = MustacheLoops.toMustache(replacement, loop);
        return {
          '//': expected,
          '#': expected,
          r'\*': expected,
          r'*\': expected,
          '/*': expected,
          '*/': expected,
        }.map((key, value) {
          return MapEntry('$key$placeholder$loop', value);
        });
      }

      final loops = {
        ...lines(MustacheLoops.start),
        ...lines(MustacheLoops.end),
        ...lines(MustacheLoops.startInvert),
      };

      const variable = Variable(placeholder: placeholder, name: replacement);
      const instance = BrickFile.config(defaultFile, variables: [variable]);

      for (final loop in loops.keys) {
        final expected = loops[loop]!;

        final newFile = fileSystem.file(defaultFile);

        sourceFile.writeAsStringSync(loop);

        instance.writeTargetFile(
          sourceFile: sourceFile,
          configuredDirs: [],
          targetDir: '',
          fileSystem: fileSystem,
        );

        expect(newFile.readAsStringSync(), expected);
      }
    });
  });

  group('props', () {
    const name = Name(
      'name',
      prefix: 'prefix',
      suffix: 'suffix',
    );
    const variables = [Variable(placeholder: 'placeholder', name: 'name')];

    const instance = BrickFile.config(
      defaultFile,
      name: name,
      variables: variables,
    );

    test('length should be 3', () {
      expect(instance.props.length, 3);
    });

    test('contains path', () {
      expect(instance.props, contains(defaultFile));
    });

    test('contains variables', () {
      final vars = instance.props.firstWhere((prop) => prop is List<Variable>);

      expect(vars, isA<List<Variable>>());
      vars as List<Variable>?;

      for (final variable in vars!) {
        expect(instance.variables, contains(variable));
      }
    });

    test('contains name', () {
      expect(instance.props, contains(name));
    });
  });
}
