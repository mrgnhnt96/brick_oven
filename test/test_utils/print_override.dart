import 'dart:async';

List<String> printLogs = <String>[];

Future<void> overridePrint(FutureOr<void> Function() fn) async {
  final spec = ZoneSpecification(
    print: (_, __, ___, String msg) {
      printLogs.add(msg);
    },
  );

  final zone = Zone.current.fork(specification: spec);

  await zone.run(fn);
}
