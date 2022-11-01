// ignore_for_file: unnecessary_cast

import 'dart:async';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:brick_oven/src/key_listener.dart';
import 'package:brick_oven/utils/extensions.dart';
import '../utils/mocks.dart';

class MockStdout extends Mock implements Stdout {}

class MockStdin extends Mock implements Stdin {}

void main() {
  group('$KeyPressListener', () {
    final mockStdout = MockStdout();
    final mockStdin = MockStdin();
    late MockLogger mockLogger;
    late KeyPressListener keyPressListener;
    void fakeExit(int _) {}

    setUp(() {
      reset(mockStdout);
      reset(mockStdin);

      KeyPressListener.stream = null;

      when(() => mockStdin.hasTerminal).thenReturn(true);
      when(() => mockStdout.supportsAnsiEscapes).thenReturn(true);
      mockLogger = MockLogger();
      keyPressListener = KeyPressListener(
        stdin: mockStdin,
        logger: mockLogger,
        toExit: fakeExit,
      );

      when(
        mockStdin.asBroadcastStream,
      ).thenAnswer((_) => const Stream.empty());
    });

    test(
      'returns null when stdin has no termainal',
      () {
        when(() => mockStdin.hasTerminal).thenReturn(false);

        expect(() => keyPressListener.qToQuit(), returnsNormally);
      },
    );

    test(
      'sets up key listener',
      () async {
        keyPressListener.qToQuit();

        verify(mockLogger.qToQuit).called(1);

        verify(() => mockStdin.lineMode = false).called(1);
        verify(() => mockStdin.echoMode = false).called(1);

        await Future<void>.delayed(const Duration(milliseconds: 200));

        verify(
          mockStdin.asBroadcastStream,
        ).called(1);
      },
    );

    group('#keyListener', () {
      test('throws state error when stdin does not have terminal', () {
        when(() => mockStdin.hasTerminal).thenReturn(false);

        expect(
          () => keyPressListener.keyListener(keys: {'': () {}} as KeyMap),
          throwsStateError,
        );
      });

      test('sets line and echo mode to false', () {
        keyPressListener.keyListener(keys: {'': () {}} as KeyMap);

        verify(() => mockStdin.lineMode = false).called(1);
        verify(() => mockStdin.echoMode = false).called(1);
      });

      test('listens for key presses', () async {
        when(
          mockStdin.asBroadcastStream,
        ).thenAnswer(
          (_) => Stream.fromIterable([
            'q'.codeUnits,
            [0x1b]
          ]),
        );

        var qPressed = false;
        var escPressed = false;
        keyPressListener.keyListener(
          keys: {
            'q': () {
              qPressed = true;
            },
            0x1b: () {
              escPressed = true;
            },
          } as KeyMap,
        );

        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(qPressed, isTrue);
        expect(escPressed, isTrue);
      });
    });

    group('#keyPresses', () {
      test('"q" logs and exits with code 0', () {
        var hasExited = false;
        var exitCode = 1;
        final action = KeyPressListener(
          stdin: mockStdin,
          logger: mockLogger,
          toExit: (code) {
            hasExited = true;
            exitCode = code;
          },
        ).keyPresses['q'];

        expect(() => action, isNotNull);
        expect(() => action, isA<Function>());

        action!;
        action();

        expect(hasExited, isTrue);
        expect(exitCode, 0);
        verify(() => mockLogger.info('\nExiting...\n')).called(1);
      });
    });

    test('"esc" logs', () {
      final action = keyPressListener.keyPresses[0x1b];

      expect(() => action, isNotNull);
      expect(() => action, isA<Function>());

      action!;
      action();

      verify(mockLogger.qToQuit).called(1);
    });
  });
}

// FutureOr<void> Function() overrideIO(
//   FutureOr<void> Function() fn, {
//   Stdin? mockStdin,
//   Stdout? mockStdout,
// }) {
//   final din = mockStdin ?? MockStdin();
//   final out = mockStdout ?? MockStdout();

//   return () => IOOverrides.runZoned(
//         () {
//           when(() => din.hasTerminal).thenReturn(true);
//           when(() => out.supportsAnsiEscapes).thenReturn(true);

//           fn();
//         },
//         mockStdin: () => din,
//         mockStdout: () => out,
//       );
// }
