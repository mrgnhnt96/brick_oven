// ignore_for_file: unnecessary_cast

import 'dart:async';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:brick_oven/utils/extensions/logger_extensions.dart';
import '../test_utils/di.dart';
import '../test_utils/fakes.dart';
import '../test_utils/mocks.dart';

void main() {
  tearDown(() {
    KeyPressListener.stream = null;
  });

  group('$KeyPressListener', () {
    final mockStdout = MockStdout();
    final mockStdin = MockStdin();
    late KeyPressListener keyPressListener;
    void fakeExit(int _) {}

    setUp(() {
      setupTestDi();

      reset(mockStdout);
      reset(mockStdin);

      when(() => mockStdin.hasTerminal).thenReturn(true);
      when(() => mockStdout.supportsAnsiEscapes).thenReturn(true);

      keyPressListener = KeyPressListener(
        stdin: mockStdin,
        toExit: fakeExit,
      );

      when(
        mockStdin.asBroadcastStream,
      ).thenAnswer((_) => const Stream.empty());
    });

    test('returns null when stdin has no terminal', () {
      when(() => mockStdin.hasTerminal).thenReturn(false);

      expect(() => keyPressListener.listenToKeystrokes(), returnsNormally);

      verifyNoMoreInteractions(di<Logger>());
    });

    test('sets up key listener', () async {
      verifyNever(mockStdin.asBroadcastStream);
      verifyNever(() => di<Logger>().info(any()));

      keyPressListener.listenToKeystrokes();

      verify(di<Logger>().quit).called(1);
      verify(di<Logger>().reload).called(1);

      verify(() => mockStdin.lineMode = false).called(1);
      verify(() => mockStdin.echoMode = false).called(1);

      await Future<void>.delayed(Duration.zero);

      verify(mockStdin.asBroadcastStream).called(1);

      verifyNoMoreInteractions(di<Logger>());
    });

    group('#keyListener', () {
      test('throws state error when stdin does not have terminal', () {
        when(() => mockStdin.hasTerminal).thenReturn(false);

        expect(
          () => keyPressListener.keyListener(keys: {'': () {}} as KeyMap),
          throwsStateError,
        );

        verifyNoMoreInteractions(di<Logger>());
      });

      test('sets line and echo mode to false', () {
        keyPressListener.keyListener(keys: {'': () {}} as KeyMap);

        verify(() => mockStdin.lineMode = false).called(1);
        verify(() => mockStdin.echoMode = false).called(1);

        verifyNoMoreInteractions(di<Logger>());
      });

      test('listens for key presses', () async {
        when(
          mockStdin.asBroadcastStream,
        ).thenAnswer(
          (_) => Stream.fromIterable(
            [
              'q'.codeUnits,
              [0x1b],
            ],
          ),
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

        await Future<void>.delayed(Duration.zero);

        expect(qPressed, isTrue);
        expect(escPressed, isTrue);

        verifyNoMoreInteractions(di<Logger>());
      });
    });

    test('#listenToKeystrokes can be called multiple times', () {
      final stdin = FakeStdin();

      final instance = KeyPressListener(
        stdin: stdin,
        toExit: fakeExit,
      );

      expect(instance.listenToKeystrokes, returnsNormally);
      expect(instance.listenToKeystrokes, returnsNormally);
      expect(instance.listenToKeystrokes, returnsNormally);
      expect(instance.listenToKeystrokes, returnsNormally);

      verify(di<Logger>().quit).called(4);
      verify(di<Logger>().reload).called(4);

      verifyNoMoreInteractions(di<Logger>());
    });

    group('#keyPresses', () {
      test('"q" logs and exits with code 0', () {
        var hasExited = false;
        var exitCode = 1;
        final action = KeyPressListener(
          stdin: mockStdin,
          toExit: (code) {
            hasExited = true;
            exitCode = code;
          },
        ).keyPresses['q'];

        expect(() => action, isNotNull);
        expect(() => action, isA<Function>());

        action!.call();

        expect(hasExited, isTrue);
        expect(exitCode, 0);
        verify(di<Logger>().exiting).called(1);

        verifyNoMoreInteractions(di<Logger>());
      });

      test('"r" logs and exits with code 75', () {
        var hasExited = false;
        var exitCode = 1;
        final action = KeyPressListener(
          stdin: mockStdin,
          toExit: (code) {
            hasExited = true;
            exitCode = code;
          },
        ).keyPresses['r'];

        expect(() => action, isNotNull);
        expect(() => action, isA<Function>());

        action!.call();

        expect(hasExited, isTrue);
        expect(exitCode, 75);
        verify(() => di<Logger>().restart()).called(1);

        verifyNoMoreInteractions(di<Logger>());
      });

      test('"esc" logs', () {
        final action = keyPressListener.keyPresses[0x1b];

        expect(() => action, isNotNull);
        expect(() => action, isA<Function>());

        action!.call();

        verify(di<Logger>().quit).called(1);
        verify(di<Logger>().reload).called(1);

        verifyNoMoreInteractions(di<Logger>());
      });
    });
  });
}
