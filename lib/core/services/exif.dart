import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:exif/exif.dart';

import '../models/models.dart';
import 'c2pa.dart';

class ExifServices {
  /// Comprehensive forensics analysis of image bytes
  static Future<ForensicsReport> analyzeImageBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    // 1. Calculate Cryptographic Hashes
    final md5Hash = md5.convert(bytes).toString();
    final sha256Hash = sha256.convert(bytes).toString();
    final mimeType = _detectMimeType(bytes, fileName);

    // 2. Extract Raw EXIF IFD Tags
    Map<String, dynamic> rawTags = {};
    try {
      final exifData = await readExifFromBytes(bytes);
      for (final entry in exifData.entries) {
        rawTags[entry.key] = entry.value;
      }
    } catch (_) {
      // Continue even if standard EXIF parsing throws or finds no headers
    }

    // 3. Categorize tags into IFD groups
    final groupedTags = _groupTags(rawTags);

    // 4. Extract Location
    final location = _extractLocation(rawTags);

    // 5. Extract Device Details
    final device = _extractDevice(rawTags);

    // 6. Extract Photography Details
    final photography = _extractPhotography(rawTags);

    // 7. Extract Timestamps
    final captureStr = _getTagPrintable(rawTags, [
      'EXIF DateTimeOriginal',
      'Image DateTime',
    ]);
    final digitizedStr = _getTagPrintable(rawTags, ['EXIF DateTimeDigitized']);
    final modifiedStr = _getTagPrintable(rawTags, ['Image DateTime']);
    final offsetStr = _getTagPrintable(rawTags, [
      'EXIF OffsetTimeOriginal',
      'EXIF OffsetTime',
      'EXIF OffsetTimeDigitized',
    ]);

    final captureDateTime = _parseExifDate(captureStr);
    final digitizedDateTime = _parseExifDate(digitizedStr);
    final modifiedDateTime = _parseExifDate(modifiedStr);

    // 8. Determine Dimensions
    int? width = _parseInt(
      _getTagPrintable(rawTags, ['EXIF ExifImageWidth', 'Image ImageWidth']),
    );
    int? height = _parseInt(
      _getTagPrintable(rawTags, ['EXIF ExifImageLength', 'Image ImageLength']),
    );

    final fileMeta = FileMetadata(
      fileName: fileName,
      fileSizeBytes: bytes.length,
      mimeType: mimeType,
      md5Hash: md5Hash,
      sha256Hash: sha256Hash,
      width: width ?? photography.imageWidth,
      height: height ?? photography.imageHeight,
    );

    // 9. Analyze AI & C2PA Provenance
    final aiDetection = C2paService.analyzeProvenance(
      bytes: bytes,
      exifTags: rawTags,
      mimeType: mimeType,
    );

    return ForensicsReport(
      file: fileMeta,
      device: device,
      photography: photography,
      location: location,
      aiDetection: aiDetection,
      captureDateTime: captureDateTime,
      captureDateTimeString: captureStr,
      digitizedDateTime: digitizedDateTime,
      modifiedDateTime: modifiedDateTime,
      timeZoneOffset: offsetStr,
      rawTags: rawTags,
      groupedTags: groupedTags,
    );
  }

  /// detect filetype by looking at the magic number
  static String _detectMimeType(Uint8List bytes, String fileName) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes.length >= 4 &&
        ((bytes[0] == 0x49 &&
                bytes[1] == 0x49 &&
                bytes[2] == 0x2A &&
                bytes[3] == 0x00) ||
            (bytes[0] == 0x4D &&
                bytes[1] == 0x4D &&
                bytes[2] == 0x00 &&
                bytes[3] == 0x2A))) {
      return 'image/tiff';
    }

    final ext = fileName.toLowerCase();
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.webp')) return 'image/webp';
    if (ext.endsWith('.heic')) return 'image/heic';
    if (ext.endsWith('.tiff') || ext.endsWith('.tif')) return 'image/tiff';
    return 'image/unknown';
  }

  static DeviceDetails _extractDevice(Map<String, dynamic> exif) {
    return DeviceDetails(
      manufacturer: _getTagPrintable(exif, ['Image Make']),
      model: _getTagPrintable(exif, ['Image Model']),
      softwareVersion: _getTagPrintable(exif, ['Image Software']),
      lensMake: _getTagPrintable(exif, ['EXIF LensMake']),
      lensModel: _getTagPrintable(exif, ['EXIF LensModel']),
      lensSpecification: _getTagPrintable(exif, ['EXIF LensSpecification']),
      cameraOwner: _getTagPrintable(exif, [
        'EXIF CameraOwnerName',
        'Image CameraOwnerName',
      ]),
      bodySerialNumber: _getTagPrintable(exif, [
        'EXIF BodySerialNumber',
        'EXIF SerialNumber',
      ]),
      lensSerialNumber: _getTagPrintable(exif, ['EXIF LensSerialNumber']),
      artist: _getTagPrintable(exif, ['Image Artist']),
      copyright: _getTagPrintable(exif, ['Image Copyright']),
    );
  }

  static PhotoLocation? _extractLocation(Map<String, dynamic> exif) {
    final latTag = exif['GPS GPSLatitude'];
    final latRefTag = exif['GPS GPSLatitudeRef'];
    final lngTag = exif['GPS GPSLongitude'];
    final lngRefTag = exif['GPS GPSLongitudeRef'];

    if (latTag == null ||
        latRefTag == null ||
        lngTag == null ||
        lngRefTag == null) {
      return null;
    }

    try {
      final latPrintable = latTag is IfdTag
          ? latTag.printable
          : latTag.toString();
      final latRef = latRefTag is IfdTag
          ? latRefTag.printable
          : latRefTag.toString();
      final lngPrintable = lngTag is IfdTag
          ? lngTag.printable
          : lngTag.toString();
      final lngRef = lngRefTag is IfdTag
          ? lngRefTag.printable
          : lngRefTag.toString();

      final lat = _parseExifCoordinate(latPrintable, latRef);
      final lng = _parseExifCoordinate(lngPrintable, lngRef);

      if (lat == null || lng == null) return null;

      final latDms = _formatDms(latPrintable, latRef);
      final lngDms = _formatDms(lngPrintable, lngRef);

      double? altitude;
      final altTag = exif['GPS GPSAltitude'];
      final altRefTag = exif['GPS GPSAltitudeRef'];
      if (altTag != null) {
        final altStr = altTag is IfdTag ? altTag.printable : altTag.toString();
        altitude = _parseFractionOrDouble(altStr);
        if (altitude != null && altRefTag != null) {
          final altRefStr = altRefTag is IfdTag
              ? altRefTag.printable
              : altRefTag.toString();
          if (altRefStr == '1' || altRefStr.toLowerCase().contains('below')) {
            altitude = -altitude;
          }
        }
      }

      final dateStamp = _getTagPrintable(exif, ['GPS GPSDateStamp']);
      final timeStamp = _getTagPrintable(exif, ['GPS GPSTimeStamp']);
      final speedStr = _getTagPrintable(exif, ['GPS GPSSpeed']);
      final speed = speedStr != null ? _parseFractionOrDouble(speedStr) : null;
      final dirStr = _getTagPrintable(exif, [
        'GPS GPSImgDirection',
        'GPS GPSTrack',
      ]);
      final imgDirection = dirStr != null
          ? _parseFractionOrDouble(dirStr)
          : null;
      final mapDatum = _getTagPrintable(exif, ['GPS GPSMapDatum']);

      return PhotoLocation(
        latitude: lat,
        longitude: lng,
        altitude: altitude,
        latitudeDms: latDms,
        longitudeDms: lngDms,
        gpsDateStamp: dateStamp,
        gpsTimeStamp: timeStamp,
        speed: speed,
        imgDirection: imgDirection,
        mapDatum: mapDatum,
      );
    } catch (_) {
      return null;
    }
  }

  static PhotographyDetails _extractPhotography(Map<String, dynamic> exif) {
    return PhotographyDetails(
      iso: _getTagPrintable(exif, [
        'EXIF ISOSpeedRatings',
        'EXIF PhotographicSensitivity',
      ]),
      exposureTime: _getTagPrintable(exif, ['EXIF ExposureTime']),
      fNumber: _getTagPrintable(exif, ['EXIF FNumber']),
      shutterSpeed: _getTagPrintable(exif, ['EXIF ShutterSpeedValue']),
      focalLength: _getTagPrintable(exif, ['EXIF FocalLength']),
      focalLength35mm: _getTagPrintable(exif, ['EXIF FocalLengthIn35mmFilm']),
      exposureProgram: _getTagPrintable(exif, ['EXIF ExposureProgram']),
      exposureBias: _getTagPrintable(exif, ['EXIF ExposureBiasValue']),
      meteringMode: _getTagPrintable(exif, ['EXIF MeteringMode']),
      flash: _getTagPrintable(exif, ['EXIF Flash']),
      whiteBalance: _getTagPrintable(exif, ['EXIF WhiteBalance']),
      colorSpace: _getTagPrintable(exif, ['EXIF ColorSpace']),
      orientation: _getTagPrintable(exif, [
        'Image Orientation',
        'EXIF Orientation',
      ]),
      imageWidth: _parseInt(
        _getTagPrintable(exif, ['EXIF ExifImageWidth', 'Image ImageWidth']),
      ),
      imageHeight: _parseInt(
        _getTagPrintable(exif, ['EXIF ExifImageLength', 'Image ImageLength']),
      ),
      xResolution: _getTagPrintable(exif, ['Image XResolution']),
      yResolution: _getTagPrintable(exif, ['Image YResolution']),
      resolutionUnit: _getTagPrintable(exif, ['Image ResolutionUnit']),
      contrast: _getTagPrintable(exif, ['EXIF Contrast']),
      saturation: _getTagPrintable(exif, ['EXIF Saturation']),
      sharpness: _getTagPrintable(exif, ['EXIF Sharpness']),
      digitalZoomRatio: _getTagPrintable(exif, ['EXIF DigitalZoomRatio']),
      sceneCaptureType: _getTagPrintable(exif, ['EXIF SceneCaptureType']),
      lightSource: _getTagPrintable(exif, ['EXIF LightSource']),
      sensingMethod: _getTagPrintable(exif, ['EXIF SensingMethod']),
    );
  }

  static String _formatDms(String value, String ref) {
    try {
      final clean = value.replaceAll('[', '').replaceAll(']', '').trim();
      final parts = clean.split(',');
      if (parts.length < 3) return '$value $ref';

      final degrees = (_parseFractionOrDouble(parts[0].trim()) ?? 0).toInt();
      final minutes = (_parseFractionOrDouble(parts[1].trim()) ?? 0).toInt();
      final seconds = _parseFractionOrDouble(parts[2].trim()) ?? 0;

      return '$degrees° $minutes\' ${seconds.toStringAsFixed(2)}" $ref'.trim();
    } catch (_) {
      return '$value $ref';
    }
  }

  static String? _getTagPrintable(
    Map<String, dynamic> exif,
    List<String> tagNames,
  ) {
    for (final name in tagNames) {
      if (exif.containsKey(name)) {
        final val = exif[name];
        if (val == null) continue;
        final str = val is IfdTag ? val.printable : val.toString();
        final trimmed = str.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return null;
  }

  static Map<String, Map<String, dynamic>> _groupTags(
    Map<String, dynamic> rawTags,
  ) {
    final Map<String, Map<String, dynamic>> groups = {
      'GPS': {},
      'Image': {},
      'EXIF': {},
      'Interoperability': {},
      'MakerNote': {},
      'Thumbnail': {},
      'Other': {},
    };

    for (final entry in rawTags.entries) {
      final key = entry.key;
      if (key.startsWith('GPS ')) {
        groups['GPS']![key] = entry.value;
      } else if (key.startsWith('Image ')) {
        groups['Image']![key] = entry.value;
      } else if (key.startsWith('EXIF ')) {
        groups['EXIF']![key] = entry.value;
      } else if (key.startsWith('Interoperability ')) {
        groups['Interoperability']![key] = entry.value;
      } else if (key.toLowerCase().contains('makernote')) {
        groups['MakerNote']![key] = entry.value;
      } else if (key.startsWith('Thumbnail ')) {
        groups['Thumbnail']![key] = entry.value;
      } else {
        groups['Other']![key] = entry.value;
      }
    }

    // Remove empty categories
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  static double? _parseExifCoordinate(String value, String ref) {
    try {
      final clean = value.replaceAll('[', '').replaceAll(']', '').trim();
      final parts = clean.split(',');
      if (parts.length < 3) return null;

      final degrees = _parseFractionOrDouble(parts[0].trim()) ?? 0;
      final minutes = _parseFractionOrDouble(parts[1].trim()) ?? 0;
      final seconds = _parseFractionOrDouble(parts[2].trim()) ?? 0;

      double decimal = degrees + (minutes / 60.0) + (seconds / 3600.0);
      final direction = ref.trim().toUpperCase();
      if (direction == 'S' || direction == 'W') {
        decimal *= -1;
      }
      return decimal;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseExifDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      // Formats like "2025:07:08 13:17:10"
      final parts = dateStr.trim().split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].replaceAll(':', '-');
        return DateTime.tryParse('${dateParts}T${parts[1]}');
      }
      return DateTime.tryParse(dateStr);
    } catch (_) {
      return null;
    }
  }

  static double? _parseFractionOrDouble(String str) {
    final s = str.trim();
    if (s.contains('/')) {
      final parts = s.split('/');
      if (parts.length == 2) {
        final num = double.tryParse(parts[0].trim());
        final den = double.tryParse(parts[1].trim());
        if (num != null && den != null && den != 0) {
          return num / den;
        }
      }
    }
    return double.tryParse(s);
  }

  static int? _parseInt(String? str) {
    if (str == null) return null;
    return int.tryParse(str.trim());
  }
}
