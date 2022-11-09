import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:mocktail/mocktail.dart';

class FakeArgResults extends Fake implements ArgResults {
  FakeArgResults({required this.data});

  final Map<String, dynamic> data;

  @override
  dynamic operator [](String key) => data[key];
}

// ignore: prefer_function_declarations_over_variables
final void Function() voidCallback = () {};

class FakeStdin extends Fake implements Stdin {
  @override
  bool get hasTerminal => true;

  final _controller = StreamController<List<int>>();

  @override
  Stream<List<int>> asBroadcastStream({
    void Function(StreamSubscription<List<int>> subscription)? onListen,
    void Function(StreamSubscription<List<int>> subscription)? onCancel,
  }) {
    return _controller.stream.asBroadcastStream();
  }

  @override
  bool lineMode = false;

  @override
  bool echoMode = false;
}
