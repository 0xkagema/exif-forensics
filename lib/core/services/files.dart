import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class FileServices {
  static final ImagePicker _picker = ImagePicker();

  /// Opens system file picker to select an image and returns bytes + file name
  static Future<SelectedFileData> selectImageFile() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        throw Exception("No file selected");
      }

      final bytes = await image.readAsBytes();
      return SelectedFileData(bytes: bytes, fileName: image.name);
    } catch (e) {
      rethrow;
    }
  }
}

class SelectedFileData {
  final Uint8List bytes;
  final String fileName;

  const SelectedFileData({required this.bytes, required this.fileName});
}
