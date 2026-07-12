import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FileServices {
  static Future<Uint8List> selectImageFileAndReturnBytes() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        throw Exception("No file selected");
      }

      final bytes = await image.readAsBytes();
      return bytes;
    } catch (e) {
      rethrow;
    }
  }
}
