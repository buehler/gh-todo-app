import 'dart:io';

import 'package:flutter/services.dart';

class WidgetSharedProjectFileService {
  static const _channel = MethodChannel('ch.cbue.ghTodos/widget_project_cache');

  Future<void> writeProjectsJson(String json) async {
    if (!Platform.isIOS) {
      return;
    }

    await _channel.invokeMethod<void>('writeProjectsJson', {'json': json});
  }

  Future<void> clearProjectsJson() async {
    if (!Platform.isIOS) {
      return;
    }

    await _channel.invokeMethod<void>('clearProjectsJson');
  }
}
