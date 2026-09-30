package ch.cbue.gh_todos.widget

import android.content.Context
import android.util.AtomicFile
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import androidx.core.content.edit

internal data class WidgetProject(
    val id: String,
    val name: String,
    val ownerLogin: String,
    val issueQuery: String,
    val dueDateFieldId: String?,
    val priorityFieldId: String?,
    val priorityOptionMap: Map<String, String>,
)

internal object WidgetProjects {
    private const val fileName = "widget_projects.json"
    private const val preferencesName = "gh_todos_widget_selection"

    fun read(context: Context): List<WidgetProject>? = try {
        val file = AtomicFile(File(context.filesDir, fileName))
        val array = JSONArray(file.openRead().bufferedReader().use { it.readText() })
        (0 until array.length()).map { index ->
            val value = array.getJSONObject(index)
            val options = value.optJSONObject("priorityOptionMap") ?: JSONObject()
            WidgetProject(
                id = value.getString("id"),
                name = value.getString("name"),
                ownerLogin = value.optString("ownerLogin"),
                issueQuery = value.optString("issueQuery", "assignee:@me"),
                dueDateFieldId = value.optionalString("dueDateFieldId"),
                priorityFieldId = value.optionalString("priorityFieldId"),
                priorityOptionMap = options.keys().asSequence().associateWith { options.getString(it) },
            )
        }
    } catch (_: Exception) {
        null
    }

    fun write(context: Context, json: String) {
        // Validate before replacing the last good cache.
        JSONArray(json)
        val file = AtomicFile(File(context.filesDir, fileName))
        val stream = file.startWrite()
        try {
            stream.write(json.toByteArray(Charsets.UTF_8))
            file.finishWrite(stream)
        } catch (error: Exception) {
            file.failWrite(stream)
            throw error
        }
    }

    fun clear(context: Context) {
        AtomicFile(File(context.filesDir, fileName)).delete()
    }

    fun selectedId(context: Context, widgetId: Int): String? =
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .getString(widgetId.toString(), null)

    fun select(context: Context, widgetId: Int, projectId: String) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit { putString(widgetId.toString(), projectId) }
    }

    fun remove(context: Context, widgetId: Int) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit { remove(widgetId.toString()) }
    }

    private fun JSONObject.optionalString(key: String): String? =
        if (isNull(key)) null else optString(key).takeIf { it.isNotEmpty() }
}
