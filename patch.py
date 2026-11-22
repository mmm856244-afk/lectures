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
s = s.replace('android:label="c4_schedule"', 'android:label="جدول C4"')
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
print('patched')
