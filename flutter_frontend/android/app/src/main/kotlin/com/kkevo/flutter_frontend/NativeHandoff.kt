package com.kkevo.flutter_frontend

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.util.concurrent.Executors

/** User-chosen documents only. Never request broad storage access or log content. */
class NativeHandoff(private val activity: Activity) {
    private val worker = Executors.newSingleThreadExecutor()
    private var pending: MethodChannel.Result? = null
    private var saveBytes: ByteArray? = null
    private val maxBytes = 10 * 1024 * 1024
    companion object { const val OPEN = 43010; const val SAVE = 43011 }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "shareText" -> {
                val text = call.argument<String>("text") ?: ""
                val title = call.argument<String>("title") ?: "Kkevo Family"
                if (text.isEmpty() || text.length > 2000 || title.length > 200) {
                    result.error("invalid_share", "Invalid invitation", null); return
                }
                try {
                    activity.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"; putExtra(Intent.EXTRA_TEXT, text)
                    }, title))
                    result.success(null) // Chooser opened; delivery is the user's decision.
                } catch (_: Exception) { result.error("share_unavailable", "Unable to open sharing", null) }
            }
            "openJson", "saveJson" -> {
                if (pending != null) { result.error("busy", "A document picker is already open", null); return }
                val saving = call.method == "saveJson"
                val bytes = if (saving) (call.argument<String>("text") ?: "").toByteArray(Charsets.UTF_8) else null
                if (saving && (bytes == null || bytes.isEmpty() || bytes.size > maxBytes)) {
                    result.error("file_limit", "Choose a JSON file under 10 MB", null); return
                }
                val intent = Intent(if (saving) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = if (saving) "application/json" else "*/*"
                    if (saving) putExtra(Intent.EXTRA_TITLE, "kkevo-family-export.json")
                }
                pending = result; saveBytes = bytes
                try { activity.startActivityForResult(intent, if (saving) SAVE else OPEN) }
                catch (_: Exception) { pending = null; saveBytes = null; result.error("picker_unavailable", "Unable to open files", null) }
            }
            else -> result.notImplemented()
        }
    }

    fun onResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != OPEN && requestCode != SAVE) return false
        val result = pending ?: return true
        val bytes = saveBytes
        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending = null; saveBytes = null; result.success(null); return true
        }
        if (uri.scheme != "content") {
            pending = null; saveBytes = null; result.error("invalid_file", "Unsupported document", null); return true
        }
        worker.execute {
            try {
                val value: Any = if (requestCode == SAVE) {
                    activity.contentResolver.openOutputStream(uri, "wt")?.use { it.write(bytes ?: throw IllegalStateException()) }
                        ?: throw IllegalStateException()
                    true
                } else {
                    val content = activity.contentResolver.openInputStream(uri)?.use { input ->
                        val output = ByteArrayOutputStream()
                        val buffer = ByteArray(8192)
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            if (output.size() + count > maxBytes) throw IllegalArgumentException()
                            output.write(buffer, 0, count)
                        }
                        output.toByteArray()
                    } ?: throw IllegalStateException()
                    if (content.size > maxBytes) throw IllegalArgumentException()
                    Charsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
                        .onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(content)).toString()
                }
                activity.runOnUiThread {
                    if (pending === result) { pending = null; saveBytes = null; result.success(value) }
                }
            } catch (_: Exception) {
                activity.runOnUiThread {
                    if (pending === result) { pending = null; saveBytes = null; result.error("file_unavailable", "Unable to read or save this file. Use UTF-8 JSON under 10 MB.", null) }
                }
            }
        }
        return true
    }

    fun close() {
        pending?.error("interrupted", "File selection was interrupted. Try again.", null)
        pending = null; saveBytes = null; worker.shutdownNow()
    }
}
