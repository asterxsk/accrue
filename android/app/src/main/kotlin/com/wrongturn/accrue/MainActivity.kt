package com.wrongturn.accrue

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val shareChannel = "habit_tracker/share"
    private val updatesChannel = "habit_tracker/updates"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, shareChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareText" -> shareText(call, result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(messenger, updatesChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "downloadDir" -> result.success(updateDir().absolutePath)
                    "installApk" -> installApk(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun shareText(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
    ) {
        val text = call.argument<String>("text")
        val subject = call.argument<String>("subject")
        if (text.isNullOrBlank()) {
            result.error("empty", "Nothing to share", null)
            return
        }
        try {
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                subject?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
            }
            val chooser = Intent.createChooser(send, subject ?: "Share")
            startActivity(chooser)
            result.success(true)
        } catch (error: Exception) {
            result.error("unavailable", error.message, null)
        }
    }

    /** Cache folder the Dart side writes downloaded APKs into. */
    private fun updateDir(): File = File(cacheDir, "updates").apply { mkdirs() }

    /**
     * Hands a downloaded APK to Android's installer. Android owns the
     * confirmation dialog; on first use it also needs this app allowed to
     * install unknown apps, which we open in settings and report back.
     */
    private fun installApk(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
    ) {
        val path = call.argument<String>("path")
        if (path.isNullOrBlank()) {
            result.error("missing", "No download to install.", null)
            return
        }
        val file = File(path)
        if (!file.exists()) {
            result.error("missing", "The download is gone. Download it again.", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            try {
                startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:$packageName"),
                    ),
                )
            } catch (_: Exception) {
                try {
                    startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
                } catch (_: Exception) {
                }
            }
            result.error(
                "permission",
                "Allow Accrue to install apps, then tap Install again.",
                null,
            )
            return
        }
        try {
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file,
            )
            val install = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(install)
            result.success(true)
        } catch (error: Exception) {
            result.error("unavailable", error.message, null)
        }
    }
}
