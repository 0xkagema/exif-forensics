import 'package:exifapp/src/rust/api/simple.dart';
import 'package:exifapp/src/rust/frb_generated.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'core/state/forensics_controller.dart';
import 'theme.dart';
import 'ui/pages/home.dart';

Future<void> main() async {
  await RustLib.init();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExifForensicsApp());
}

class ExifForensicsApp extends StatefulWidget {
  const ExifForensicsApp({super.key});

  @override
  State<ExifForensicsApp> createState() => _ExifForensicsAppState();
}

class _ExifForensicsAppState extends State<ExifForensicsApp> {
  late final ForensicsController _controller;

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      config: const ToastificationConfig(alignment: Alignment.bottomRight),
      child: MaterialApp(
        title: 'EXIF Forensics',
        debugShowCheckedModeBanner: false,
        themeMode: _controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: AppTheme.lightTheme.copyWith(
          extensions: [AppThemeExtension.light],
        ),
        darkTheme: AppTheme.darkTheme.copyWith(
          extensions: [AppThemeExtension.dark],
        ),
        home: HomePage(controller: _controller),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChange);
    _controller.dispose();
    super.dispose();
  }



  @override
  void initState() {
    super.initState();
    _controller = ForensicsController();
    _controller.addListener(_onStateChange);
  }

  void _onStateChange() {
    setState(() {});
  }
}
