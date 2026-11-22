import os
import shutil
import subprocess

# 0) صورة الهيدر + شعار التطبيق
os.makedirs('assets', exist_ok=True)
shutil.copy('header.jpg', 'assets/header.jpg')
subprocess.run(['flutter', 'pub', 'get'], check=True)
subprocess.run(['dart', 'run', 'flutter_launcher_icons'], check=True)

# 1) صلاحيات وإعدادات الإشعارات في ملف AndroidManifest
p = 'android/app/src/main/AndroidManifest.xml'
s = open(p, encoding='utf-8').read()
perms = '''<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    '''
s = s.replace('<application', perms + '<application', 1)
recv = '''<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    '''
s = s.replace('</application>', recv + '</application>', 1)
import re
s = re.sub(r'android:label="[^"]*"', 'android:label="جدول BUA"', s, count=1)
open(p, 'w', encoding='utf-8').write(s)

# 2) تفعيل desugaring اللي مكتبة الإشعارات محتاجاها
for name in ['android/app/build.gradle', 'android/app/build.gradle.kts']:
    if not os.path.exists(name):
        continue
    g = open(name, encoding='utf-8').read()
    if name.endswith('.kts'):
        g = g.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n}\n'
    else:
        g = g.replace('compileOptions {', 'compileOptions {\n        coreLibraryDesugaringEnabled true', 1)
        g += '\ndependencies {\n    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.0.4"\n}\n'
    open(name, 'w', encoding='utf-8').write(g)

# 3) كود أندرويد لاختيار صوت المنبه (نغمات الموبايل + أي ملف صوت/أغنية)
import glob, re
KOTLIN = r'''package __PKG__

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "bua/sound"
    private val rcRingtone = 7101
    private val rcFile = 7102
    private var pending: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickRingtone" -> {
                        if (pending != null) { result.error("busy", "busy", null); return@setMethodCallHandler }
                        pending = result
                        val i = Intent(RingtoneManager.ACTION_RINGTONE_PICKER)
                        i.putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE,
                            RingtoneManager.TYPE_ALARM or RingtoneManager.TYPE_RINGTONE or RingtoneManager.TYPE_NOTIFICATION)
                        i.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                        i.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                        val cur = call.argument<String>("current")
                        if (cur != null) i.putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(cur))
                        startActivityForResult(i, rcRingtone)
                    }
                    "pickFile" -> {
                        if (pending != null) { result.error("busy", "busy", null); return@setMethodCallHandler }
                        pending = result
                        val i = Intent(Intent.ACTION_OPEN_DOCUMENT)
                        i.addCategory(Intent.CATEGORY_OPENABLE)
                        i.type = "audio/*"
                        i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        startActivityForResult(i, rcFile)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != rcRingtone && requestCode != rcFile) return
        val r = pending
        pending = null
        if (r == null) return
        if (resultCode != Activity.RESULT_OK || data == null) { r.success(null); return }
        if (requestCode == rcRingtone) {
            try {
                val uri: Uri? = if (Build.VERSION.SDK_INT >= 33)
                    data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
                else data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                if (uri == null) {
                    r.success(mapOf<String, String?>("uri" to null, "title" to "الافتراضي"))
                } else {
                    val title = try { RingtoneManager.getRingtone(this, uri)?.getTitle(this) } catch (e: Exception) { null }
                    r.success(mapOf<String, String?>("uri" to uri.toString(), "title" to (title ?: "نغمة")))
                }
            } catch (e: Exception) { r.error("fail", e.message, null) }
            return
        }
        val src = data.data
        if (src == null) { r.success(null); return }
        Thread {
            try {
                val name = displayName(src)
                val out = makeReadable(src, name)
                runOnUiThread { r.success(mapOf<String, String?>("uri" to out.toString(), "title" to name)) }
            } catch (e: Exception) {
                runOnUiThread { r.error("fail", e.message, null) }
            }
        }.start()
    }

    private fun displayName(uri: Uri): String {
        var name = "صوت مخصص"
        try {
            contentResolver.query(uri, null, null, null, null)?.use { c ->
                val idx = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0 && c.moveToFirst()) name = c.getString(idx) ?: name
            }
        } catch (e: Exception) {}
        return name
    }

    // نظام الإشعارات لازم يقدر يقرأ الملف، فبننسخه لمجلد المنبهات (أندرويد 10+)
    private fun makeReadable(src: Uri, name: String): Uri {
        if (Build.VERSION.SDK_INT >= 29) {
            val prefs = getSharedPreferences("bua_sound", MODE_PRIVATE)
            prefs.getString("last", null)?.let {
                try { contentResolver.delete(Uri.parse(it), null, null) } catch (e: Exception) {}
            }
            val mime = contentResolver.getType(src) ?: "audio/mpeg"
            val v = ContentValues().apply {
                put(MediaStore.Audio.Media.DISPLAY_NAME, "bua_" + System.currentTimeMillis() + "_" + name)
                put(MediaStore.Audio.Media.MIME_TYPE, mime)
                put(MediaStore.Audio.Media.RELATIVE_PATH, "Alarms/BUA")
                put(MediaStore.Audio.Media.IS_ALARM, 1)
                put(MediaStore.Audio.Media.IS_PENDING, 1)
            }
            val dst = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, v)
                ?: throw Exception("insert failed")
            contentResolver.openInputStream(src)!!.use { i ->
                contentResolver.openOutputStream(dst)!!.use { o -> i.copyTo(o) }
            }
            val done = ContentValues()
            done.put(MediaStore.Audio.Media.IS_PENDING, 0)
            contentResolver.update(dst, done, null, null)
            prefs.edit().putString("last", dst.toString()).apply()
            return dst
        }
        try { contentResolver.takePersistableUriPermission(src, Intent.FLAG_GRANT_READ_URI_PERMISSION) } catch (e: Exception) {}
        try { grantUriPermission("com.android.systemui", src, Intent.FLAG_GRANT_READ_URI_PERMISSION) } catch (e: Exception) {}
        return src
    }
}
'''
found = glob.glob('android/app/src/main/**/MainActivity.*', recursive=True)
if found:
    f = found[0]
    src = open(f, encoding='utf-8').read()
    m = re.search(r'package\s+([\w.]+)', src)
    pkg = m.group(1) if m else 'com.example.b3_schedule'
    d = os.path.dirname(f)
    for old in found:
        os.remove(old)
    open(os.path.join(d, 'MainActivity.kt'), 'w', encoding='utf-8').write(
        KOTLIN.replace('__PKG__', pkg))
else:
    print('WARNING: MainActivity not found - sound picker will not work')
print('patched')
