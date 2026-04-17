import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'package:gh_todos/services/app_log_file_sink_factory.dart';

enum AppLogLevel { debug, info, warn, error }

abstract class AppLogSink {
  Future<void> write(String line);

  Future<List<String>> readLines();

  Future<void> clear();
}

class MemoryAppLogSink implements AppLogSink {
  MemoryAppLogSink({this.maxBytes = 5 * 1024 * 1024});

  final int maxBytes;
  final Queue<String> _lines = ListQueue<String>();
  int _currentBytes = 0;

  @override
  Future<void> clear() async {
    _lines.clear();
    _currentBytes = 0;
  }

  @override
  Future<List<String>> readLines() async => _lines.toList(growable: false);

  @override
  Future<void> write(String line) async {
    final size = utf8.encode('$line\n').length;
    _lines.addLast(line);
    _currentBytes += size;
    while (_currentBytes > maxBytes && _lines.isNotEmpty) {
      final removed = _lines.removeFirst();
      _currentBytes -= utf8.encode('$removed\n').length;
    }
  }
}

class AppLogStore {
  AppLogStore({FutureOr<AppLogSink> Function()? sinkFactory})
    : _sinkFactory =
          sinkFactory ??
          (() => kIsWeb ? MemoryAppLogSink() : createPlatformAppLogSink()) {
    _initialized = _initialize();
  }

  final StreamController<List<String>> _controller =
      StreamController<List<String>>.broadcast();
  final FutureOr<AppLogSink> Function() _sinkFactory;
  late final Future<void> _initialized;
  Future<void> _chain = Future<void>.value();
  AppLogSink? _sink;
  List<String> _lines = const [];

  Stream<List<String>> get stream async* {
    await _initialized;
    yield _lines;
    yield* _controller.stream;
  }

  Future<void> _initialize() async {
    _sink = await _sinkFactory();
    _lines = await _sink!.readLines();
    _controller.add(_lines);
  }

  Future<List<String>> readLines() async {
    await _initialized;
    return List<String>.unmodifiable(_lines);
  }

  Future<void> append(String line) async {
    await _initialized;
    _chain = _chain.then((_) async {
      await _sink!.write(line);
      _lines = await _sink!.readLines();
      _controller.add(List<String>.unmodifiable(_lines));
    });
    await _chain;
  }

  Future<void> clear() async {
    await _initialized;
    _chain = _chain.then((_) async {
      await _sink!.clear();
      _lines = const [];
      _controller.add(_lines);
    });
    await _chain;
  }

  void dispose() {
    unawaited(_controller.close());
  }
}

class AppLogger {
  const AppLogger({required this.store});

  final AppLogStore store;

  Future<void> debug(
    String message, {
    String category = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    return _log(
      AppLogLevel.debug,
      message,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> info(
    String message, {
    String category = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    return _log(
      AppLogLevel.info,
      message,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> warn(
    String message, {
    String category = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    return _log(
      AppLogLevel.warn,
      message,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> error(
    String message, {
    String category = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    return _log(
      AppLogLevel.error,
      message,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> clear() => store.clear();

  Future<List<String>> readLines() => store.readLines();

  Future<void> _log(
    AppLogLevel level,
    String message, {
    required String category,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final rendered = StringBuffer(
      '[$timestamp] ${level.name.toUpperCase()} [$category] $message',
    );
    if (error != null) {
      rendered.write(' | error=$error');
    }
    if (stackTrace != null) {
      rendered.write(' | stack=${_singleLine(stackTrace.toString())}');
    }

    final line = rendered.toString();
    developer.log(
      message,
      name: category,
      level: _developerLevel(level),
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
    await store.append(line);
  }

  String _singleLine(String input) {
    return input.replaceAll('\n', ' | ').replaceAll('\r', ' ');
  }

  int _developerLevel(AppLogLevel level) {
    switch (level) {
      case AppLogLevel.debug:
        return 500;
      case AppLogLevel.info:
        return 800;
      case AppLogLevel.warn:
        return 900;
      case AppLogLevel.error:
        return 1000;
    }
  }
}
