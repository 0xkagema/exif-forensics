import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:exifapp/core/models/models.dart';
import 'package:exifapp/core/services/services.dart';

void main() {
  test('Analyze real Nokia sample image from test-images folder', () async {
    final file = File('test-images/IMG_20250708_131710_HDR.jpg');
    if (!file.existsSync()) {
      return;
    }

    final bytes = await file.readAsBytes();
    final report = await ExifServices.analyzeImageBytes(
      bytes: bytes,
      fileName: 'IMG_20250708_131710_HDR.jpg',
    );

    // Verify file metadata & hashes
    expect(report.file.fileName, 'IMG_20250708_131710_HDR.jpg');
    expect(report.file.mimeType, 'image/jpeg');
    expect(report.file.fileSizeBytes, greaterThan(0));
    expect(report.file.md5Hash, isNotEmpty);
    expect(report.file.sha256Hash, isNotEmpty);

    // Verify Device
    expect(report.device.displayName, contains('HMD Global'));
    expect(report.device.model, contains('M-KOPA X2'));
    expect(report.device.softwareVersion, contains('00WW_2_470'));

    // Verify AI / Authenticity Classification
    expect(
      report.aiDetection.classification,
      ForensicClassification.cameraOriginal,
    );
    expect(report.aiDetection.isAiGenerated, isFalse);

    // Verify GPS location
    expect(report.hasLocation, isTrue);
    expect(report.location!.latitude, isNotNull);
    expect(report.location!.longitude, isNotNull);

    // Verify Photography settings
    expect(report.photography.hasPhotoData, isTrue);

    // Verify Raw tags count
    expect(report.rawTags.length, greaterThan(10));
  });
}
