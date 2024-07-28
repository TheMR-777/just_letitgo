import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

void main() => runApp(const LetGo());

class MyColor {
  static const Color primary = Color(0xFFAD8746);
  static const Color secondary = Color(0xFF221F1F);
  static const Color accent = Color(0xFFCCBEA1);
}

class MyConstants {
  static const String reference = 'start_date';
}

class LetGo extends StatelessWidget {
  const LetGo({super.key});
  static const String title = 'LetitGo';

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: title,
    themeMode: ThemeMode.dark,
    darkTheme: ThemeData(
      colorScheme: const ColorScheme.dark(
        primary: MyColor.primary,
        secondary: MyColor.secondary,
        tertiary: MyColor.accent,
        surface: MyColor.secondary,
        error: MyColor.accent,
        onPrimary: MyColor.secondary,
        onSecondary: MyColor.primary,
        onSurface: MyColor.accent,
        onError: MyColor.secondary,
      ),
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _startDate = DateTime.now();
  late final Timer _timer;

  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    _loadStartDate();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => update());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final startDateMillis = prefs.getInt(MyConstants.reference);
    if (startDateMillis == null) {
      await _resetStartDate(DateTime.now());
    } else {
      setState(() => _startDate = DateTime.fromMillisecondsSinceEpoch(startDateMillis));
    }
  }

  Future<void> _resetStartDate(DateTime use) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(MyConstants.reference, use.millisecondsSinceEpoch);
    setState(() => _startDate = use);
  }

  Future<void> _changeStartDate() async => showDatePicker(
    context: context,
    initialDate: _startDate,
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
  ).then((picked) {
    if (picked != null && picked != _startDate) {
      _resetStartDate(picked);
    }
  });

  Iterable<(String, String)> _formatDuration() {
    final duration = DateTime.now().difference(_startDate);

    // Calculate all time units once
    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;
    final days = (duration.inDays % 365) % 30;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    // Define a list of tuples with time units and their corresponding labels
    final timeUnits = [
      (years, 'y'),
      (months, 'M'),
      (days, 'd'),
      (hours, 'h'),
      (minutes, 'm'),
      (seconds, 's'),
    ];

    // Filter out zero values and convert to string with zero-padding
    return timeUnits
        .where((unit) => unit.$1 > 0)
        .map((unit) => (unit.$1.toString().padLeft(2, '0'), unit.$2));
  }

  Future<void> _showResetConfirmation() async => showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: MyColor.primary),
      ),
      title: const Text('Reset Counter'),
      content: const Text('Are you sure you want to reset the counter?'),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: MyColor.accent),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          child: const Text('Reset'),
          onPressed: () {
            _resetStartDate(DateTime.now());
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: Drawer(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16),
            height: 160,
            child: Center(
              child: _buildTitle(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create another Memory'),
            onTap: () {},
          ),
          const Divider(
            color: MyColor.primary,
          ),

          // Created Memories here
        ],
      ),
    ),
    appBar: AppBar(
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _changeStartDate,
          ),
        ),
      ],
    ),
    body: GestureDetector(
      onTap: _showResetConfirmation,
      child: Container(
        color: MyColor.secondary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTitle(),
              _buildDurationList(),
            ],
          ),
        ),
      ),
    ),
  );

  Text _buildTitle() => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'Let',
          style: GoogleFonts.dancingScript(
            color: MyColor.accent,
            fontSize: 50,
          ),
        ),
        TextSpan(
          text: 'it',
          style: GoogleFonts.dancingScript(
            color: MyColor.primary,
            fontSize: 50,
          ),
        ),
        TextSpan(
          text: 'Go',
          style: GoogleFonts.dancingScript(
            color: MyColor.accent,
            fontSize: 50,
          ),
        ),
      ],
    ),
  );

  Widget _buildDurationList() {
    const int fontFactor = 12;
    const int multiFactor = 4;
    const int lineLimit = 3;

    final formattedDuration = _formatDuration().toList();
    final line01 = formattedDuration
        .where((element) => ['y', 'M', 'd'].contains(element.$2))
        .toList();
    final line02 = formattedDuration
        .where((element) => ['h', 'm', 's'].contains(element.$2))
        .toList();

    final fontSize01 = fontFactor * (multiFactor + lineLimit - line01.length).toDouble();
    final fontSize02 = fontFactor * multiFactor.toDouble();

    return Column(
      children: [
        _buildDurationView(line01, fontSize01),
        _buildDurationView(line02, fontSize02),
      ],
    );
  }

  Widget _buildDurationView(List<(String, String)> durationList, double fontSize) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: durationList.map((part) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                part.$1,
                style: GoogleFonts.chivoMono(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: MyColor.accent,
                ),
              ),
              Text(
                part.$2,
                style: GoogleFonts.chivoMono(
                  fontSize: fontSize * 0.5,
                  fontWeight: FontWeight.normal,
                  color: MyColor.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
}
