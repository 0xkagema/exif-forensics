import 'package:exif/exif.dart';
import 'package:flutter/services.dart';

class ExifServices {
  static Future<Map<String, dynamic>> readExifData(Uint8List bytes) async {
    try {
      var exifData = await readExifFromBytes(bytes);
      Map<String, dynamic> data = {};
      for (var i in exifData.entries) {
        data[i.key] = i.value;
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }
}
