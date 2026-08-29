import 'dart:convert';

import 'ai_detection.dart';
import 'device.dart';
import 'file_metadata.dart';
import 'location.dart';
import 'photography_details.dart';

class ForensicsReport {
  final FileMetadata file;
  final DeviceDetails device;
  final PhotographyDetails photography;
  final PhotoLocation? location;
  final AiDetectionResult aiDetection;
  final DateTime? captureDateTime;
  final String? captureDateTimeString;
  final DateTime? digitizedDateTime;
  final DateTime? modifiedDateTime;
  final String? timeZoneOffset;
  final Map<String, dynamic> rawTags;
  final Map<String, Map<String, dynamic>> groupedTags;

  const ForensicsReport({
    required this.file,
    required this.device,
    required this.photography,
    this.location,
    required this.aiDetection,
    this.captureDateTime,
    this.captureDateTimeString,
    this.digitizedDateTime,
    this.modifiedDateTime,
    this.timeZoneOffset,
    required this.rawTags,
    required this.groupedTags,
  });

  bool get hasExifData => rawTags.isNotEmpty;
  bool get hasLocation => location != null;

  String toFormattedJson() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'file': file.toMap(),
      'aiDetection': aiDetection.toMap(),
      'device': device.toMap(),
      'photography': photography.toMap(),
      'location': location?.toMap(),
      'timestamps': {
        'captureDateTime': captureDateTime?.toIso8601String(),
        'captureDateTimeString': captureDateTimeString,
        'digitizedDateTime': digitizedDateTime?.toIso8601String(),
        'modifiedDateTime': modifiedDateTime?.toIso8601String(),
        'timeZoneOffset': timeZoneOffset,
      },
      'tagCount': rawTags.length,
      'rawTags': rawTags.map((k, v) => MapEntry(k, v.toString())),
    };
  }

  String toMarkdownReport() {
    final buffer = StringBuffer();
    buffer.writeln('# EXIF Forensics Investigation Report');
    buffer.writeln(
      '**Generated on:** ${DateTime.now().toUtc().toIso8601String()} UTC',
    );
    buffer.writeln('');
    buffer.writeln('## 1. File & Cryptographic Integrity');
    buffer.writeln('- **File Name:** `${file.fileName}`');
    buffer.writeln('- **File Size:** ${file.formattedSize}');
    buffer.writeln('- **MIME Type:** ${file.mimeType}');
    buffer.writeln('- **Resolution:** ${file.dimensionsString}');
    buffer.writeln('- **MD5:** `${file.md5Hash}`');
    buffer.writeln('- **SHA-256:** `${file.sha256Hash}`');
    buffer.writeln('');

    buffer.writeln('## 2. AI & Provenance Forensics');
    buffer.writeln('- **Verdict:** ${aiDetection.verdict}');
    buffer.writeln('- **Confidence:** ${aiDetection.confidenceLabel}');
    buffer.writeln('- **Analysis:** ${aiDetection.explanation}');
    if (aiDetection.generator != null) {
      buffer.writeln('- **Generator / Tool:** ${aiDetection.generator}');
    }
    if (aiDetection.model != null) {
      buffer.writeln('- **Model:** ${aiDetection.model}');
    }
    if (aiDetection.prompt != null && aiDetection.prompt!.isNotEmpty) {
      buffer.writeln('- **Embedded Prompt:** `${aiDetection.prompt}`');
    }
    if (aiDetection.hasC2paManifest) {
      buffer.writeln(
        '- **C2PA Credentials:** Present (${aiDetection.c2paIssuer ?? 'Issuer Verified'})',
      );
      if (aiDetection.c2paSignature?.validationState != null) {
        buffer.writeln(
          '- **Signature Status:** ${aiDetection.c2paSignature!.validationState} (Algorithm: ${aiDetection.c2paSignature!.algorithm?.toUpperCase() ?? 'N/A'})',
        );
      }
      if (aiDetection.c2paSignature?.signingTime != null) {
        buffer.writeln(
          '- **Signing Time:** ${aiDetection.c2paSignature!.signingTime}',
        );
      }
      if (aiDetection.c2paActionSummaries.isNotEmpty) {
        buffer.writeln('- **Provenance Actions:**');
        for (final act in aiDetection.c2paActionSummaries) {
          buffer.writeln(
            '  - `${act.action}`${act.softwareAgent != null ? " by ${act.softwareAgent}" : ""}${act.when != null ? " at ${act.when}" : ""}',
          );
        }
      }
    }
    buffer.writeln('');

    buffer.writeln('## 3. Capture & Timestamps');
    buffer.writeln(
      '- **Original Capture Time:** ${captureDateTimeString ?? 'N/A'}',
    );
    if (modifiedDateTime != null) {
      buffer.writeln(
        '- **Modified Time:** ${modifiedDateTime!.toIso8601String()}',
      );
    }
    if (timeZoneOffset != null) {
      buffer.writeln('- **Offset / TimeZone:** $timeZoneOffset');
    }
    buffer.writeln('');

    buffer.writeln('## 4. Hardware & Camera Device');
    buffer.writeln('- **Device:** ${device.displayName}');
    if (device.manufacturer != null) {
      buffer.writeln('- **Manufacturer:** ${device.manufacturer}');
    }
    if (device.model != null) buffer.writeln('- **Model:** ${device.model}');
    if (device.softwareVersion != null) {
      buffer.writeln('- **Software / Firmware:** ${device.softwareVersion}');
    }
    if (device.lensModel != null) {
      buffer.writeln('- **Lens Model:** ${device.lensModel}');
    }
    if (device.bodySerialNumber != null) {
      buffer.writeln('- **Body Serial Number:** ${device.bodySerialNumber}');
    }
    if (device.artist != null) {
      buffer.writeln('- **Artist / Photographer:** ${device.artist}');
    }
    if (device.copyright != null) {
      buffer.writeln('- **Copyright:** ${device.copyright}');
    }
    buffer.writeln('');

    buffer.writeln('## 5. Photographic Parameters');
    buffer.writeln('- **ISO:** ${photography.iso ?? 'N/A'}');
    buffer.writeln('- **Exposure Time:** ${photography.exposureTime ?? 'N/A'}');
    buffer.writeln('- **Aperture (F-Stop):** ${photography.fNumber ?? 'N/A'}');
    buffer.writeln(
      '- **Focal Length:** ${photography.focalLength ?? 'N/A'} (35mm equiv: ${photography.focalLength35mm ?? 'N/A'})',
    );
    buffer.writeln('- **Flash:** ${photography.flash ?? 'N/A'}');
    buffer.writeln('- **White Balance:** ${photography.whiteBalance ?? 'N/A'}');
    buffer.writeln('- **Metering Mode:** ${photography.meteringMode ?? 'N/A'}');
    buffer.writeln('- **Color Space:** ${photography.colorSpace ?? 'N/A'}');
    buffer.writeln('');

    if (location != null) {
      buffer.writeln('## 6. Geolocation & GPS Intelligence');
      buffer.writeln(
        '- **Coordinates (Decimal):** `${location!.formattedDecimal}`',
      );
      buffer.writeln('- **Coordinates (DMS):** `${location!.formattedDms}`');
      if (location!.altitude != null) {
        buffer.writeln(
          '- **Altitude:** ${location!.altitude!.toStringAsFixed(1)} m',
        );
      }
      if (location!.speed != null) {
        buffer.writeln('- **Speed:** ${location!.speed} km/h');
      }
      if (location!.imgDirection != null) {
        buffer.writeln('- **Heading / Direction:** ${location!.imgDirection}°');
      }
      buffer.writeln(
        '- **OpenStreetMap:** [View Map](${location!.openStreetMapUrl})',
      );
      buffer.writeln(
        '- **Google Maps:** [View Map](${location!.googleMapsUrl})',
      );
      buffer.writeln('');
    }

    buffer.writeln('## 7. Raw Metadata Summary');
    buffer.writeln('- **Total IFD Tags Extracted:** ${rawTags.length}');
    buffer.writeln('');

    return buffer.toString();
  }
}
