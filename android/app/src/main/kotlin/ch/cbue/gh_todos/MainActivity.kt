package ch.cbue.gh_todos

import ch.cbue.gh_todos.widget.WidgetProjects
import ch.cbue.gh_todos.widget.WidgetWork
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ch.cbue.ghTodos/widget_project_cache")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "writeProjectsJson" -> {
                            val json = call.argument<String>("json")
                                ?: throw IllegalArgumentException("Missing project JSON")
                            WidgetProjects.write(applicationContext, json)
                            WidgetWork.refresh(applicationContext)
                            result.success(null)
                        }
                        "clearProjectsJson" -> {
                            WidgetProjects.clear(applicationContext)
                            WidgetWork.refresh(applicationContext)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    result.error("widget_cache_failed", "Could not update widget projects", null)
                }
            }
    }
}
