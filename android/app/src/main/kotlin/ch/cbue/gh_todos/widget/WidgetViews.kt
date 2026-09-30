package ch.cbue.gh_todos.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Paint
import android.net.Uri
import android.os.Build
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import ch.cbue.gh_todos.MainActivity
import ch.cbue.gh_todos.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

internal object WidgetViews {
    private const val largeMinHeight = 408

    fun render(context: Context, widgetId: Int, project: WidgetProject, todos: List<WidgetTodo>) {
        update(context, widgetId) { maxRows ->
            base(context, widgetId, project).apply {
                setTextViewText(R.id.widget_updated, "Updated ${SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())}")
                if (todos.isEmpty()) {
                    setViewVisibility(R.id.widget_message, View.VISIBLE)
                    setTextViewText(R.id.widget_message, "✓  all done for now")
                } else {
                    todos.distinctBy { it.id }.take(maxRows).forEach { todo ->
                        addView(R.id.widget_rows, row(context, widgetId, project, todo))
                    }
                }
            }
        }
    }

    fun renderMessage(context: Context, widgetId: Int, message: String) {
        update(context, widgetId) {
            base(context, widgetId, null).apply {
                setViewVisibility(R.id.widget_message, View.VISIBLE)
                setTextViewText(R.id.widget_message, message)
            }
        }
    }

    fun renderError(context: Context, widgetId: Int, code: String) {
        val diagnostic = UUID.randomUUID().toString().take(8).uppercase(Locale.US)
        update(context, widgetId) {
            base(context, widgetId, null).apply {
                setViewVisibility(R.id.widget_message, View.VISIBLE)
                setTextViewText(
                    R.id.widget_message,
                    "GH Todos could not refresh. Tap to open the app, or try refreshing.\n$code · $diagnostic",
                )
                setViewVisibility(R.id.widget_refresh, View.VISIBLE)
                setOnClickPendingIntent(R.id.widget_refresh, actionIntent(context, widgetId, null, "refresh"))
            }
        }
    }

    private fun base(context: Context, widgetId: Int, project: WidgetProject?): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_todos).apply {
            removeAllViews(R.id.widget_rows)
            setViewVisibility(R.id.widget_message, View.GONE)
            setTextViewText(R.id.widget_message, "")
            setTextViewText(R.id.widget_updated, "")
            setTextViewText(R.id.widget_title, project?.name ?: "GH Todos")
            setViewVisibility(R.id.widget_add, if (project == null) View.GONE else View.VISIBLE)
            setViewVisibility(R.id.widget_refresh, if (project == null) View.GONE else View.VISIBLE)
            setOnClickPendingIntent(R.id.widget_root, openApp(context, widgetId, project?.id))
            if (project != null) {
                setOnClickPendingIntent(R.id.widget_project_link, openApp(context, widgetId, project.id))
                setOnClickPendingIntent(R.id.widget_add, openApp(context, widgetId, project.id, "new"))
                setOnClickPendingIntent(R.id.widget_refresh, actionIntent(context, widgetId, null, "refresh"))
            }
        }

    private fun row(context: Context, widgetId: Int, project: WidgetProject, todo: WidgetTodo): RemoteViews {
        val (background, accent) = when (todo.priority) {
            "urgent" -> R.drawable.widget_row_urgent to R.color.widget_urgent
            "high" -> R.drawable.widget_row_high to R.color.widget_high
            "medium" -> R.drawable.widget_row_medium to R.color.widget_medium
            "low" -> R.drawable.widget_row_low to R.color.widget_low
            "trivial" -> R.drawable.widget_row_trivial to R.color.widget_trivial
            else -> R.drawable.widget_row_neutral to android.R.color.transparent
        }
        val titleFlags = Paint.ANTI_ALIAS_FLAG or
            (if (todo.closed) Paint.STRIKE_THRU_TEXT_FLAG else 0)
        return RemoteViews(context.packageName, R.layout.widget_todo_row).apply {
            setInt(R.id.widget_row, "setBackgroundResource", background)
            setInt(R.id.widget_row_accent, "setBackgroundColor", context.getColor(accent))
            setTextViewText(R.id.widget_row_title, todo.title)
            setTextColor(R.id.widget_row_title, context.getColor(if (todo.closed) R.color.widget_muted else R.color.widget_text))
            setInt(R.id.widget_row_title, "setPaintFlags", titleFlags)
            setFloat(R.id.widget_row, "setAlpha", if (todo.closed) 0.58f else 1f)
            setViewVisibility(R.id.widget_row_due, if (todo.dueDate == null) View.GONE else View.VISIBLE)
            setTextViewText(R.id.widget_row_due, todo.dueDate?.let { "▦  ${formatDueDate(it)}" } ?: "")
            setTextViewText(R.id.widget_row_state, if (todo.closed) "✓" else "○")
            setContentDescription(R.id.widget_row_state, if (todo.closed) "Reopen todo" else "Close todo")
            setOnClickPendingIntent(R.id.widget_row_link, openApp(context, widgetId, project.id, "issue", todo.id))
            setOnClickPendingIntent(
                R.id.widget_row_state,
                actionIntent(context, widgetId, todo.id, if (todo.closed) "reopen" else "close"),
            )
        }
    }

    private fun formatDueDate(value: String): String {
        val parsed = runCatching { SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(value) }
            .getOrNull() ?: return value
        val year = SimpleDateFormat("yyyy", Locale.US).format(parsed)
        val currentYear = SimpleDateFormat("yyyy", Locale.US).format(Date())
        return SimpleDateFormat(if (year == currentYear) "MMM d" else "MMM d, yyyy", Locale.getDefault()).format(parsed)
    }

    private fun update(context: Context, widgetId: Int, build: (Int) -> RemoteViews) {
        val manager = AppWidgetManager.getInstance(context)
        val views = if (Build.VERSION.SDK_INT >= 31) {
            RemoteViews(
                mapOf(
                    SizeF(250f, 180f) to build(2),
                    SizeF(250f, largeMinHeight.toFloat()) to build(6),
                ),
            )
        } else {
            val heightKey = if (context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE)
                AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT
            else AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT
            val height = manager.getAppWidgetOptions(widgetId).getInt(heightKey)
            build(if (height >= largeMinHeight) 6 else 2)
        }
        manager.updateAppWidget(widgetId, views)
    }

    private fun openApp(context: Context, widgetId: Int, vararg path: String?): PendingIntent {
        val uri = Uri.Builder().scheme("ghtodos").authority("local").apply {
            if (path.firstOrNull() != null) {
                appendPath("project")
                path.filterNotNull().forEach(::appendPath)
            }
        }.build()
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = uri
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context, widgetId xor uri.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun actionIntent(context: Context, widgetId: Int, issueId: String?, action: String): PendingIntent {
        val uri = Uri.Builder().scheme("ghtodos-widget").authority("action")
            .appendPath(widgetId.toString()).appendPath(action).apply { issueId?.let(::appendPath) }.build()
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            this.action = action
            data = uri
            putExtra(WidgetWork.widgetIdKey, widgetId)
            issueId?.let { putExtra(WidgetWork.issueIdKey, it) }
        }
        return PendingIntent.getBroadcast(
            context, widgetId xor uri.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
