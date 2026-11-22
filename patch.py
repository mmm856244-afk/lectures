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
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
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

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "bua/sound"
    private val rcFile = 7102
    private val rcPerm = 7103
    private var pendingFile: MethodChannel.Result? = null
    private var pendingList: MethodChannel.Result? = null
    private var player: MediaPlayer? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listSounds" -> {
                        if (pendingList != null) { result.error("busy", "busy", null); return@setMethodCallHandler }
                        if (hasAudioPermission()) {
                            loadSounds(result, true)
                        } else {
                            pendingList = result
                            requestPermissions(arrayOf(audioPermission()), rcPerm)
                        }
                    }
                    "preview" -> {
                        val uri = call.argument<String>("uri")
                        if (uri == null) { result.success(null); return@setMethodCallHandler }
                        try { startPreview(uri); result.success(true) }
                        catch (e: Exception) { stopPreview(); result.error("fail", e.message, null) }
                    }
                    "stopPreview" -> { stopPreview(); result.success(null) }
                    "pickFile" -> {
                        if (pendingFile != null) { result.error("busy", "busy", null); return@setMethodCallHandler }
                        pendingFile = result
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

    private fun audioPermission(): String =
        if (Build.VERSION.SDK_INT >= 33) Manifest.permission.READ_MEDIA_AUDIO
        else Manifest.permission.READ_EXTERNAL_STORAGE

    private fun hasAudioPermission(): Boolean =
        checkSelfPermission(audioPermission()) == PackageManager.PERMISSION_GRANTED

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == rcPerm) {
            val r = pendingList
            pendingList = null
            if (r != null) loadSounds(r, grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
        }
    }

    // نغمات النظام + الأغاني اللي على الموبايل
    private fun loadSounds(result: MethodChannel.Result, withMusic: Boolean) {
        Thread {
            val tones = ArrayList<Map<String, String>>()
            val music = ArrayList<Map<String, String>>()
            try {
                val rm = RingtoneManager(this)
                rm.setType(RingtoneManager.TYPE_ALARM or RingtoneManager.TYPE_RINGTONE or RingtoneManager.TYPE_NOTIFICATION)
                val c = rm.cursor
                val seen = HashSet<String>()
                while (c.moveToNext()) {
                    val uri = rm.getRingtoneUri(c.position).toString()
                    if (seen.add(uri)) {
                        tones.add(mapOf("uri" to uri, "title" to (c.getString(RingtoneManager.TITLE_COLUMN_INDEX) ?: "نغمة")))
                    }
                }
            } catch (e: Exception) {}
            if (withMusic) {
                try {
                    val base = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                    val proj = arrayOf(MediaStore.Audio.Media._ID, MediaStore.Audio.Media.TITLE, MediaStore.Audio.Media.ARTIST)
                    contentResolver.query(base, proj, MediaStore.Audio.Media.IS_MUSIC + " != 0", null,
                        MediaStore.Audio.Media.TITLE + " COLLATE NOCASE ASC")?.use { c ->
                        while (c.moveToNext()) {
                            val id = c.getLong(0)
                            val title = c.getString(1) ?: "بدون اسم"
                            var artist = c.getString(2) ?: ""
                            if (artist == "<unknown>") artist = ""
                            music.add(mapOf("uri" to ContentUris.withAppendedId(base, id).toString(),
                                "title" to title, "artist" to artist))
                        }
                    }
                } catch (e: Exception) {}
            }
            runOnUiThread {
                result.success(mapOf("tones" to tones, "music" to music, "musicAllowed" to withMusic))
            }
        }.start()
    }

    private fun startPreview(uri: String) {
        stopPreview()
        val mp = MediaPlayer()
        mp.setAudioAttributes(AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
        mp.setDataSource(this, Uri.parse(uri))
        mp.setOnPreparedListener { it.start() }
        mp.setOnCompletionListener { stopPreview() }
        mp.setOnErrorListener { _, _, _ -> stopPreview(); true }
        mp.prepareAsync()
        player = mp
        handler.postDelayed({ stopPreview() }, 10000)
    }

    private fun stopPreview() {
        handler.removeCallbacksAndMessages(null)
        val p = player
        player = null
        if (p != null) {
            try { p.stop() } catch (e: Exception) {}
            try { p.release() } catch (e: Exception) {}
        }
    }

    override fun onDestroy() {
        stopPreview()
        super.onDestroy()
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != rcFile) return
        val r = pendingFile
        pendingFile = null
        if (r == null) return
        val src = data?.data
        if (resultCode != Activity.RESULT_OK || src == null) { r.success(null); return }
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

    // ملف من مدير الملفات: بننسخه لمجلد المنبهات عشان نظام الإشعارات يقدر يقرأه (أندرويد 10+)
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
