import 'package:exifapp/src/rust/frb_generated.dart';
import 'package:flutter/material.dart';

import 'app.dart';

Future<void> main() async {
  // init Rust bridge
  await RustLib.init();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExifForensicsApp());
}
