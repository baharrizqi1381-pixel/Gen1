
// main.dart
// SoloMission - Solo Leveling inspired daily-mission app (Flutter prototype)
// This is a single-file prototype suitable for building into an APK after adding required packages and setup.
// (Content derived from the prototype previously placed in the canvas.)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// NOTE: For production-ready scheduling you must add timezone (tz) package setup and android_alarm_manager_plus
// This file is intended as the app logic prototype. See README.md for full build steps.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(MyApp());
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (payload) async {
        // When notification is tapped, app will open. Main screen reads saved state.
      },
    );
  }

  // Placeholders. For exact scheduling, integrate 'tz' and schedule with zonedSchedule.
  Future<void> scheduleDailyFiveAM() async {
    // Implementation left to README instructions.
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoloMission',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: IntroScreen(),
    );
  }
}

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _nicknameController = TextEditingController();
  String _chosenLevel = 'easy';
  final List<TextEditingController> _optionalControllers =
      List.generate(5, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('nickname') != null) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainMenuScreen()));
    }
  }

  Future<void> _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', _nicknameController.text.trim());
    await prefs.setString('mandatory_level', _chosenLevel);
    for (int i = 0; i < 5; i++) {
      await prefs.setString('optional_task_$i', _optionalControllers[i].text);
    }
    await prefs.setInt('exp', 0);
    await prefs.setInt('level', 0);
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainMenuScreen()));
  }

  Widget _levelButton(String level, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _chosenLevel == level ? Colors.green : null,
      ),
      onPressed: () => setState(() => _chosenLevel = level),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup SoloMission')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan nickname'),
            const SizedBox(height: 8),
            TextField(controller: _nicknameController, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const Text('Pilih level tugas wajib'),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _levelButton('easy', 'Easy'),
              _levelButton('medium', 'Medium'),
              _levelButton('hard', 'Hard'),
            ]),
            const SizedBox(height: 12),
            _buildMandatoryDetails(),
            const SizedBox(height: 16),
            const Text('Tulis 5 tugas opsionalmu (boleh kosong)'),
            ...List.generate(5, (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: TextField(controller: _optionalControllers[i], decoration: InputDecoration(labelText: 'Tugas opsional ${i+1}', border: OutlineInputBorder())),
            )),
            const SizedBox(height: 12),
            Center(child: ElevatedButton(onPressed: _saveAndContinue, child: const Text('Selesai dan Mulai'))),
          ],
        ),
      ),
    );
  }

  Widget _buildMandatoryDetails() {
    Map<String, List<String>> details = {
      'easy': ['Push up 10×', 'Lari 1 KM', 'Sit up 10×', 'Membaca 10 halaman'],
      'medium': ['Push up 20×', 'Lari 3 KM', 'Sit up 35×', 'Membaca 20 halaman'],
      'hard': ['Push up 30×', 'Lari 5 KM', 'Sit up 50×', 'Membaca 30 halaman'],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detail tugas wajib ($_chosenLevel):'),
        ...details[_chosenLevel]!.map((t) => ListTile(title: Text(t))).toList(),
      ],
    );
  }
}

class MainMenuScreen extends StatefulWidget {
  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  String nickname = '';
  String mandatoryLevel = 'easy';
  List<String> optionalTasks = ['', '', '', '', ''];
  int exp = 0;
  int level = 0;

  Timer? _countdownTimer;
  Duration _timeToFiveAM = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startCountdownToFiveAM();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nickname = prefs.getString('nickname') ?? '';
      mandatoryLevel = prefs.getString('mandatory_level') ?? 'easy';
      for (int i = 0; i < 5; i++) {
        optionalTasks[i] = prefs.getString('optional_task_$i') ?? '';
      }
      exp = prefs.getInt('exp') ?? 0;
      level = prefs.getInt('level') ?? 0;
    });
  }

  void _startCountdownToFiveAM() {
    _updateTimeToFiveAM();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeToFiveAM());
  }

  void _updateTimeToFiveAM() {
    final now = DateTime.now();
    DateTime fiveAM = DateTime(now.year, now.month, now.day, 5, 0);
    if (fiveAM.isBefore(now)) fiveAM = fiveAM.add(const Duration(days: 1));
    setState(() {
      _timeToFiveAM = fiveAM.difference(now);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onStartPressed() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Game akan dimulai pukul 05:00. Alarm akan aktif setiap hari.')));
  }

  Map<String, List<Map<String, dynamic>>> _getDailySchedule() {
    Map<String, List<Map<String, dynamic>>> schedules = {
      'easy': [
        {'time': TimeOfDay(hour: 6, minute: 0), 'label': 'Lari 1 KM', 'mandatory': true},
        {'time': TimeOfDay(hour: 7, minute: 0), 'label': 'Push up 10×', 'mandatory': true},
        {'time': TimeOfDay(hour: 7, minute: 15), 'label': 'Sit up 10×', 'mandatory': true},
        {'time': TimeOfDay(hour: 7, minute: 30), 'label': 'Mandi', 'mandatory': true},
        {'time': TimeOfDay(hour: 8, minute: 0), 'label': 'Membaca buku 10 halaman', 'mandatory': true},
      ],
      'medium': [
        {'time': TimeOfDay(hour: 6, minute: 0), 'label': 'Lari 3 KM', 'mandatory': true},
        {'time': TimeOfDay(hour: 7, minute: 0), 'label': 'Push up 20×', 'mandatory': true},
        {'time': TimeOfDay(hour: 7, minute: 15), 'label': 'Sit up 35×', 'mandatory': true},
        {'time': TimeOfDay(hour: 7, minute: 30), 'label': 'Mandi', 'mandatory': true},
        {'time': TimeOfDay(hour: 8, minute: 0), 'label': 'Membaca buku 20 halaman', 'mandatory': true},
      ],
      'hard': [
        {'time': TimeOfDay(hour: 6, minute: 0), 'label': 'Lari 5 KM', 'mandatory': true},
        {'time': TimeOfDay(hour: 7, minute: 0), 'label': 'Push up 30×', 'mandatory': true},
        {'time': TimeOfDay(hour: 7, minute: 15), 'label': 'Sit up 50×', 'mandatory': true},
        {'time': TimeOfDay(hour: 7, minute: 30), 'label': 'Mandi', 'mandatory': true},
        {'time': TimeOfDay(hour: 8, minute: 0), 'label': 'Membaca buku 30 halaman', 'mandatory': true},
      ],
    };
    return schedules;
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  Future<void> _markTaskCompleted(bool mandatory, int optionalIndex, String taskLabel) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (mandatory) exp += 10; else exp += 20;
      int newLevel = (exp / 100).floor();
      if (newLevel > level) {
        level = newLevel;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showRewardDialog());
      }
    });
    await prefs.setInt('exp', exp);
    await prefs.setInt('level', level);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tugas \"$taskLabel\" diselesaikan! +${mandatory?10:20} EXP')));
  }

  void _showRewardDialog() async {
    final rewards = ['Bermain game 1 jam', 'Mendengarkan musik 1 jam', 'Melakukan hobi 2 jam', 'Istirahat 2 jam', 'Menonton 1 film'];
    String? chosen = await showDialog<String>(context: context, builder: (context) {
      return AlertDialog(
        title: const Text('Level Up! Pilih hadiahmu'),
        content: Column(mainAxisSize: MainAxisSize.min, children: rewards.map((r) => ListTile(title: Text(r), onTap: () => Navigator.of(context).pop(r))).toList()),
      );
    });
    if (chosen != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hadiah dipilih: $chosen')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _getDailySchedule()[mandatoryLevel]!;
    return Scaffold(
      appBar: AppBar(title: Text('SoloMission — Halo, $nickname')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level: $level   EXP: $exp', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Card(child: ListTile(title: const Text('Countdown ke 05:00'), subtitle: Text(_formatDuration(_timeToFiveAM)), trailing: ElevatedButton(onPressed: _onStartPressed, child: const Text('Mulai')))),
            const SizedBox(height: 12),
            const Text('Jadwal hari ini:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(child: ListView.builder(itemCount: schedule.length, itemBuilder: (context, idx) {
              final item = schedule[idx];
              final now = DateTime.now();
              final scheduled = DateTime(now.year, now.month, now.day, item['time'].hour, item['time'].minute);
              Duration remaining = scheduled.difference(now);
              if (remaining.isNegative) remaining = Duration.zero;
              return Card(child: ListTile(
                title: Text(item['label']),
                subtitle: Text('Waktu: ${item['time'].format(context)}   Sisa: ${_formatDuration(remaining)}'),
                trailing: ElevatedButton(onPressed: () => _markTaskCompleted(true, -1, item['label']), child: const Text('Selesai')),));
            })),
            const SizedBox(height: 8),
            const Text('Tugas opsional:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...List.generate(5, (i) {
              final t = optionalTasks[i];
              return Card(child: ListTile(
                title: Text(t.isEmpty ? 'Tugas opsional kosong' : t),
                subtitle: const Text('Tekan \"Mulai\" untuk timer 1 jam'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  ElevatedButton(onPressed: t.isEmpty ? null : () => _startOptionalTimer(i, t), child: const Text('Mulai')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: t.isEmpty ? null : () => _markTaskCompleted(false, i, t), child: const Text('Selesai')),
                ]),
              ));
            })
          ],
        ),
      ),
    );
  }

  void _startOptionalTimer(int index, String label) {
    final end = DateTime.now().add(const Duration(hours: 1));
    showDialog(context: context, barrierDismissible: false, builder: (context) {
      return OptionalTimerDialog(end: end, onFinish: () async {
        await _markTaskCompleted(false, index, label);
      });
    });
  }
}

class OptionalTimerDialog extends StatefulWidget {
  final DateTime end;
  final VoidCallback onFinish;
  OptionalTimerDialog({required this.end, required this.onFinish});
  @override
  _OptionalTimerDialogState createState() => _OptionalTimerDialogState();
}

class _OptionalTimerDialogState extends State<OptionalTimerDialog> {
  late Timer _t;
  Duration _remain = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final now = DateTime.now();
    setState(() {
      _remain = widget.end.difference(now);
      if (_remain.isNegative) _remain = Duration.zero;
    });
    if (_remain == Duration.zero) {
      _t.cancel();
      widget.onFinish();
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tugas opsional berlangsung'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [Text('Sisa waktu: ${_fmt(_remain)}')]),
      actions: [TextButton(onPressed: () { _t.cancel(); Navigator.of(context).pop(); }, child: const Text('Batal'))],
    );
  }
}
