import 'package:test/test.dart';

import 'package:brick_oven/enums/mustache_format.dart';

void main() {
  const formats = [
    MustacheFormat.camelCase,
    MustacheFormat.constantCase,
    MustacheFormat.dotCase,
    MustacheFormat.headerCase,
    MustacheFormat.lowerCase,
    MustacheFormat.mustacheCase,
    MustacheFormat.pascalCase,
    MustacheFormat.paramCase,
    MustacheFormat.pathCase,
    MustacheFormat.sentenceCase,
    MustacheFormat.snakeCase,
    MustacheFormat.titleCase,
    MustacheFormat.upperCase,
  ];

  const nonFormats = [
    MustacheFormat.escape,
    MustacheFormat.if_,
    MustacheFormat.ifNot,
    MustacheFormat.endIf,
  ];

  const suffix = 'ASDF';

  const formatsWithoutSuffixes = {
    MustacheFormat.camelCase: [
      'camelCase',
      'camelcase',
      'camel',
    ],
    MustacheFormat.constantCase: [
      'constantCase',
      'constantcase',
      'constant',
    ],
    MustacheFormat.dotCase: [
      'dotCase',
      'dotcase',
      'dot',
    ],
    MustacheFormat.headerCase: [
      'headerCase',
      'headercase',
      'header',
    ],
    MustacheFormat.lowerCase: [
      'lowerCase',
      'lowercase',
      'lower',
    ],
    MustacheFormat.mustacheCase: [
      'mustacheCase',
      'mustachecase',
      'mustache',
    ],
    MustacheFormat.pascalCase: [
      'pascalCase',
      'pascalcase',
      'pascal',
    ],
    MustacheFormat.paramCase: [
      'paramCase',
      'paramcase',
      'param',
    ],
    MustacheFormat.pathCase: [
      'pathCase',
      'pathcase',
      'path',
    ],
    MustacheFormat.sentenceCase: [
      'sentenceCase',
      'sentencecase',
      'sentence',
    ],
    MustacheFormat.snakeCase: [
      'snakeCase',
      'snakecase',
      'snake',
    ],
    MustacheFormat.titleCase: [
      'titleCase',
      'titlecase',
      'title',
    ],
    MustacheFormat.upperCase: [
      'upperCase',
      'uppercase',
      'upper',
    ],
    MustacheFormat.escape: [
      'escape',
    ],
    MustacheFormat.if_: [
      'if',
    ],
    MustacheFormat.ifNot: [
      'ifNot',
      'ifnot',
    ],
    MustacheFormat.endIf: [
      'endIf',
      'endif',
    ],
  };

  const formatsWithSuffixes = {
    MustacheFormat.camelCase: [
      'camelCase$suffix',
      'camelcase$suffix',
      'camel$suffix',
    ],
    MustacheFormat.constantCase: [
      'constantCase$suffix',
      'constantCase$suffix',
      'constant$suffix',
    ],
    MustacheFormat.dotCase: [
      'dotCase$suffix',
      'dotcase$suffix',
      'dot$suffix',
    ],
    MustacheFormat.headerCase: [
      'headerCase$suffix',
      'headercase$suffix',
      'header$suffix',
    ],
    MustacheFormat.lowerCase: [
      'lowerCase$suffix',
      'lowercase$suffix',
      'lower$suffix',
    ],
    MustacheFormat.mustacheCase: [
      'mustacheCase$suffix',
      'mustacheCase$suffix',
      'mustache$suffix',
    ],
    MustacheFormat.pascalCase: [
      'pascalCase$suffix',
      'pascalcase$suffix',
      'pascal$suffix',
    ],
    MustacheFormat.paramCase: [
      'paramCase$suffix',
      'paramcase$suffix',
      'param$suffix',
    ],
    MustacheFormat.pathCase: [
      'pathCase$suffix',
      'pathcase$suffix',
      'path$suffix',
    ],
    MustacheFormat.sentenceCase: [
      'sentenceCase$suffix',
      'sentenceCase$suffix',
      'sentence$suffix',
    ],
    MustacheFormat.snakeCase: [
      'snakeCase$suffix',
      'snakecase$suffix',
      'snake$suffix',
    ],
    MustacheFormat.titleCase: [
      'titleCase$suffix',
      'titlecase$suffix',
      'title$suffix',
    ],
    MustacheFormat.upperCase: [
      'upperCase$suffix',
      'uppercase$suffix',
      'upper$suffix',
    ],
    MustacheFormat.escape: [
      'escape$suffix',
    ],
    MustacheFormat.if_: [
      'if$suffix',
    ],
    MustacheFormat.ifNot: [
      'ifNot$suffix',
      'ifnot$suffix',
    ],
    MustacheFormat.endIf: [
      'endIf$suffix',
      'endif$suffix',
    ],
  };

  const allFormats = [...formats, ...nonFormats];

  group('MustacheFormatX', () {
    group('#toMustache', () {
      test('throws assertion when content is not wrapped with brackets', () {
        expect(
          () => MustacheFormat.camelCase.toMustache('content'),
          throwsA(isA<AssertionError>()),
        );
      });

      test('formats the content correctly', () {
        for (final format in MustacheFormat.values) {
          const content = '{{{sup_dude}}}';

          if (format.isEscape) {
            expect(
              format.toMustache(content),
              content,
            );
            continue;
          }

          expect(
            format.toMustache(content),
            '{{#${format.name}}}$content{{/${format.name}}}',
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

      const allValues = MustacheFormat.values;

      for (final format in allValues) {
        expect(allFormats, contains(format));
      }
    });

    test('#isValue is correct for all values', () {
      final values = {
        MustacheFormat.camelCase: () => MustacheFormat.camelCase.isCamelCase,
        MustacheFormat.constantCase: () =>
            MustacheFormat.constantCase.isConstantCase,
        MustacheFormat.dotCase: () => MustacheFormat.dotCase.isDotCase,
        MustacheFormat.headerCase: () => MustacheFormat.headerCase.isHeaderCase,
        MustacheFormat.lowerCase: () => MustacheFormat.lowerCase.isLowerCase,
        MustacheFormat.mustacheCase: () =>
            MustacheFormat.mustacheCase.isMustacheCase,
        MustacheFormat.pascalCase: () => MustacheFormat.pascalCase.isPascalCase,
        MustacheFormat.paramCase: () => MustacheFormat.paramCase.isParamCase,
        MustacheFormat.pathCase: () => MustacheFormat.pathCase.isPathCase,
        MustacheFormat.sentenceCase: () =>
            MustacheFormat.sentenceCase.isSentenceCase,
        MustacheFormat.snakeCase: () => MustacheFormat.snakeCase.isSnakeCase,
        MustacheFormat.titleCase: () => MustacheFormat.titleCase.isTitleCase,
        MustacheFormat.upperCase: () => MustacheFormat.upperCase.isUpperCase,
        MustacheFormat.escape: () => MustacheFormat.escape.isEscape,
        MustacheFormat.if_: () => MustacheFormat.if_.isIf,
        MustacheFormat.ifNot: () => MustacheFormat.ifNot.isIfNot,
        MustacheFormat.endIf: () => MustacheFormat.endIf.isEndIf,
      };

      final keys = values.keys;

      for (final key in MustacheFormat.values) {
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

        for (final key in MustacheFormat.values) {
          expect(keys, contains(key));
        }

        for (final key in keys) {
          for (final value in formatsWithoutSuffixes[key]!) {
            final result = MustacheFormat.values.findFrom(value);
            expect(result, key);
          }
        }
      });

      test('returns appropriate value when provided with suffixes', () {
        final keys = formatsWithSuffixes.keys;

        for (final key in MustacheFormat.values) {
          expect(keys, contains(key));
        }

        for (final key in keys) {
          for (final value in formatsWithSuffixes[key]!) {
            final result = MustacheFormat.values.findFrom(value);
            expect(result, key);
          }
        }
      });

      test('returns null when value is not found', () {
        expect(MustacheFormat.values.findFrom('nothing'), isNull);
        expect(MustacheFormat.values.findFrom(null), isNull);
      });
    });

    group('#suffixFrom', () {
      test('returns the suffix for the provided value', () {
        final keys = formatsWithSuffixes.keys;

        for (final key in MustacheFormat.values) {
          expect(keys, contains(key));
        }

        for (final key in keys) {
          for (final value in formatsWithSuffixes[key]!) {
            final result = MustacheFormat.values.suffixFrom(value);
            expect(result, suffix);
          }
        }
      });

      test('returns null when value is not found', () {
        expect(MustacheFormat.values.suffixFrom('nothing'), isNull);
        expect(MustacheFormat.values.suffixFrom(null), isNull);
      });
    });
  });
}
