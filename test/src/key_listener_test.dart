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
  final stdout = MockStdout();
  final stdin = MockStdin();
  late MockLogger mockLogger;

  setUp(() {
    reset(stdout);
    reset(stdin);
    mockLogger = MockLogger();

    when(
      () => stdin.asBroadcastStream(
        onListen: any(named: 'onListen'),
        onCancel: any(named: 'onCancel'),
      ),
    ).thenAnswer((_) => const Stream.empty());
  });

  test(
    'throws $StateError when terminal is not supported',
    overrideIO(
      () {
        when(() => stdin.hasTerminal).thenReturn(false);

        expect(() => qToQuit(logger: mockLogger), throwsStateError);
      },
      stdin: stdin,
      stdout: stdout,
    ),
  );

  test(
    'sets up key listener',
    overrideIO(
      () {
        qToQuit(logger: mockLogger);

        verify(mockLogger.qToQuit).called(1);

        verify(() => stdin.lineMode = false).called(1);
        verify(() => stdin.echoMode = false).called(1);

        verify(
          () => stdin.asBroadcastStream(
            onListen: any(named: 'onListen'),
            onCancel: any(named: 'onCancel'),
          ),
        ).called(1);
      },
      stdin: stdin,
      stdout: stdout,
    ),
  );
}

FutureOr<void> Function() overrideIO(
  FutureOr<void> Function() fn, {
  Stdin? stdin,
  Stdout? stdout,
}) {
  final din = stdin ?? MockStdin();
  final out = stdout ?? MockStdout();

  return () => IOOverrides.runZoned(
        () {
          when(() => din.hasTerminal).thenReturn(true);
          when(() => out.supportsAnsiEscapes).thenReturn(true);

          fn();
        },
        stdin: () => din,
        stdout: () => out,
      );
}
