package com.lectures.c4_schedule

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "c4/sound")
            .setMethodCallHandler { call, result ->
                if (call.method == "pick") {
                    pending = result
                    val i = Intent(RingtoneManager.ACTION_RINGTONE_PICKER)
                    i.putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALL)
                    i.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                    i.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                    val cur = call.argument<String>("current")
                    if (cur != null) {
                        i.putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(cur))
                    }
                    startActivityForResult(i, 77)
                } else {
                    result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 77) {
            val r = pending
            pending = null
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri: Uri? = data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                var title = "الافتراضي"
                if (uri != null) {
                    try {
                        title = RingtoneManager.getRingtone(this, uri).getTitle(this)
                    } catch (e: Exception) {
                    }
                }
                r?.success(mapOf("uri" to uri?.toString(), "title" to title))
            } else {
                r?.success(null)
            }
        }
    }
}
