import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: MyColor.secondary,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const LetGo());
}

class MyColor {
  static const Color primary = Color(0xFFAD8746);
  static const Color secondary = Color(0xFF221F1F);
  static const Color accent = Color(0xFFCCBEA1);
}

class MyConstants {
  static const String title = 'LetitGo';
  static const String namesReference = 'tracker_names';
  static const String timestampsReference = 'tracker_timestamps';
}

class LetGo extends StatelessWidget {
  const LetGo({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: MyConstants.title,
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
  late final Timer _timer;
  List<String> _trackerNames = [];
  List<int> _trackerTimestamps = [];
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _loadTrackers();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadTrackers() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(MyConstants.namesReference) ?? [];
    final timestamps = prefs.getStringList(MyConstants.timestampsReference) ?? [];
    setState(() {
      _trackerNames = names;
      _trackerTimestamps = timestamps.map((e) => int.parse(e)).toList();
      _selectedIndex = _trackerNames.isNotEmpty ? 0 : null;
    });
  }

  Future<void> _saveTrackers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(MyConstants.namesReference, _trackerNames);
    await prefs.setStringList(MyConstants.timestampsReference, _trackerTimestamps.map((e) => e.toString()).toList());
  }

  Future<void> _createTracker() async {
    final name = await _showDialog(context: context, title: 'Create a new Memory', hint: 'Enter a name');
    if (name != null && name.isNotEmpty) {
      setState(() {
        _trackerNames.add(name);
        _trackerTimestamps.add(DateTime.now().millisecondsSinceEpoch);
        _selectedIndex = _trackerNames.length - 1;
      });
      await _saveTrackers();
    }
  }

  Future<void> _deleteTracker(int index) async {
    setState(() {
      _trackerNames.removeAt(index);
      _trackerTimestamps.removeAt(index);
      if (_selectedIndex == index) {
        _selectedIndex = _trackerNames.isNotEmpty ? 0 : null;
      }
    });
    await _saveTrackers();
  }

  Future<void> _renameTracker(int index) async {
    final newName = await _showDialog(context: context, title: 'Rename Memory', hint: 'Enter a new name', initialValue: _trackerNames[index]);
    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _trackerNames[index] = newName;
      });
      await _saveTrackers();
    }
  }

  Future<void> _changeStartDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.fromMillisecondsSinceEpoch(_trackerTimestamps[index]),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _trackerTimestamps[index] = picked.millisecondsSinceEpoch;
      });
      await _saveTrackers();
    }
  }

  Future<void> _showResetConfirmation(int index) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: MyColor.primary),
        ),
        title: const Text('Reset Counter'),
        content: const Text('Are you sure you want to reset the counter?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Reset'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (shouldReset == true) {
      setState(() {
        _trackerTimestamps[index] = DateTime.now().millisecondsSinceEpoch;
      });
      await _saveTrackers();
    }
  }

  Future<String?> _showDialog({
    required BuildContext context,
    required String title,
    required String hint,
    String? initialValue,
  }) async => showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        controller: initialValue != null ? TextEditingController(text: initialValue) : null,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );

  Iterable<(String, String)> _formatDuration(int index) {
    final startDate = DateTime.fromMillisecondsSinceEpoch(_trackerTimestamps[index]);
    final duration = DateTime.now().difference(startDate);
    final timeUnits = [
      (duration.inDays ~/ 365, 'y'),
      ((duration.inDays % 365) ~/ 30, 'M'),
      ((duration.inDays % 365) % 30, 'd'),
      (duration.inHours % 24, 'h'),
      (duration.inMinutes % 60, 'm'),
      (duration.inSeconds % 60, 's'),
    ];
    return timeUnits.where((unit) => unit.$1 > 0).map((unit) => (unit.$1.toString().padLeft(2, '0'), unit.$2));
  }

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
            trailing: const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.add),
            ),
            title: const Text('Create another Memory'),
            onTap: _createTracker,
          ),
          const Divider(
            color: MyColor.primary,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _trackerNames.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return ListTile(
                  tileColor: isSelected ? MyColor.primary.withOpacity(0.5) : null,
                  title: Text(_trackerNames[index]),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    Navigator.of(context).pop();
                  },
                  onLongPress: () => _renameTracker(index),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTracker(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    appBar: AppBar(
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectedIndex != null
                ? () => _changeStartDate(_selectedIndex!)
                : null,
          ),
        ),
      ],
    ),
    body: GestureDetector(
      onTap: _selectedIndex != null
          ? () => _showResetConfirmation(_selectedIndex!)
          : null,
      child: Container(
        color: MyColor.secondary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTitle(),
              if (_selectedIndex != null) _buildDurationList(_selectedIndex!),
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

  Widget _buildDurationList(int index) {
    const int fontFactor = 12;
    const int multiFactor = 4;
    const int lineLimit = 3;

    final formattedDuration = _formatDuration(index).toList();
    final line01 = formattedDuration.where((element) => ['y', 'M', 'd'].contains(element.$2)).toList();
    final line02 = formattedDuration.where((element) => ['h', 'm', 's'].contains(element.$2)).toList();

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
