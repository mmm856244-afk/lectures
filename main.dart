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
const Color kNavy = Color(0xFF0B2A6F); // الأزرق الكحلي
const Color kNavyDark = Color(0xFF06133F); // الكحلي الغامق

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
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: kNavyDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await AppSettings.load();
  await initNotifications();
  runApp(const MyApp());
}

IconData iconFor(Item it) {
  switch (it.course) {
    case 'Computer Fundamentals':
      return it.lecture ? Icons.memory : Icons.code;
    case 'Information Technology':
      return Icons.public;
    case 'Problem Solving':
      return Icons.extension;
    case 'English':
      return Icons.menu_book;
    case 'Pure Math':
      return Icons.calculate;
    case 'Math 0':
      return Icons.functions;
    case 'Electronics I':
      return Icons.electrical_services;
    default:
      return Icons.school;
  }
}

const BoxDecoration kPageBg = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE3EAF9), Color(0xFFF7F9FD)],
  ),
);

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

Widget bottomBar(BuildContext context) {
  final bottom = MediaQuery.of(context).padding.bottom;
  Widget line() => Container(width: 70, height: 1.5, color: Colors.white54);
  return Container(
    height: 58 + bottom,
    padding: EdgeInsets.only(bottom: bottom),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [kNavyDark, kNavy, kNavyDark]),
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        line(),
        const SizedBox(width: 14),
        const Icon(Icons.school, color: Colors.white, size: 30),
        const SizedBox(width: 14),
        line(),
      ],
    ),
  );
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

  Widget _header(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    const radius = BorderRadius.vertical(bottom: Radius.circular(36));
    return Container(
      height: 150 + top,
      decoration: const BoxDecoration(
        color: kNavyDark,
        borderRadius: radius,
        image: DecorationImage(
          image: AssetImage('assets/header.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, top + 8, 20, 10),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kNavyDark.withOpacity(0.35),
              kNavyDark.withOpacity(0.88),
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('جدول C4',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                )),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()));
                setState(() {});
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kNavyDark.withOpacity(0.75),
                  border:
                      Border.all(color: const Color(0xFF3E6BFF), width: 2),
                ),
                child: const Icon(Icons.settings, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayBar(String name) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [kNavyDark, kNavy]),
        boxShadow: [
          BoxShadow(
              color: kNavy.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.white),
          const SizedBox(width: 10),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _card(Item it) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.white, Color(0xFFE4EBF8)],
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: kNavy.withOpacity(0.13),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // الوقت
            SizedBox(
              width: 104,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 20, color: kNavy),
                      const SizedBox(width: 6),
                      Text(fmt(it.sh, it.sm),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: kNavyDark)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 26),
                    child: Text(fmt(it.eh, it.em),
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black45)),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: const Color(0xFFC9D3EA),
            ),
            // البيانات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(it.course,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: kNavyDark)),
                  const SizedBox(height: 4),
                  Text('${it.lecture ? 'محاضرة' : 'سكشن'} • ${it.person}',
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF39425C))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 17, color: kNavy),
                      const SizedBox(width: 4),
                      Text('القاعة: ${it.room}',
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF39425C))),
                    ],
                  ),
                ],
              ),
            ),
            // الأيقونة (لونها حسب الجدول: بنفسجي للمحاضرة وأخضر للسكشن)
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: it.lecture ? kLecture : kSection,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(iconFor(it), size: 32, color: kNavy),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final d in dayOrder) {
      children.add(_dayBar(dayNames[d]!));
      for (final it in items.where((e) => e.day == d)) {
        children.add(_card(it));
      }
    }
    children.add(const SizedBox(height: 20));
    return Scaffold(
      body: Container(
        decoration: kPageBg,
        child: Column(
          children: [
            _header(context),
            Expanded(child: ListView(padding: EdgeInsets.zero, children: children)),
          ],
        ),
      ),
      bottomNavigationBar: bottomBar(context),
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

  Widget _box(Widget child) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.white, Color(0xFFE4EBF8)],
        ),
        boxShadow: [
          BoxShadow(
              color: kNavy.withOpacity(0.13),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Container(
        decoration: kPageBg,
        child: Column(
          children: [
            Container(
              height: 80 + top,
              padding: EdgeInsets.fromLTRB(12, top, 12, 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [kNavyDark, kNavy]),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Row(
                children: const [
                  BackButton(color: Colors.white),
                  SizedBox(width: 6),
                  Text('الإعدادات',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12),
                children: [
                  _box(ListTile(
                    leading: const Icon(Icons.music_note, color: kNavy),
                    title: const Text('صوت المنبه'),
                    subtitle: Text(AppSettings.soundTitle),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: _pickSound,
                  )),
                  _box(ListTile(
                    leading:
                        const Icon(Icons.notifications_active, color: kNavy),
                    title: const Text('تجربة المنبه دلوقتي'),
                    onTap: () async {
                      await askPermissions();
                      await testNotification();
                    },
                  )),
                  _box(Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          Icon(Icons.access_time, color: kNavy),
                          SizedBox(width: 10),
                          Text('نظام الساعة',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                  value: false, label: Text('12 ساعة')),
                              ButtonSegment(
                                  value: true, label: Text('24 ساعة')),
                            ],
                            selected: {AppSettings.use24},
                            onSelectionChanged: (s) => _setClock(s.first),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomBar(context),
    );
  }
}
