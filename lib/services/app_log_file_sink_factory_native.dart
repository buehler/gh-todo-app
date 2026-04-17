import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:gh_todos/services/app_logger_service.dart';

class RollingFileAppLogSink implements AppLogSink {
  RollingFileAppLogSink._(this._directory);

  static const maxTotalBytes = 5 * 1024 * 1024;
  static const _activeBudgetBytes = maxTotalBytes ~/ 2;

  final Directory _directory;

  File get _activeFile => File('${_directory.path}/app.log');
  File get _rolledFile => File('${_directory.path}/app.log.1');

  static Future<RollingFileAppLogSink> create() async {
    final directory = await getApplicationSupportDirectory();
    final logDirectory = Directory('${directory.path}/logs');
    if (!await logDirectory.exists()) {
      await logDirectory.create(recursive: true);
    }
    return RollingFileAppLogSink._(logDirectory);
  }

  @override
  Future<void> clear() async {
    if (await _activeFile.exists()) {
      await _activeFile.delete();
    }
    if (await _rolledFile.exists()) {
      await _rolledFile.delete();
    }
  }

  @override
  Future<List<String>> readLines() async {
    final lines = <String>[];

    if (await _rolledFile.exists()) {
      lines.addAll(await _rolledFile.readAsLines());
    }
    if (await _activeFile.exists()) {
      lines.addAll(await _activeFile.readAsLines());
    }

    return lines;
  }

  @override
  Future<void> write(String line) async {
    await _activeFile.parent.create(recursive: true);
    await _activeFile.writeAsString('$line\n', mode: FileMode.append);
    await _rotateIfNeeded();
  }

  Future<void> _rotateIfNeeded() async {
    if (!await _activeFile.exists()) return;

    final length = await _activeFile.length();
    if (length <= _activeBudgetBytes) return;

    if (await _rolledFile.exists()) {
      await _rolledFile.delete();
    }
    await _activeFile.rename(_rolledFile.path);
    await _activeFile.writeAsString('');
  }
}

Future<AppLogSink> createPlatformAppLogSink() {
  return RollingFileAppLogSink.create();
}
