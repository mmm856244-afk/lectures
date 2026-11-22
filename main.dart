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

// جدول المستوى الأول كامل: 16 جروب (الوقت بنظام 24 ساعة)
// الجروبات: A1..A4 / B1..B4 / C1..C4 / D1..D4
const Map<String, List<Item>> allSchedules = {
  'A1': [
    Item(6, 9, 0, 11, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(6, 11, 0, 12, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 12, 0, 13, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 13, 0, 15, 0, 'Math 0', 'م. فاطمة', 'AI413', false),
    Item(7, 9, 0, 11, 0, 'Computer Fundamentals', 'م. آلاء حمادة', 'AI107', false),
    Item(1, 9, 0, 11, 0, 'English', 'د. منة', 'AI101', true),
    Item(1, 11, 0, 13, 0, 'Pure Math', 'م. خالد', 'AI303', false),
    Item(1, 13, 0, 15, 0, 'Electronics I', 'د. علاء فرح', 'AI102', true),
    Item(2, 9, 0, 11, 0, 'Math 0', 'د. باسم', 'AI101', true),
    Item(2, 11, 0, 13, 0, 'Pure Math', 'د. معتز', 'AI101', true),
    Item(2, 15, 0, 17, 0, 'Electronics I', 'م. هبة ممدوح', 'AI303', false),
  ],
  'A2': [
    Item(6, 9, 0, 11, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(6, 11, 0, 12, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 12, 0, 13, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 15, 0, 17, 0, 'Computer Fundamentals', 'م. سارة حيدر', 'AI111', false),
    Item(7, 9, 0, 11, 0, 'Pure Math', 'م. هالة', 'AI207', false),
    Item(7, 11, 0, 13, 0, 'Electronics I', 'م. محمد حسام', 'AI110', false),
    Item(1, 9, 0, 11, 0, 'English', 'د. منة', 'AI101', true),
    Item(1, 13, 0, 15, 0, 'Electronics I', 'د. علاء فرح', 'AI102', true),
    Item(2, 9, 0, 11, 0, 'Math 0', 'د. باسم', 'AI101', true),
    Item(2, 11, 0, 13, 0, 'Pure Math', 'د. معتز', 'AI101', true),
    Item(2, 13, 0, 15, 0, 'Math 0', 'م. أحمد', 'AI110', false),
  ],
  'A3': [
    Item(6, 9, 0, 11, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(6, 11, 0, 12, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 12, 0, 13, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 13, 0, 15, 0, 'Math 0', 'م. أحمد', 'AI207', false),
    Item(7, 9, 0, 11, 0, 'Pure Math', 'م. خالد', 'AI205', false),
    Item(7, 11, 0, 13, 0, 'Computer Fundamentals', 'م. مورا', 'AI112', false),
    Item(7, 13, 0, 15, 0, 'Electronics I', 'م. إنجي', 'AI413', false),
    Item(1, 9, 0, 11, 0, 'English', 'د. منة', 'AI101', true),
    Item(1, 13, 0, 15, 0, 'Electronics I', 'د. علاء فرح', 'AI102', true),
    Item(2, 9, 0, 11, 0, 'Math 0', 'د. باسم', 'AI101', true),
    Item(2, 11, 0, 13, 0, 'Pure Math', 'د. معتز', 'AI101', true),
  ],
  'A4': [
    Item(6, 9, 0, 11, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(6, 11, 0, 12, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 12, 0, 13, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(7, 9, 0, 11, 0, 'Computer Fundamentals', 'م. شهد محمد', 'AI302', false),
    Item(7, 13, 0, 15, 0, 'Electronics I', 'م. وفاء', 'AI304', false),
    Item(1, 9, 0, 11, 0, 'English', 'د. منة', 'AI101', true),
    Item(1, 11, 0, 13, 0, 'Math 0', 'م. فاطمة', 'B303', false),
    Item(1, 13, 0, 15, 0, 'Electronics I', 'د. علاء فرح', 'AI102', true),
    Item(2, 9, 0, 11, 0, 'Math 0', 'د. باسم', 'AI101', true),
    Item(2, 11, 0, 13, 0, 'Pure Math', 'د. معتز', 'AI101', true),
    Item(2, 13, 0, 15, 0, 'Pure Math', 'م. هالة', 'AI413', false),
  ],
  'B1': [
    Item(6, 9, 0, 10, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 10, 0, 11, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 11, 0, 13, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(7, 9, 0, 11, 0, 'Math 0', 'م. فاطمة', 'AI110', false),
    Item(7, 11, 0, 13, 0, 'English', 'د. منة', 'AI101', true),
    Item(7, 13, 0, 15, 0, 'Pure Math', 'م. شهد إبراهيم', 'AI205', false),
    Item(1, 9, 0, 11, 0, 'Computer Fundamentals', 'م. آلاء حمادة', 'AI107', false),
    Item(1, 11, 0, 13, 0, 'Electronics I', 'م. محمد حسام', 'AI110', false),
    Item(1, 15, 0, 17, 0, 'Electronics I', 'د. علاء فرح', 'AI101', true),
    Item(2, 9, 0, 11, 0, 'Pure Math', 'د. معتز', 'AI102', true),
    Item(2, 11, 0, 13, 0, 'Math 0', 'د. باسم', 'AI102', true),
  ],
  'B2': [
    Item(6, 9, 0, 10, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 10, 0, 11, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 11, 0, 13, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(7, 9, 0, 11, 0, 'Math 0', 'م. وفاء', 'AI304', false),
    Item(7, 11, 0, 13, 0, 'English', 'د. منة', 'AI101', true),
    Item(7, 15, 0, 17, 0, 'Electronics I', 'م. وفاء', 'AI304', false),
    Item(1, 9, 0, 11, 0, 'Computer Fundamentals', 'م. سارة حيدر', 'AI111', false),
    Item(1, 11, 0, 13, 0, 'Pure Math', 'م. مونيكا', 'B304', false),
    Item(1, 15, 0, 17, 0, 'Electronics I', 'د. علاء فرح', 'AI101', true),
    Item(2, 9, 0, 11, 0, 'Pure Math', 'د. معتز', 'AI102', true),
    Item(2, 11, 0, 13, 0, 'Math 0', 'د. باسم', 'AI102', true),
  ],
  'B3': [
    Item(6, 9, 0, 10, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 10, 0, 11, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 11, 0, 13, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(6, 13, 0, 15, 0, 'Electronics I', 'م. شهد محمد', 'AI110', false),
    Item(7, 9, 0, 11, 0, 'Computer Fundamentals', 'م. مورا', 'AI112', false),
    Item(7, 11, 0, 13, 0, 'English', 'د. منة', 'AI101', true),
    Item(7, 13, 0, 15, 0, 'Math 0', 'م. رنا', 'AI110', false),
    Item(1, 9, 0, 11, 0, 'Pure Math', 'م. هالة', 'AI207', false),
    Item(1, 15, 0, 17, 0, 'Electronics I', 'د. علاء فرح', 'AI101', true),
    Item(2, 9, 0, 11, 0, 'Pure Math', 'د. معتز', 'AI102', true),
    Item(2, 11, 0, 13, 0, 'Math 0', 'د. باسم', 'AI102', true),
  ],
  'B4': [
    Item(6, 9, 0, 10, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 10, 0, 11, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 11, 0, 13, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(6, 13, 0, 15, 0, 'Pure Math', 'م. مونيكا', 'AI205', false),
    Item(7, 9, 0, 11, 0, 'Computer Fundamentals', 'م. سارة حيدر', 'AI111', false),
    Item(7, 11, 0, 13, 0, 'English', 'د. منة', 'AI101', true),
    Item(1, 9, 0, 11, 0, 'Math 0', 'م. أحمد', 'AI205', false),
    Item(1, 13, 0, 15, 0, 'Electronics I', 'م. محمد حسام', 'AI207', false),
    Item(1, 15, 0, 17, 0, 'Electronics I', 'د. علاء فرح', 'AI101', true),
    Item(2, 9, 0, 11, 0, 'Pure Math', 'د. معتز', 'AI102', true),
    Item(2, 11, 0, 13, 0, 'Math 0', 'د. باسم', 'AI102', true),
  ],
  'C1': [
    Item(6, 11, 0, 13, 0, 'Computer Fundamentals', 'م. آلاء حمادة', 'AI107', false),
    Item(6, 13, 0, 15, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(6, 15, 0, 16, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 16, 0, 17, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(7, 11, 0, 13, 0, 'Electronics I', 'م. إنجي', 'AI413', false),
    Item(7, 13, 0, 15, 0, 'English', 'د. منة', 'AI101', true),
    Item(7, 15, 0, 17, 0, 'Pure Math', 'د. معتز', 'AI101', true),
    Item(1, 9, 0, 11, 0, 'Math 0', 'م. رنا', 'AI110', false),
    Item(1, 11, 0, 13, 0, 'Electronics I', 'د. علاء فرح', 'AI101', true),
    Item(2, 13, 0, 15, 0, 'Math 0', 'د. باسم', 'AI101', true),
    Item(2, 15, 0, 17, 0, 'Pure Math', 'م. هالة', 'AI413', false),
  ],
  'C2': [
    Item(6, 11, 0, 13, 0, 'Electronics I', 'م. وفاء', 'AI304', false),
    Item(6, 13, 0, 15, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(6, 15, 0, 16, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 16, 0, 17, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(7, 11, 0, 13, 0, 'Pure Math', 'م. شهد إبراهيم', 'AI205', false),
    Item(7, 13, 0, 15, 0, 'English', 'د. منة', 'AI101', true),
    Item(7, 15, 0, 17, 0, 'Pure Math', 'د. معتز', 'AI101', true),
    Item(1, 9, 0, 11, 0, 'Computer Fundamentals', 'م. شهد محمد', 'AI112', false),
    Item(1, 11, 0, 13, 0, 'Electronics I', 'د. علاء فرح', 'AI101', true),
    Item(2, 13, 0, 15, 0, 'Math 0', 'د. باسم', 'AI101', true),
    Item(2, 15, 0, 17, 0, 'Math 0', 'م. وفاء', 'AI304', false),
  ],
  'C3': [
    Item(6, 13, 0, 15, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(6, 15, 0, 16, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 16, 0, 17, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(7, 13, 0, 15, 0, 'English', 'د. منة', 'AI101', true),
    Item(7, 15, 0, 17, 0, 'Pure Math', 'د. معتز', 'AI101', true),
    Item(1, 9, 0, 11, 0, 'Computer Fundamentals', 'م. منار', 'AI305', false),
    Item(1, 11, 0, 13, 0, 'Electronics I', 'د. علاء فرح', 'AI101', true),
    Item(1, 13, 0, 15, 0, 'Pure Math', 'م. شهد إبراهيم', 'AI205', false),
    Item(2, 11, 0, 13, 0, 'Math 0', 'م. وفاء', 'AI304', false),
    Item(2, 13, 0, 15, 0, 'Math 0', 'د. باسم', 'AI101', true),
    Item(2, 15, 0, 17, 0, 'Electronics I', 'م. شهد محمد', 'AI207', false),
  ],
  'C4': [
    Item(6, 11, 0, 13, 0, 'Computer Fundamentals', 'م. مورا', 'AI111', false),
    Item(6, 13, 0, 15, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(6, 15, 0, 16, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 16, 0, 17, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(7, 13, 0, 15, 0, 'English', 'د. منة', 'AI101', true),
    Item(7, 15, 0, 17, 0, 'Pure Math', 'د. معتز', 'AI101', true),
    Item(1, 9, 0, 11, 0, 'Math 0', 'م. مورا', 'AI304', false),
    Item(1, 11, 0, 13, 0, 'Electronics I', 'د. علاء فرح', 'AI101', true),
    Item(2, 11, 0, 13, 0, 'Electronics I', 'م. هبة ممدوح', 'B303', false),
    Item(2, 13, 0, 15, 0, 'Math 0', 'د. باسم', 'AI101', true),
    Item(2, 15, 0, 17, 0, 'Pure Math', 'م. مونيكا', 'AI110', false),
  ],
  'D1': [
    Item(6, 13, 0, 14, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 14, 0, 15, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 15, 0, 17, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(7, 9, 0, 11, 0, 'English', 'د. منة', 'AI101', true),
    Item(7, 13, 0, 15, 0, 'Computer Fundamentals', 'م. آلاء حمادة', 'AI107', false),
    Item(7, 15, 0, 17, 0, 'Electronics I', 'م. شهد محمد', 'AI110', false),
    Item(1, 9, 0, 11, 0, 'Electronics I', 'د. علاء فرح', 'AI102', true),
    Item(1, 11, 0, 13, 0, 'Pure Math', 'د. معتز', 'AI102', true),
    Item(1, 13, 0, 15, 0, 'Pure Math', 'م. خالد', 'B304', false),
    Item(2, 13, 0, 15, 0, 'Math 0', 'م. وفاء', 'AI304', false),
    Item(2, 15, 0, 17, 0, 'Math 0', 'د. باسم', 'AI101', true),
  ],
  'D2': [
    Item(6, 11, 0, 13, 0, 'Pure Math', 'م. شهد إبراهيم', 'AI205', false),
    Item(6, 13, 0, 14, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 14, 0, 15, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 15, 0, 17, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(7, 9, 0, 11, 0, 'English', 'د. منة', 'AI101', true),
    Item(7, 13, 0, 15, 0, 'Computer Fundamentals', 'م. سارة حيدر', 'AI111', false),
    Item(7, 15, 0, 17, 0, 'Math 0', 'م. فاطمة', 'AI207', false),
    Item(1, 9, 0, 11, 0, 'Electronics I', 'د. علاء فرح', 'AI102', true),
    Item(1, 11, 0, 13, 0, 'Pure Math', 'د. معتز', 'AI102', true),
    Item(2, 13, 0, 15, 0, 'Electronics I', 'م. هبة ممدوح', 'AI303', false),
    Item(2, 15, 0, 17, 0, 'Math 0', 'د. باسم', 'AI101', true),
  ],
  'D3': [
    Item(6, 9, 0, 11, 0, 'Computer Fundamentals', 'م. آلاء حمادة', 'AI107', false),
    Item(6, 13, 0, 14, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 14, 0, 15, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 15, 0, 17, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(7, 9, 0, 11, 0, 'English', 'د. منة', 'AI101', true),
    Item(7, 11, 0, 13, 0, 'Pure Math', 'م. هالة', 'AI207', false),
    Item(7, 15, 0, 17, 0, 'Electronics I', 'م. شهد إبراهيم', 'AI205', false),
    Item(1, 9, 0, 11, 0, 'Electronics I', 'د. علاء فرح', 'AI102', true),
    Item(1, 11, 0, 13, 0, 'Pure Math', 'د. معتز', 'AI102', true),
    Item(1, 13, 0, 15, 0, 'Math 0', 'م. أحمد', 'AI303', false),
    Item(2, 15, 0, 17, 0, 'Math 0', 'د. باسم', 'AI101', true),
  ],
  'D4': [
    Item(6, 11, 0, 13, 0, 'Math 0', 'م. أحمد', 'AI207', false),
    Item(6, 13, 0, 14, 0, 'Information Technology', 'د. لؤى', 'AI102', true),
    Item(6, 14, 0, 15, 0, 'Problem Solving', 'د. ظافر', 'AI102', true),
    Item(6, 15, 0, 17, 0, 'Computer Fundamentals', 'د. نبيل', 'AI101', true),
    Item(7, 9, 0, 11, 0, 'English', 'د. منة', 'AI101', true),
    Item(7, 11, 0, 13, 0, 'Electronics I', 'م. هبة ممدوح', 'B303', false),
    Item(7, 15, 0, 17, 0, 'Computer Fundamentals', 'م. مورا', 'AI112', false),
    Item(1, 9, 0, 11, 0, 'Electronics I', 'د. علاء فرح', 'AI102', true),
    Item(1, 11, 0, 13, 0, 'Pure Math', 'د. معتز', 'AI102', true),
    Item(1, 13, 0, 15, 0, 'Pure Math', 'م. مونيكا', 'AI110', false),
    Item(2, 15, 0, 17, 0, 'Math 0', 'د. باسم', 'AI101', true),
  ],
};

const List<String> groupLetters = ['A', 'B', 'C', 'D'];

// الأيام بالترتيب اللي في الجدول
const List<int> dayOrder = [6, 7, 1, 2];
const Map<int, String> dayNames = {
  6: 'السبت',
  7: 'الأحد',
  1: 'الاثنين',
  2: 'الثلاثاء',
};

// ---------------- الإعدادات ----------------
class AppSettings {
  static String? group; // null = لسه ما اخترتش جروب
  static String? soundUri; // null = الصوت الافتراضي
  static String soundTitle = 'الافتراضي';
  static bool vibrate = true;
  static bool use24 = false;
  static int chan = 0; // رقم قناة الإشعارات (بيتغير لما الصوت أو الاهتزاز يتغير)

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    group = p.getString('group');
    soundUri = p.getString('soundUri');
    soundTitle = p.getString('soundTitle') ?? 'الافتراضي';
    vibrate = p.getBool('vibrate') ?? true;
    use24 = p.getBool('use24') ?? false;
    chan = p.getInt('chan') ?? 0;
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    if (group == null) {
      await p.remove('group');
    } else {
      await p.setString('group', group!);
    }
    if (soundUri == null) {
      await p.remove('soundUri');
    } else {
      await p.setString('soundUri', soundUri!);
    }
    await p.setString('soundTitle', soundTitle);
    await p.setBool('vibrate', vibrate);
    await p.setBool('use24', use24);
    await p.setInt('chan', chan);
  }
}

// مواعيد الجروب اللي المستخدم اختاره
List<Item> get items => allSchedules[AppSettings.group] ?? const <Item>[];

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

String channelId() => 'bua_alarm_${AppSettings.chan}';

Int64List vibrationPattern() =>
    Int64List.fromList(<int>[0, 900, 450, 900, 450, 900, 450, 900]);

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
      enableVibration: AppSettings.vibrate,
      vibrationPattern: AppSettings.vibrate ? vibrationPattern() : null,
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

// بنرتب عمليات ضبط المنبهات ورا بعض عشان ما تتخانقش مع بعض
Future<void> _lastSchedule = Future<void>.value();
Future<void> scheduleAll() {
  _lastSchedule =
      _lastSchedule.catchError((_) {}).then((_) => _scheduleAllNow());
  return _lastSchedule;
}

Future<void> _scheduleAllNow() async {
  await plugin.cancelAll();
  await androidImpl()?.createNotificationChannel(AndroidNotificationChannel(
    channelId(),
    'تنبيهات المحاضرات',
    description: 'منبه قبل المحاضرة أو السكشن بخمس دقايق',
    importance: Importance.max,
    playSound: true,
    sound: currentSound(),
    enableVibration: AppSettings.vibrate,
    vibrationPattern: AppSettings.vibrate ? vibrationPattern() : null,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  ));
  final list = items;
  for (var i = 0; i < list.length; i++) {
    final it = list[i];
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
  final list = items;
  final it = list.isNotEmpty ? list.first : null;
  final body = it == null
      ? 'د. نبيل • القاعة AI101 • 9:00 ص'
      : '${it.person} • القاعة ${it.room} • ${fmt(it.sh, it.sm)}';
  final title = it == null
      ? 'تجربة: محاضرة بعد 5 دقايق'
      : 'تجربة: ${it.course} بعد 5 دقايق';
  await plugin.show(999, title, body, buildDetails(body));
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
      title: 'جدول BUA',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: kNavy),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: AppSettings.group == null
          ? const GroupPickerPage(first: true)
          : const HomePage(),
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

Widget pageHeader(BuildContext context, String title) {
  final top = MediaQuery.of(context).padding.top;
  return Container(
    height: 80 + top,
    padding: EdgeInsets.fromLTRB(12, top, 12, 0),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [kNavyDark, kNavy]),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: Row(
      children: [
        if (Navigator.of(context).canPop())
          const BackButton(color: Colors.white)
        else
          const SizedBox(width: 12),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

// ---------------- اختيار الجروب ----------------
class GroupPickerPage extends StatefulWidget {
  final bool first;
  const GroupPickerPage({super.key, this.first = false});
  @override
  State<GroupPickerPage> createState() => _GroupPickerPageState();
}

class _GroupPickerPageState extends State<GroupPickerPage> {
  bool _busy = false;

  Future<void> _choose(String g) async {
    if (_busy) return;
    _busy = true;
    setState(() => AppSettings.group = g); // العلامة الزرقاء تظهر فورًا
    await AppSettings.save();
    // ضبط الصلاحيات والمنبهات في الخلفية من غير ما نعلّق الشاشة
    askPermissions().then((_) => scheduleAll());
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    if (widget.first) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      Navigator.of(context).pop(true);
    }
  }

  Widget _chip(String g) {
    final sel = AppSettings.group == g;
    return Expanded(
      child: GestureDetector(
        onTap: () => _choose(g),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: sel
                ? const LinearGradient(colors: [kNavyDark, kNavy])
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFE4EBF8)]),
            boxShadow: [
              BoxShadow(
                  color: kNavy.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Text(g,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: sel ? Colors.white : kNavyDark)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: kPageBg,
        child: Column(
          children: [
            pageHeader(context, 'اختار جروبك'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 18, 12, 24),
                children: [
                  for (final l in groupLetters) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                      child: Text('مجموعة $l',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: kNavy)),
                    ),
                    Row(children: [for (var i = 1; i <= 4; i++) _chip('$l$i')]),
                    const SizedBox(height: 14),
                  ],
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                        'المنبه هيرن قبل كل محاضرة أو سكشن في جروبك بخمس دقايق. تقدر تغيّر الجروب في أي وقت.',
                        style: TextStyle(color: Colors.black54)),
                  ),
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

  Future<void> _changeGroup() async {
    final r = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const GroupPickerPage()));
    if (r == true) setState(() {});
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('جدول BUA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    )),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _changeGroup,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: kNavyDark.withOpacity(0.75),
                      border: Border.all(
                          color: const Color(0xFF3E6BFF), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('الجروب: ${AppSettings.group}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        const Icon(Icons.expand_more,
                            color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
    final list = items;
    for (final d in dayOrder) {
      final dayItems = list.where((e) => e.day == d).toList();
      if (dayItems.isEmpty) continue;
      children.add(_dayBar(dayNames[d]!));
      for (final it in dayItems) {
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

// ---------------- اختيار نغمة المنبه (شاشة واحدة) ----------------
class SoundPickerPage extends StatefulWidget {
  const SoundPickerPage({super.key});
  @override
  State<SoundPickerPage> createState() => _SoundPickerPageState();
}

class _SoundPickerPageState extends State<SoundPickerPage> {
  static const MethodChannel _ch = MethodChannel('bua/sound');
  List<Map<String, String>> tones = [];
  List<Map<String, String>> music = [];
  bool loading = true;
  bool musicAllowed = true;
  bool _busy = false;
  String? playing; // الصوت اللي بيتسمع كمعاينة
  String query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ch.invokeMethod('stopPreview').catchError((_) {});
    super.dispose();
  }

  List<Map<String, String>> _conv(dynamic l) => ((l as List?) ?? const [])
      .map((e) => Map<String, String>.from(e as Map))
      .toList();

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final r = await _ch.invokeMethod<Map>('listSounds');
      if (!mounted) return;
      setState(() {
        tones = _conv(r?['tones']);
        music = _conv(r?['music']);
        musicAllowed = (r?['musicAllowed'] as bool?) ?? false;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  // الاختيار بيتفعل على طول وبترجع للإعدادات
  Future<void> _select(String? uri, String title) async {
    if (_busy) return;
    _busy = true;
    _ch.invokeMethod('stopPreview').catchError((_) {});
    setState(() {
      AppSettings.soundUri = uri;
      AppSettings.soundTitle = title;
      AppSettings.chan += 1; // قناة جديدة عشان الصوت الجديد يتطبق
      playing = null;
    });
    await AppSettings.save();
    scheduleAll();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _preview(String uri) async {
    if (playing == uri) {
      _ch.invokeMethod('stopPreview').catchError((_) {});
      setState(() => playing = null);
      return;
    }
    setState(() => playing = uri);
    try {
      await _ch.invokeMethod('preview', {'uri': uri});
    } catch (_) {
      if (mounted) setState(() => playing = null);
      return;
    }
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && playing == uri) setState(() => playing = null);
    });
  }

  Future<void> _pickFile() async {
    try {
      final r = await _ch.invokeMethod<Map>('pickFile');
      if (r == null) return;
      await _select(r['uri'] as String?, (r['title'] as String?) ?? 'صوت مخصص');
    } catch (_) {}
  }

  Widget _row(String? uri, String title,
      {String sub = '', required IconData icon}) {
    final sel = AppSettings.soundUri == uri;
    return GestureDetector(
      onTap: () => _select(uri, title),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: sel
              ? const LinearGradient(colors: [kNavyDark, kNavy])
              : const LinearGradient(
                  colors: [Colors.white, Color(0xFFE4EBF8)]),
          boxShadow: [
            BoxShadow(
                color: kNavy.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: sel ? Colors.white24 : kLecture,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: sel ? Colors.white : kNavy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: sel ? Colors.white : kNavyDark)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: sel ? Colors.white70 : Colors.black54)),
                ],
              ),
            ),
            if (uri != null)
              IconButton(
                onPressed: () => _preview(uri),
                icon: Icon(
                    playing == uri
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline,
                    size: 30,
                    color: sel ? Colors.white : kNavy),
              ),
            if (sel) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
      );

  bool _match(Map<String, String> e) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return (e['title'] ?? '').toLowerCase().contains(q) ||
        (e['artist'] ?? '').toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (query.isEmpty) {
      rows.add(_row(null, 'الافتراضي', icon: Icons.notifications));
    }
    final t = tones.where(_match).toList();
    final m = music.where(_match).toList();
    if (t.isNotEmpty) {
      rows.add(_label('نغمات الموبايل'));
      for (final e in t) {
        rows.add(_row(e['uri'], e['title'] ?? 'نغمة', icon: Icons.music_note));
      }
    }
    if (m.isNotEmpty) {
      rows.add(_label('الأغاني اللي على الموبايل'));
      for (final e in m) {
        rows.add(_row(e['uri'], e['title'] ?? '',
            sub: e['artist'] ?? '', icon: Icons.library_music));
      }
    }
    if (!musicAllowed) {
      rows.add(_label('الأغاني'));
      rows.add(Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'عشان تظهر الأغاني لازم تسمح للتطبيق يوصل للصوتيات. لو الطلب مش بيظهر، افتح إعدادات التطبيق من الموبايل واسمح بالوصول للموسيقى والصوتيات.'),
            const SizedBox(height: 8),
            FilledButton(onPressed: _load, child: const Text('السماح بالأغاني')),
          ],
        ),
      ));
    }
    if (query.isEmpty && !loading) {
      rows.add(_label('مش لاقي أغنيتك؟'));
      rows.add(GestureDetector(
        onTap: _pickFile,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Row(children: const [
            Icon(Icons.folder_open, color: kNavy),
            SizedBox(width: 12),
            Text('دوّر في الملفات', style: TextStyle(fontSize: 16)),
          ]),
        ),
      ));
    }
    rows.add(const SizedBox(height: 20));

    return Scaffold(
      body: Container(
        decoration: kPageBg,
        child: Column(
          children: [
            pageHeader(context, 'نغمة المنبه'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'ابحث عن نغمة أو أغنية',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4),
                      itemCount: rows.length,
                      itemBuilder: (_, i) => rows[i],
                    ),
            ),
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
  Future<void> _openSounds() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SoundPickerPage()));
    if (mounted) setState(() {});
  }

  Future<void> _setVibrate(bool v) async {
    setState(() {
      AppSettings.vibrate = v;
      AppSettings.chan += 1; // الاهتزاز بيتحدد في القناة، فلازم قناة جديدة
    });
    await AppSettings.save();
    scheduleAll();
  }

  Future<void> _setClock(bool v) async {
    setState(() => AppSettings.use24 = v);
    await AppSettings.save();
    scheduleAll(); // الوقت جوه نص الإشعار بيتحدث
  }

  Future<void> _changeGroup() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const GroupPickerPage()));
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
    return Scaffold(
      body: Container(
        decoration: kPageBg,
        child: Column(
          children: [
            pageHeader(context, 'الإعدادات'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12),
                children: [
                  _box(ListTile(
                    leading: const Icon(Icons.groups, color: kNavy),
                    title: const Text('الجروب'),
                    subtitle: Text(AppSettings.group ?? '-'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: _changeGroup,
                  )),
                  _box(ListTile(
                    leading: const Icon(Icons.music_note, color: kNavy),
                    title: const Text('صوت المنبه'),
                    subtitle: Text(AppSettings.soundTitle),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: _openSounds,
                  )),
                  _box(SwitchListTile(
                    secondary: const Icon(Icons.vibration, color: kNavy),
                    title: const Text('الاهتزاز مع المنبه'),
                    value: AppSettings.vibrate,
                    onChanged: _setVibrate,
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
