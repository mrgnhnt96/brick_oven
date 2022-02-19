import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart' as io;

final _cwd = io.Directory.current;

String testFixturesPath() {
  return path.join(_cwd.path, 'test', '.tmp', 'fixtures');
}

FileSystem setUpTestingEnvironment([List<String> pathSegments = const []]) {
  final fs = const LocalFileSystem()..currentDirectory = './';

  final testDir = io.Directory(
    path.joinAll([testFixturesPath(), ...pathSegments]),
  );

  if (testDir.existsSync()) {
    testDir.deleteSync(recursive: true);
  }

  testDir.createSync(recursive: true);
  fs.currentDirectory = testDir.path;

  return fs;
}

void tearDownTestingEnvironment(FileSystem fs) {
  fs
      .directory(path.join(_cwd.path, 'test', '.tmp'))
      .deleteSync(recursive: true);

  fs.currentDirectory = _cwd.path;
}
