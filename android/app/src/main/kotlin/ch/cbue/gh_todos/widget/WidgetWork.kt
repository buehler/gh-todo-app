package ch.cbue.gh_todos.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkerParameters
import androidx.work.WorkManager
import androidx.work.workDataOf
import kotlinx.coroutines.CancellationException
import java.util.concurrent.TimeUnit

internal object WidgetWork {
    private const val refreshName = "gh_todos_widget_refresh"
    private const val periodicName = "gh_todos_widget_periodic"
    const val actionKey = "action"
    const val issueIdKey = "issueId"
    const val widgetIdKey = "widgetId"

    fun schedulePeriodic(context: Context) {
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            periodicName,
            ExistingPeriodicWorkPolicy.KEEP,
            PeriodicWorkRequestBuilder<WidgetWorker>(1, TimeUnit.HOURS).build(),
        )
    }

    fun cancelPeriodic(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(periodicName)
    }

    fun refresh(context: Context) {
        WorkManager.getInstance(context).enqueueUniqueWork(
            refreshName,
            ExistingWorkPolicy.REPLACE,
            OneTimeWorkRequestBuilder<WidgetWorker>().build(),
        )
    }

    fun mutate(context: Context, widgetId: Int, issueId: String, action: String) {
        WorkManager.getInstance(context).enqueue(
            OneTimeWorkRequestBuilder<WidgetWorker>()
                .setInputData(workDataOf(widgetIdKey to widgetId, issueIdKey to issueId, actionKey to action))
                .build(),
        )
    }
}

internal class WidgetWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val manager = AppWidgetManager.getInstance(applicationContext)
        val widgetIds = manager.getAppWidgetIds(
            ComponentName(applicationContext, GHTodosWidgetProvider::class.java),
        )
        if (widgetIds.isEmpty()) return Result.success()

        val github = WidgetGitHub(applicationContext)
        try {
            val action = inputData.getString(WidgetWork.actionKey)
            val actionWidgetId = inputData.getInt(WidgetWork.widgetIdKey, AppWidgetManager.INVALID_APPWIDGET_ID)
            val issueId = inputData.getString(WidgetWork.issueIdKey)
            val actionState = if (action in setOf("close", "reopen") && issueId != null && actionWidgetId in widgetIds) {
                try {
                    when (action) {
                        "close" -> github.close(issueId)
                        "reopen" -> github.reopen(issueId)
                    }
                } catch (cancelled: CancellationException) {
                    throw cancelled
                } catch (error: Exception) {
                    WidgetViews.renderError(applicationContext, actionWidgetId, errorCode(error))
                    return Result.success()
                }
                issueId to (action == "close")
            } else null

            val projects = WidgetProjects.read(applicationContext)
            val results = mutableMapOf<String, kotlin.Result<List<WidgetTodo>>>()
            for (widgetId in widgetIds) {
                val selected = WidgetProjects.selectedId(applicationContext, widgetId)
                when {
                    selected == null -> WidgetViews.renderMessage(applicationContext, widgetId, "Select a project in widget settings.")
                    projects == null -> WidgetViews.renderError(applicationContext, widgetId, "project_cache_unavailable")
                    else -> {
                        val project = projects.firstOrNull { it.id == selected }
                        if (project == null) {
                            WidgetViews.renderMessage(applicationContext, widgetId, "Project unavailable. Reconfigure this widget.")
                        } else {
                            val loaded = results[selected] ?: try {
                                kotlin.Result.success(github.todos(project))
                            } catch (cancelled: CancellationException) {
                                throw cancelled
                            } catch (error: Exception) {
                                kotlin.Result.failure(error)
                            }.also { results[selected] = it }
                            loaded.fold(
                                onSuccess = { todos ->
                                    val displayed = actionState?.let { (changedId, closed) ->
                                        github.withActionState(todos, changedId, closed)
                                    } ?: todos
                                    WidgetViews.render(applicationContext, widgetId, project, displayed)
                                },
                                onFailure = { WidgetViews.renderError(applicationContext, widgetId, errorCode(it)) },
                            )
                        }
                    }
                }
            }
            return Result.success()
        } finally {
            github.dispose()
        }
    }

    private fun errorCode(error: Throwable): String =
        (error as? WidgetFailure)?.code ?: "refresh_failed"
}
