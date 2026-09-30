package ch.cbue.gh_todos.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle

class GHTodosWidgetProvider : AppWidgetProvider() {
    override fun onEnabled(context: Context) {
        WidgetWork.schedulePeriodic(context)
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, widgetIds: IntArray) {
        WidgetWork.schedulePeriodic(context)
        WidgetWork.refresh(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, widgetId: Int, options: Bundle) {
        if (Build.VERSION.SDK_INT < 31) WidgetWork.refresh(context)
    }

    override fun onDeleted(context: Context, widgetIds: IntArray) {
        widgetIds.forEach { WidgetProjects.remove(context, it) }
    }

    override fun onDisabled(context: Context) {
        WidgetWork.cancelPeriodic(context)
    }
}

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val widgetId = intent.getIntExtra(WidgetWork.widgetIdKey, AppWidgetManager.INVALID_APPWIDGET_ID)
        val action = intent.action ?: return
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID ||
            WidgetProjects.selectedId(context, widgetId) == null) return
        if (action == "refresh") {
            WidgetWork.refresh(context)
            return
        }
        val issueId = intent.getStringExtra(WidgetWork.issueIdKey) ?: return
        if (action !in setOf("close", "reopen")) return
        WidgetWork.mutate(context, widgetId, issueId, action)
    }
}
