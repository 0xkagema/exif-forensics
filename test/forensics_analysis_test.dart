import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:exifapp/core/models/models.dart';
import 'package:exifapp/core/services/services.dart';

void main() {
  group('PhotoLocation Model Tests', () {
    test('Decimal and DMS formatting works properly', () {
      const loc = PhotoLocation(
        latitude: -1.202883,
        longitude: 36.918306,
        latitudeDms: '1° 12\' 10.38" S',
        longitudeDms: '36° 55\' 5.90" E',
        altitude: 1642.5,
      );

      expect(loc.formattedDecimal, '-1.202883, 36.918306');
      expect(loc.formattedDms, '1° 12\' 10.38" S, 36° 55\' 5.90" E');
      expect(loc.googleMapsUrl, contains('-1.202883,36.918306'));
      expect(loc.openStreetMapUrl, contains('-1.202883'));
    });
  });

  group('DeviceDetails Model Tests', () {
    test('Device display name formatting', () {
      const device1 = DeviceDetails(
        manufacturer: 'HMD Global',
        model: 'Nokia C22',
        softwareVersion: '00WW_2_470',
      );
      expect(device1.displayName, 'HMD Global Nokia C22');

      const device2 = DeviceDetails(
        manufacturer: 'Apple',
        model: 'iPhone 15 Pro',
      );
      expect(device2.displayName, 'Apple iPhone 15 Pro');

      const device3 = DeviceDetails(model: 'Sony ILCE-7M4');
      expect(device3.displayName, 'Sony ILCE-7M4');

      const deviceEmpty = DeviceDetails();
      expect(deviceEmpty.displayName, 'Unknown Device');
      expect(deviceEmpty.hasDeviceData, isFalse);
    });
  });

  group('C2PA & AI Provenance Detection Tests', () {
    test('Detects camera original when authentic EXIF tags are present', () {
      final tags = {
        'Image Make': 'Nokia',
        'Image Model': 'C22',
        'EXIF ExposureTime': '1/250',
        'EXIF FNumber': '2.0',
        'EXIF ISOSpeedRatings': '100',
        'GPS GPSLatitude': '[1, 14, 549/50]',
        'GPS GPSLatitudeRef': 'S',
        'GPS GPSLongitude': '[36, 33, 59/10]',
        'GPS GPSLongitudeRef': 'E',
      };

      final result = C2paService.analyzeProvenance(
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
        exifTags: tags,
      );

      expect(result.classification, ForensicClassification.cameraOriginal);
      expect(result.isAiGenerated, isFalse);
      expect(result.verdict, 'Authentic Camera Capture');
    });

    test('Detects Stable Diffusion from tag parameters', () {
      final tags = {
        'EXIF UserComment':
            'masterpiece, 1girl, cyberpunk city\nNegative prompt: blurry, bad anatomy\nSteps: 28, Sampler: Euler a, CFG scale: 7, Seed: 1234567, Model: dreamshaper_8',
      };

      final result = C2paService.analyzeProvenance(
        bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
        exifTags: tags,
      );

      expect(result.classification, ForensicClassification.aiGenerated);
      expect(result.isAiGenerated, isTrue);
      expect(result.confidence, AiConfidence.high);
      expect(result.prompt, 'masterpiece, 1girl, cyberpunk city');
      expect(result.negativePrompt, 'blurry, bad anatomy');
      expect(result.generator, 'Stable Diffusion Ecosystem');
    });

    test('Detects Midjourney from tag parameter switches', () {
      final tags = {
        'Image ImageDescription':
            'photorealistic astronaut exploring mars --v 6.0 --ar 16:9 --stylize 250',
      };

      final result = C2paService.analyzeProvenance(
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        exifTags: tags,
      );

      expect(result.classification, ForensicClassification.aiGenerated);
      expect(result.generator, 'Midjourney');
    });

    test('Detects digital editing software without camera sensor tags', () {
      final tags = {
        'Image Software': 'Adobe Photoshop 2024 (Windows)',
      };

      final result = C2paService.analyzeProvenance(
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        exifTags: tags,
      );

      expect(result.classification, ForensicClassification.digitallyEdited);
      expect(result.verdict, contains('Digitally Modified'));
    });
  });

  group('ExifServices Tests', () {
    test('Calculates hashes and generates complete ForensicsReport', () async {
      final dummyBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      ]);

      final report = await ExifServices.analyzeImageBytes(
        bytes: dummyBytes,
        fileName: 'test_sample.jpg',
      );

      expect(report.file.fileName, 'test_sample.jpg');
      expect(report.file.mimeType, 'image/jpeg');
      expect(report.file.md5Hash, isNotEmpty);
      expect(report.file.sha256Hash, isNotEmpty);
      expect(report.toMarkdownReport(), contains('EXIF Forensics Investigation Report'));
      expect(report.toFormattedJson(), contains('test_sample.jpg'));
    });
  });
}
