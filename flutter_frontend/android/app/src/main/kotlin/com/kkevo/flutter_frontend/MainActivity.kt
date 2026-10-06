package com.kkevo.flutter_frontend

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.LocaleManager
import android.os.Build
import android.os.LocaleList
import android.content.Intent

class MainActivity : FlutterActivity() {
    private val handoff by lazy { NativeHandoff(this) }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kkevo.family/handoff")
            .setMethodCallHandler { call, result -> handoff.handle(call, result) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kkevo.family/language")
            .setMethodCallHandler { call, result ->
                if (Build.VERSION.SDK_INT < 33) {
                    result.success(null)
                    return@setMethodCallHandler
                }
                val manager = getSystemService(LocaleManager::class.java)
                when (call.method) {
                    "getLanguage" -> result.success(manager.applicationLocales.toLanguageTags())
                    "setLanguage" -> {
                        val language = call.arguments as? String ?: ""
                        if (language !in listOf("", "en", "fr")) {
                            result.error("unsupported_language", "Unsupported language", null)
                        } else {
                            manager.applicationLocales = LocaleList.forLanguageTags(language)
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!handoff.onResult(requestCode, resultCode, data)) super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        handoff.close()
        super.onDestroy()
    }
}
