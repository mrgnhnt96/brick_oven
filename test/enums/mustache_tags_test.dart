import 'package:test/test.dart';

import 'package:brick_oven/enums/mustache_tags.dart';

void main() {
  const formats = [
    MustacheTags.camelCase,
    MustacheTags.constantCase,
    MustacheTags.dotCase,
    MustacheTags.headerCase,
    MustacheTags.lowerCase,
    MustacheTags.mustacheCase,
    MustacheTags.pascalCase,
    MustacheTags.paramCase,
    MustacheTags.pathCase,
    MustacheTags.sentenceCase,
    MustacheTags.snakeCase,
    MustacheTags.titleCase,
    MustacheTags.upperCase,
  ];

  const nonFormats = [
    MustacheTags.escaped,
    MustacheTags.unescaped,
    MustacheTags.if_,
    MustacheTags.ifNot,
    MustacheTags.endIf,
  ];

  const suffix = 'ASDF';

  const formatsWithoutSuffixes = {
    MustacheTags.camelCase: [
      'camelCase',
      'camelcase',
      'camel',
    ],
    MustacheTags.constantCase: [
      'constantCase',
      'constantcase',
      'constant',
    ],
    MustacheTags.dotCase: [
      'dotCase',
      'dotcase',
      'dot',
    ],
    MustacheTags.headerCase: [
      'headerCase',
      'headercase',
      'header',
    ],
    MustacheTags.lowerCase: [
      'lowerCase',
      'lowercase',
      'lower',
    ],
    MustacheTags.mustacheCase: [
      'mustacheCase',
      'mustachecase',
      'mustache',
    ],
    MustacheTags.pascalCase: [
      'pascalCase',
      'pascalcase',
      'pascal',
    ],
    MustacheTags.paramCase: [
      'paramCase',
      'paramcase',
      'param',
    ],
    MustacheTags.pathCase: [
      'pathCase',
      'pathcase',
      'path',
    ],
    MustacheTags.sentenceCase: [
      'sentenceCase',
      'sentencecase',
      'sentence',
    ],
    MustacheTags.snakeCase: [
      'snakeCase',
      'snakecase',
      'snake',
    ],
    MustacheTags.titleCase: [
      'titleCase',
      'titlecase',
      'title',
    ],
    MustacheTags.upperCase: [
      'upperCase',
      'uppercase',
      'upper',
    ],
    MustacheTags.escaped: [
      'escaped',
    ],
    MustacheTags.unescaped: [
      'unescaped',
    ],
    MustacheTags.if_: [
      'if',
    ],
    MustacheTags.ifNot: [
      'ifNot',
      'ifnot',
    ],
    MustacheTags.endIf: [
      'endIf',
      'endif',
    ],
  };

  const formatsWithSuffixes = {
    MustacheTags.camelCase: [
      'camelCase$suffix',
      'camelcase$suffix',
      'camel$suffix',
    ],
    MustacheTags.constantCase: [
      'constantCase$suffix',
      'constantCase$suffix',
      'constant$suffix',
    ],
    MustacheTags.dotCase: [
      'dotCase$suffix',
      'dotcase$suffix',
      'dot$suffix',
    ],
    MustacheTags.headerCase: [
      'headerCase$suffix',
      'headercase$suffix',
      'header$suffix',
    ],
    MustacheTags.lowerCase: [
      'lowerCase$suffix',
      'lowercase$suffix',
      'lower$suffix',
    ],
    MustacheTags.mustacheCase: [
      'mustacheCase$suffix',
      'mustacheCase$suffix',
      'mustache$suffix',
    ],
    MustacheTags.pascalCase: [
      'pascalCase$suffix',
      'pascalcase$suffix',
      'pascal$suffix',
    ],
    MustacheTags.paramCase: [
      'paramCase$suffix',
      'paramcase$suffix',
      'param$suffix',
    ],
    MustacheTags.pathCase: [
      'pathCase$suffix',
      'pathcase$suffix',
      'path$suffix',
    ],
    MustacheTags.sentenceCase: [
      'sentenceCase$suffix',
      'sentenceCase$suffix',
      'sentence$suffix',
    ],
    MustacheTags.snakeCase: [
      'snakeCase$suffix',
      'snakecase$suffix',
      'snake$suffix',
    ],
    MustacheTags.titleCase: [
      'titleCase$suffix',
      'titlecase$suffix',
      'title$suffix',
    ],
    MustacheTags.upperCase: [
      'upperCase$suffix',
      'uppercase$suffix',
      'upper$suffix',
    ],
    MustacheTags.escaped: [
      'escaped$suffix',
    ],
    MustacheTags.unescaped: [
      'unescaped$suffix',
    ],
    MustacheTags.if_: [
      'if$suffix',
    ],
    MustacheTags.ifNot: [
      'ifNot$suffix',
      'ifnot$suffix',
    ],
    MustacheTags.endIf: [
      'endIf$suffix',
      'endif$suffix',
    ],
  };

  const allFormats = [...formats, ...nonFormats];

  test('MustacheFormat.values', () {
    final formatsWithSuffixesKeys = formatsWithSuffixes.keys.toList();
    final formatsWithoutSuffixesKeys = formatsWithoutSuffixes.keys.toList();

    for (final value in MustacheTags.values) {
      expect(allFormats, contains(value));
      expect(formatsWithSuffixesKeys, contains(value));
      expect(formatsWithoutSuffixesKeys, contains(value));
    }
  });

  group('MustacheFormatX', () {
    group('#wrappedPattern', () {
      test('is correct value', () {
        final expected = RegExp(r'\S*\{{2,3}\S+\}{2,3}\S*');

        expect(MustacheFormatX.wrappedPattern, expected);
      });

      test('matches', () {
        const matches = [
          'prefix{{foo}}',
          'prefix{{foo}}suffix',
          '{{foo}}suffix',
          '{{foo}}',
          '{{foo}}}',
          '{{{foo}}}',
          '{{{foo}}',
        ];

        for (final match in matches) {
          expect(MustacheFormatX.wrappedPattern.hasMatch(match), isTrue);
        }
      });
    });

    group('#wrap', () {
      test('throws assertion when content is configured correctly', () {
        for (final format in formats) {
          expect(() => format.wrap('foo'), returnsNormally);
          expect(() => format.wrap('{{foo}}'), returnsNormally);
          expect(() => format.wrap('{{{foo}}}'), returnsNormally);
        }

        for (final format in nonFormats) {
          expect(
            () => format.wrap('{{foo}}'),
            throwsA(isA<AssertionError>()),
          );
          expect(
            () => format.wrap('{{{foo}}}'),
            throwsA(isA<AssertionError>()),
          );
          expect(
            () => format.wrap('foo'),
            returnsNormally,
          );
        }
      });

      test('formats the content correctly', () {
        for (final format in formats) {
          expect(
            format.wrap('{{{sup_dude}}}'),
            '{{#${format.name}}}{{{sup_dude}}}{{/${format.name}}}',
          );

          expect(
            format.wrap('{{sup_dude}}'),
            '{{#${format.name}}}{{sup_dude}}{{/${format.name}}}',
          );
        }

        const nonFormatExpected = {
          MustacheTags.escaped: '{{{DUDE}}}',
          MustacheTags.unescaped: '{{DUDE}}',
          MustacheTags.if_: '{{#DUDE}}',
          MustacheTags.ifNot: '{{^DUDE}}',
          MustacheTags.endIf: '{{/DUDE}}',
        };

        for (final format in nonFormats) {
          expect(
            format.wrap('DUDE'),
            nonFormatExpected[format],
          );
        }
      });
    });

    test('#isFormat returns true when the value is a format type', () {
      for (final format in formats) {
        expect(format.isFormat, isTrue);
      }

      for (final format in nonFormats) {
        expect(format.isFormat, isFalse);
      }
    });

    test('#isValue is correct for all values', () {
      final values = {
        MustacheTags.camelCase: () => MustacheTags.camelCase.isCamelCase,
        MustacheTags.constantCase: () =>
            MustacheTags.constantCase.isConstantCase,
        MustacheTags.dotCase: () => MustacheTags.dotCase.isDotCase,
        MustacheTags.headerCase: () => MustacheTags.headerCase.isHeaderCase,
        MustacheTags.lowerCase: () => MustacheTags.lowerCase.isLowerCase,
        MustacheTags.mustacheCase: () =>
            MustacheTags.mustacheCase.isMustacheCase,
        MustacheTags.pascalCase: () => MustacheTags.pascalCase.isPascalCase,
        MustacheTags.paramCase: () => MustacheTags.paramCase.isParamCase,
        MustacheTags.pathCase: () => MustacheTags.pathCase.isPathCase,
        MustacheTags.sentenceCase: () =>
            MustacheTags.sentenceCase.isSentenceCase,
        MustacheTags.snakeCase: () => MustacheTags.snakeCase.isSnakeCase,
        MustacheTags.titleCase: () => MustacheTags.titleCase.isTitleCase,
        MustacheTags.upperCase: () => MustacheTags.upperCase.isUpperCase,
        MustacheTags.escaped: () => MustacheTags.escaped.isEscaped,
        MustacheTags.unescaped: () => MustacheTags.unescaped.isUnescaped,
        MustacheTags.if_: () => MustacheTags.if_.isIf,
        MustacheTags.ifNot: () => MustacheTags.ifNot.isIfNot,
        MustacheTags.endIf: () => MustacheTags.endIf.isEndIf,
      };

      final keys = values.keys;

      for (final key in MustacheTags.values) {
        expect(keys, contains(key));
      }

      for (final key in keys) {
        expect(values[key]!(), isTrue);
      }
    });
  });

  group('ListMustacheX', () {
    group('#findFrom', () {
      test('returns when the correct enum for value', () {
        final keys = formatsWithoutSuffixes.keys;

        for (final key in keys) {
          for (final value in formatsWithoutSuffixes[key]!) {
            final result = MustacheTags.values.findFrom(value);
            expect(result, key);
          }
        }
      });

      test('returns appropriate value when provided with suffixes', () {
        final keys = formatsWithSuffixes.keys;

        for (final key in keys) {
          for (final value in formatsWithSuffixes[key]!) {
            final result = MustacheTags.values.findFrom(value);
            expect(result, key);
          }
        }
      });

      test('returns null when value is not found', () {
        expect(MustacheTags.values.findFrom('nothing'), isNull);
        expect(MustacheTags.values.findFrom(null), isNull);
      });
    });

    group('#suffixFrom', () {
      test('returns the suffix for the provided value', () {
        final keys = formatsWithSuffixes.keys;

        for (final key in keys) {
          for (final value in formatsWithSuffixes[key]!) {
            final result = MustacheTags.values.suffixFrom(value);
            expect(result, suffix);
          }
        }
      });

      test('returns null when value is not found', () {
        expect(MustacheTags.values.suffixFrom('nothing'), isNull);
        expect(MustacheTags.values.suffixFrom(null), isNull);
      });
    });
  });
}
