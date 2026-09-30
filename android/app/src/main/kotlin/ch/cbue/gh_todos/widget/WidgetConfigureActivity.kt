package ch.cbue.gh_todos.widget

import android.app.Activity
import android.app.AlertDialog
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import ch.cbue.gh_todos.MainActivity

class WidgetConfigureActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        val provider = AppWidgetManager.getInstance(this).getAppWidgetInfo(widgetId)?.provider
        if (provider?.className != GHTodosWidgetProvider::class.java.name) {
            finish()
            return
        }

        val projects = WidgetProjects.read(this).orEmpty()
        if (projects.isEmpty()) {
            AlertDialog.Builder(this)
                .setTitle("GH Todos")
                .setMessage("Open GH Todos and add a GitHub Project before placing this widget.")
                .setPositiveButton("Open app") { _, _ ->
                    startActivity(Intent(this, MainActivity::class.java))
                    finish()
                }
                .setNegativeButton("Cancel") { _, _ -> finish() }
                .setOnCancelListener { finish() }
                .show()
            return
        }

        AlertDialog.Builder(this)
            .setTitle("Select project")
            .setItems(projects.map { "${it.name} · ${it.ownerLogin}" }.toTypedArray()) { _, index ->
                WidgetProjects.select(this, widgetId, projects[index].id)
                WidgetViews.renderMessage(this, widgetId, "Loading todos…")
                WidgetWork.refresh(this)
                setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
                finish()
            }
            .setNegativeButton("Cancel") { _, _ -> finish() }
            .setOnCancelListener { finish() }
            .show()
    }
}
