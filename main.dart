import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// الألوان مأخوذة من جدول الـ PDF نفسه
const Color kLecture = Color(0xFFE4DFEC); // المحاضرات (بنفسجي فاتح)
const Color kSection = Color(0xFFD9EAD3); // السكاشن (أخضر فاتح)
const Color kNavy = Color(0xFF203864); // شريط العنوان
const Color kDay = Color(0xFF44546A); // عمود اليوم

class Item {
  final int day; // نفس ترقيم ديارت: الاثنين 1 ... السبت 6، الأحد 7
  final int sh, sm, eh, em;
  final String course, person, room;
  final bool lecture;
  const Item(this.day, this.sh, this.sm, this.eh, this.em, this.course,
      this.person, this.room, this.lecture);
}

// مواعيد C4 فقط (الوقت بنظام 24 ساعة)
const List<Item> items = [
  // السبت
  Item(6, 11, 0, 13, 0, 'Computer Fundamentals', 'م. مورا', 'AI111', false),
  Item(6, 13, 0, 15, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
  Item(6, 15, 0, 16, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
  Item(6, 16, 0, 17, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
  // الأحد
  Item(7, 13, 0, 15, 0, 'English', 'د. منة', 'AI101', true),
  Item(7, 15, 0, 17, 0, 'Pure Math', 'د. معتز', 'AI101', true),
  // الاثنين
  Item(1, 9, 0, 11, 0, 'Math 0', 'م. مورا', 'AI304', false),
  Item(1, 11, 0, 13, 0, 'Electronics I', 'د. علاء فرح', 'AI101', true),
  // الثلاثاء
  Item(2, 11, 0, 13, 0, 'Electronics I', 'م. هبة ممدوح', 'B303', false),
  Item(2, 13, 0, 15, 0, 'Math 0', 'د. باسم', 'AI101', true),
  Item(2, 15, 0, 17, 0, 'Pure Math', 'م. مونيكا', 'AI110', false),
];

const List<int> dayOrder = [6, 7, 1, 2];
const Map<int, String> dayNames = {
  6: 'السبت',
  7: 'الأحد',
  1: 'الاثنين',
  2: 'الثلاثاء',
};

// ---------------- الإعدادات ----------------
class AppSettings {
  static String? soundUri; // null = الصوت الافتراضي
  static String soundTitle = 'الافتراضي';
  static bool use24 = false;
  static int chan = 0; // رقم قناة الإشعارات (بيتغير لما الصوت يتغير)

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    soundUri = p.getString('soundUri');
    soundTitle = p.getString('soundTitle') ?? 'الافتراضي';
    use24 = p.getBool('use24') ?? false;
    chan = p.getInt('chan') ?? 0;
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    if (soundUri == null) {
      await p.remove('soundUri');
    } else {
      await p.setString('soundUri', soundUri!);
    }
    await p.setString('soundTitle', soundTitle);
    await p.setBool('use24', use24);
    await p.setInt('chan', chan);
  }
}

String fmt(int h, int m) {
  final mm = m.toString().padLeft(2, '0');
  if (AppSettings.use24) {
    return '${h.toString().padLeft(2, '0')}:$mm';
  }
  final h12 = (h % 12 == 0) ? 12 : h % 12;
  final suffix = h < 12 ? 'ص' : 'م';
  return '$h12:$mm $suffix';
}

// ---------------- الإشعارات والمنبهات ----------------
final FlutterLocalNotificationsPlugin plugin =
    FlutterLocalNotificationsPlugin();

AndroidFlutterLocalNotificationsPlugin? androidImpl() => plugin
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

String channelId() => 'c4_alarm_${AppSettings.chan}';

Future<void> initNotifications() async {
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
  const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'));
  await plugin.initialize(init);
}

Future<void> askPermissions() async {
  final a = androidImpl();
  await a?.requestNotificationsPermission();
  await a?.requestExactAlarmsPermission();
}

AndroidNotificationSound? currentSound() => AppSettings.soundUri == null
    ? null
    : UriAndroidNotificationSound(AppSettings.soundUri!);

NotificationDetails buildDetails(String body) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      channelId(),
      'تنبيهات المحاضرات',
      channelDescription: 'منبه قبل المحاضرة أو السكشن بخمس دقايق',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      sound: currentSound(),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      additionalFlags: Int32List.fromList(<int>[4]), // الصوت يتكرر لحد ما تقفله
      timeoutAfter: 60000,
      autoCancel: true,
      styleInformation: BigTextStyleInformation(body),
    ),
  );
}

tz.TZDateTime nextTime(Item it) {
  final now = tz.TZDateTime.now(tz.local);
  final total = it.sh * 60 + it.sm - 5; // قبل البداية بخمس دقايق
  final hh = total ~/ 60, mm = total % 60;
  var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, hh, mm);
  while (d.weekday != it.day || !d.isAfter(now)) {
    d = tz.TZDateTime(tz.local, d.year, d.month, d.day + 1, hh, mm);
  }
  return d;
}

Future<void> scheduleAll() async {
  await plugin.cancelAll();
  await androidImpl()?.createNotificationChannel(AndroidNotificationChannel(
    channelId(),
    'تنبيهات المحاضرات',
    description: 'منبه قبل المحاضرة أو السكشن بخمس دقايق',
    importance: Importance.max,
    playSound: true,
    sound: currentSound(),
    enableVibration: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  ));
  for (var i = 0; i < items.length; i++) {
    final it = items[i];
    final kind = it.lecture ? 'محاضرة' : 'سكشن';
    final title = '$kind ${it.course} بعد 5 دقايق';
    final body = '${it.person} • القاعة ${it.room} • ${fmt(it.sh, it.sm)}';
    final when = nextTime(it);
    Future<void> go(AndroidScheduleMode mode) => plugin.zonedSchedule(
          i,
          title,
          body,
          when,
          buildDetails(body),
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
    try {
      await go(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      await go(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }
}

Future<void> testNotification() async {
  const body = 'د. نبيل • القاعة AI101 • 1:00 م';
  await plugin.show(
      999, 'تجربة: محاضرة بعد 5 دقايق', body, buildDetails(body));
}

// ---------------- الواجهة ----------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  await initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'جدول C4',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: kNavy),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await askPermissions();
    await scheduleAll();
  }

  Widget _card(Item it) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: it.lecture ? kLecture : kSection,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fmt(it.sh, it.sm),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text(fmt(it.eh, it.em),
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.course,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${it.lecture ? 'محاضرة' : 'سكشن'} • ${it.person}',
                    style: const TextStyle(fontSize: 14)),
                Text('القاعة: ${it.room}',
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final d in dayOrder) {
      children.add(Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14, left: 12, right: 12, bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
            color: kDay, borderRadius: BorderRadius.circular(8)),
        child: Text(dayNames[d]!,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ));
      for (final it in items.where((e) => e.day == d)) {
        children.add(_card(it));
      }
    }
    children.add(const SizedBox(height: 24));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
        title: const Text('جدول C4'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()));
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(children: children),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const MethodChannel _ch = MethodChannel('c4/sound');

  Future<void> _pickSound() async {
    try {
      final r = await _ch.invokeMethod<Map>('pick', {
        'current': AppSettings.soundUri,
      });
      if (r == null) return;
      AppSettings.soundUri = r['uri'] as String?;
      AppSettings.soundTitle = (r['title'] as String?) ?? 'الافتراضي';
      AppSettings.chan += 1; // قناة جديدة عشان الصوت الجديد يتطبق
      await AppSettings.save();
      await scheduleAll();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _setClock(bool v) async {
    AppSettings.use24 = v;
    await AppSettings.save();
    await scheduleAll(); // الوقت جوه نص الإشعار بيتحدث
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('صوت المنبه'),
            subtitle: Text(AppSettings.soundTitle),
            trailing: const Icon(Icons.chevron_left),
            onTap: _pickSound,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('تجربة المنبه دلوقتي'),
            onTap: () async {
              await askPermissions();
              await testNotification();
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('نظام الساعة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('12 ساعة')),
                ButtonSegment(value: true, label: Text('24 ساعة')),
              ],
              selected: {AppSettings.use24},
              onSelectionChanged: (s) => _setClock(s.first),
            ),
          ),
        ],
      ),
    );
  }
}
