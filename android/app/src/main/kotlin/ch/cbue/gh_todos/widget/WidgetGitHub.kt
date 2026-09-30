package ch.cbue.gh_todos.widget

import android.content.Context
import ch.cbue.gh_todos.widget.graphql.WidgetCloseIssueMutation
import ch.cbue.gh_todos.widget.graphql.WidgetProjectIssuesQuery
import ch.cbue.gh_todos.widget.graphql.WidgetReopenIssueMutation
import ch.cbue.gh_todos.widget.graphql.type.IssueState
import com.apollographql.apollo.ApolloClient
import com.apollographql.apollo.api.ApolloResponse
import com.apollographql.apollo.api.Operation
import com.apollographql.apollo.api.http.HttpRequest
import com.apollographql.apollo.api.http.HttpResponse
import com.apollographql.apollo.network.http.HttpInterceptor
import com.apollographql.apollo.network.http.HttpInterceptorChain
import com.it_nomads.fluttersecurestorage.FlutterSecureStorage
import com.it_nomads.fluttersecurestorage.FlutterSecureStorageConfig
import com.it_nomads.fluttersecurestorage.SecurePreferencesCallback
import kotlinx.coroutines.suspendCancellableCoroutine
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

internal data class WidgetTodo(
    val id: String,
    val title: String,
    val updatedAt: Date,
    val closed: Boolean,
    val priority: String?,
    val dueDate: String?,
)

internal class WidgetFailure(val code: String) : Exception(code)

internal class WidgetGitHub(context: Context) {
    private val todoOrder = compareBy<WidgetTodo> { it.closed }
        .thenBy { priorityRank(it.priority) }
        .thenBy { it.dueDate ?: "9999-99-99" }
        .thenByDescending { it.updatedAt.time }

    private val credential = WidgetCredential(context.applicationContext)
    private val client = ApolloClient.Builder()
        .serverUrl("https://api.github.com/graphql")
        .addHttpInterceptor(object : HttpInterceptor {
            override suspend fun intercept(request: HttpRequest, chain: HttpInterceptorChain): HttpResponse {
                val token = credential.read() ?: throw WidgetFailure("credential_missing")
                return chain.proceed(request.newBuilder().addHeader("Authorization", "Bearer $token").build())
            }
        })
        .build()

    suspend fun todos(project: WidgetProject): List<WidgetTodo> {
        val data = client.query(WidgetProjectIssuesQuery(project.id, project.issueQuery))
            .execute().requiredData()
        val projectData = data.node?.onProjectV2 ?: throw WidgetFailure("project_data_missing")
        val items = projectData.items.nodes.orEmpty()
        val now = Date().time
        return items.mapNotNull { item ->
            val issue = item?.content?.onIssue ?: return@mapNotNull null
            val updatedAt = parseTimestamp(issue.updatedAt) ?: return@mapNotNull null
            val closed = issue.state == IssueState.CLOSED
            if (closed) {
                val closedAt = if (issue.closedAt == null) updatedAt
                    else parseTimestamp(issue.closedAt) ?: return@mapNotNull null
                if (closedAt.time < now - 3L * 24 * 60 * 60 * 1000) return@mapNotNull null
            }

            var priority: String? = null
            var dueDate: String? = null
            item.fieldValues?.nodes?.forEach { fieldValue ->
                val select = fieldValue?.onProjectV2ItemFieldSingleSelectValue
                if (priority == null && select != null && project.priorityFieldId != null &&
                    select.field.onProjectV2SingleSelectField?.id == project.priorityFieldId
                ) {
                    priority = project.priorityOptionMap[select.optionId]
                }
                val date = fieldValue?.onProjectV2ItemFieldDateValue
                if (dueDate == null && date != null && project.dueDateFieldId != null &&
                    date.field.onProjectV2Field?.id == project.dueDateFieldId
                ) {
                    dueDate = date.date
                }
            }
            WidgetTodo(issue.id, issue.title, updatedAt, closed, priority, dueDate)
        }.sortedWith(todoOrder)
    }

    fun withActionState(todos: List<WidgetTodo>, issueId: String, closed: Boolean): List<WidgetTodo> =
        todos.map { todo ->
            if (todo.id == issueId) todo.copy(closed = closed, updatedAt = Date()) else todo
        }.sortedWith(todoOrder)

    suspend fun close(issueId: String) {
        val data = client.mutation(WidgetCloseIssueMutation(issueId)).execute().requiredData()
        if (data.closeIssue?.issue?.id == null) throw WidgetFailure("mutation_data_missing")
    }

    suspend fun reopen(issueId: String) {
        val data = client.mutation(WidgetReopenIssueMutation(issueId)).execute().requiredData()
        if (data.reopenIssue?.issue?.id == null) throw WidgetFailure("mutation_data_missing")
    }

    fun dispose() = client.close()

    private fun <D : Operation.Data> ApolloResponse<D>.requiredData(): D {
        exception?.let { failure ->
            generateSequence(failure as Throwable?) { it.cause }
                .filterIsInstance<WidgetFailure>()
                .firstOrNull()?.let { throw it }
            throw WidgetFailure("transport_failed")
        }
        if (!errors.isNullOrEmpty()) throw WidgetFailure("graphql_failed")
        return data ?: throw WidgetFailure("decode_failed")
    }

    private fun priorityRank(priority: String?): Int = when (priority) {
        "urgent" -> 0
        "high" -> 1
        "medium" -> 2
        null -> 3
        "low" -> 4
        "trivial" -> 5
        else -> 3
    }

    private fun parseTimestamp(value: String): Date? {
        val normalized = value.replace(Regex("\\.(\\d+)Z$")) { match ->
            ".${match.groupValues[1].padEnd(3, '0').take(3)}Z"
        }
        for (pattern in listOf("yyyy-MM-dd'T'HH:mm:ss.SSSX", "yyyy-MM-dd'T'HH:mm:ssX")) {
            val format = SimpleDateFormat(pattern, Locale.US).apply { isLenient = false }
            runCatching { format.parse(normalized) }.getOrNull()?.let { return it }
        }
        return null
    }
}

private class WidgetCredential(context: Context) {
    private val storage = FlutterSecureStorage(context)
    private val config = FlutterSecureStorageConfig(mapOf("resetOnError" to "true"))

    suspend fun read(): String? {
        suspendCancellableCoroutine<Unit> { continuation ->
            storage.initialize(config, object : SecurePreferencesCallback<Void> {
                override fun onSuccess(result: Void?) { continuation.resume(Unit) }
                override fun onError(error: Exception) { continuation.resumeWithException(error) }
            })
        }
        val key = storage.addPrefixToKey("github.personal_access_token")
        return suspendCancellableCoroutine { continuation ->
            storage.read(key, object : SecurePreferencesCallback<String> {
                override fun onSuccess(result: String?) { continuation.resume(result?.trim()?.takeIf { it.isNotEmpty() }) }
                override fun onError(error: Exception) { continuation.resumeWithException(error) }
            })
        }
    }
}
