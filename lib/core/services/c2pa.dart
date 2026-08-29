import 'dart:typed_data';

import '../models/ai_detection.dart';


// Rust comes in here

class C2paService {
  /// Analyzes image bytes and extracted EXIF tags for AI generation markers,
  /// C2PA manifests, and digital provenance signatures.
  static AiDetectionResult analyzeProvenance({
    required Uint8List bytes,
    required Map<String, dynamic> exifTags,
  }) {
    final signatures = <String>[];
    final c2paActions = <String>[];
    bool hasC2pa = false;
    String? c2paIssuer;
    String? generator;
    String? model;
    String? prompt;
    String? negativePrompt;
    final generationParams = <String, dynamic>{};

    // 1. Scan binary bytes for C2PA JUMBF boxes or Content Credentials markers
    final byteString = _extractSearchableStrings(bytes);

    if (byteString.contains('c2pa') ||
        byteString.contains('jumb') ||
        byteString.contains('urn:uuid:c2pa') ||
        byteString.contains('c2pa.manifest')) {
      hasC2pa = true;
      signatures.add('C2PA Content Credentials Manifest detected');

      if (byteString.contains('Adobe') || byteString.contains('adobe')) {
        c2paIssuer = 'Adobe Content Authenticity Initiative';
      } else if (byteString.contains('Truepic')) {
        c2paIssuer = 'Truepic Lens';
      } else if (byteString.contains('Microsoft')) {
        c2paIssuer = 'Microsoft Content Credentials';
      } else if (byteString.contains('Google')) {
        c2paIssuer = 'Google SynthID';
      }

      if (byteString.contains('c2pa.created')) {
        c2paActions.add('c2pa.created');
      }
      if (byteString.contains('c2pa.edited')) {
        c2paActions.add('c2pa.edited');
      }
      if (byteString.contains('c2pa.placed')) {
        c2paActions.add('c2pa.placed');
      }
    }

    // 2. Check EXIF tag values for AI generation fingerprints
    final tagValues = exifTags.values.map((v) => v.toString()).toList();
    final tagString = tagValues.join(' \n ');

    // Stable Diffusion / Automatic1111 / ComfyUI / Forge / WebUI
    if (_containsIgnoreCase(tagString, 'Negative prompt:') ||
        _containsIgnoreCase(tagString, 'Steps:') &&
            _containsIgnoreCase(tagString, 'Sampler:') &&
            _containsIgnoreCase(tagString, 'CFG scale:') ||
        _containsIgnoreCase(tagString, 'ComfyUI') ||
        _containsIgnoreCase(tagString, 'Stable Diffusion') ||
        _containsIgnoreCase(tagString, 'AUTOMATIC1111') ||
        _containsIgnoreCase(byteString, 'ComfyUI') ||
        _containsIgnoreCase(byteString, 'StableDiffusion')) {
      generator = 'Stable Diffusion Ecosystem';
      signatures.add(
        'Stable Diffusion / Automatic1111 / ComfyUI metadata structure found',
      );

      _extractStableDiffusionParams(
        tagString.isNotEmpty ? tagString : byteString,
        generationParams,
        (p) => prompt = p,
        (np) => negativePrompt = np,
        (m) => model = m,
      );

      return AiDetectionResult(
        classification: ForensicClassification.aiGenerated,
        confidence: AiConfidence.high,
        verdict: 'AI-Generated Image (Stable Diffusion)',
        explanation:
            'Image metadata contains explicit generation parameters, sampling method, seed, and prompt indicative of Stable Diffusion / ComfyUI.',
        generator: generator,
        model: model ?? 'Stable Diffusion Checkpoint',
        prompt: prompt,
        negativePrompt: negativePrompt,
        generationParameters: generationParams,
        hasC2paManifest: hasC2pa,
        c2paIssuer: c2paIssuer,
        c2paActions: c2paActions,
        detectedSignatures: signatures,
      );
    }

    // Midjourney
    if (_containsIgnoreCase(tagString, 'Midjourney') ||
        _containsIgnoreCase(byteString, 'Midjourney') ||
        _containsIgnoreCase(tagString, '--v 5') ||
        _containsIgnoreCase(tagString, '--v 6') ||
        _containsIgnoreCase(tagString, '--ar ') &&
            _containsIgnoreCase(tagString, '--stylize')) {
      generator = 'Midjourney';
      signatures.add('Midjourney generation signature detected');

      return AiDetectionResult(
        classification: ForensicClassification.aiGenerated,
        confidence: AiConfidence.high,
        verdict: 'AI-Generated Image (Midjourney)',
        explanation:
            'Midjourney parameter switches and generation markers detected in embedded metadata fields.',
        generator: generator,
        model: 'Midjourney v5/v6',
        prompt: prompt ?? _extractMidjourneyPrompt(tagString),
        generationParameters: generationParams,
        hasC2paManifest: hasC2pa,
        c2paIssuer: c2paIssuer,
        c2paActions: c2paActions,
        detectedSignatures: signatures,
      );
    }

    // DALL-E / OpenAI / ChatGPT
    if (_containsIgnoreCase(tagString, 'DALL·E') ||
        _containsIgnoreCase(tagString, 'DALL-E') ||
        _containsIgnoreCase(byteString, 'DALL-E') ||
        _containsIgnoreCase(tagString, 'OpenAI') &&
            _containsIgnoreCase(tagString, 'generative')) {
      generator = 'OpenAI DALL·E';
      signatures.add('DALL·E provenance signature detected');

      return AiDetectionResult(
        classification: ForensicClassification.aiGenerated,
        confidence: AiConfidence.high,
        verdict: 'AI-Generated Image (DALL·E / OpenAI)',
        explanation:
            'Image contains OpenAI / DALL-E synthetic image generation watermarks or tags.',
        generator: generator,
        model: 'DALL·E 3 / DALL·E 2',
        prompt: prompt,
        generationParameters: generationParams,
        hasC2paManifest: hasC2pa,
        c2paIssuer: c2paIssuer,
        c2paActions: c2paActions,
        detectedSignatures: signatures,
      );
    }

    // Adobe Firefly
    if (_containsIgnoreCase(tagString, 'Adobe Firefly') ||
        _containsIgnoreCase(byteString, 'Adobe Firefly') ||
        _containsIgnoreCase(byteString, 'adobe:firefly')) {
      generator = 'Adobe Firefly';
      signatures.add('Adobe Firefly AI generation signature detected');

      return AiDetectionResult(
        classification: ForensicClassification.aiGenerated,
        confidence: AiConfidence.high,
        verdict: 'AI-Generated Image (Adobe Firefly)',
        explanation:
            'Adobe Firefly generative AI provenance tags and assertions found in metadata.',
        generator: generator,
        model: 'Firefly Image Model',
        prompt: prompt,
        hasC2paManifest: hasC2pa,
        c2paIssuer: c2paIssuer ?? 'Adobe CAI',
        c2paActions: c2paActions,
        detectedSignatures: signatures,
      );
    }

    // Flux / Black Forest Labs
    if (_containsIgnoreCase(tagString, 'FLUX.1') ||
        _containsIgnoreCase(tagString, 'Black Forest Labs') ||
        _containsIgnoreCase(byteString, 'FLUX.1')) {
      generator = 'Black Forest Labs (FLUX)';
      signatures.add('FLUX.1 generation signature detected');

      return AiDetectionResult(
        classification: ForensicClassification.aiGenerated,
        confidence: AiConfidence.high,
        verdict: 'AI-Generated Image (FLUX.1)',
        explanation:
            'Black Forest Labs FLUX.1 generation signatures identified.',
        generator: generator,
        model: 'FLUX.1',
        prompt: prompt,
        hasC2paManifest: hasC2pa,
        c2paIssuer: c2paIssuer,
        c2paActions: c2paActions,
        detectedSignatures: signatures,
      );
    }

    // Check for authentic camera hardware metadata
    final hasCameraMake = exifTags.containsKey('Image Make');
    final hasCameraModel = exifTags.containsKey('Image Model');
    final hasExposure =
        exifTags.containsKey('EXIF ExposureTime') ||
        exifTags.containsKey('EXIF FNumber');
    final hasIso = exifTags.containsKey('EXIF ISOSpeedRatings');
    final hasDateOriginal = exifTags.containsKey('EXIF DateTimeOriginal');
    final hasGps =
        exifTags.containsKey('GPS GPSLatitude') &&
        exifTags.containsKey('GPS GPSLongitude');

    if (hasCameraMake &&
        hasCameraModel &&
        (hasExposure || hasIso || hasDateOriginal)) {
      final make = exifTags['Image Make']?.toString() ?? '';
      final modelName = exifTags['Image Model']?.toString() ?? '';

      return AiDetectionResult(
        classification: ForensicClassification.cameraOriginal,
        confidence: hasGps ? AiConfidence.high : AiConfidence.medium,
        verdict: 'Authentic Camera Capture',
        explanation:
            'Image retains authentic camera hardware tags ($make $modelName), optical sensor exposure parameters, and EXIF timestamp records with no synthetic generation signatures.',
        generator: null,
        model: '$make $modelName',
        hasC2paManifest: hasC2pa,
        c2paIssuer: c2paIssuer,
        c2paActions: c2paActions,
        detectedSignatures: [
          'Hardware optical sensor metadata verified',
          if (hasGps) 'Authentic GPS telemetry recorded',
          if (hasDateOriginal) 'Original shutter timestamp recorded',
        ],
      );
    }

    // Check for image editing software without camera sensor tags
    final softwareTag = exifTags['Image Software']?.toString() ?? '';
    if (softwareTag.isNotEmpty) {
      if (_containsIgnoreCase(softwareTag, 'Photoshop') ||
          _containsIgnoreCase(softwareTag, 'GIMP') ||
          _containsIgnoreCase(softwareTag, 'Canva') ||
          _containsIgnoreCase(softwareTag, 'Affinity') ||
          _containsIgnoreCase(softwareTag, 'Lightroom')) {
        return AiDetectionResult(
          classification: ForensicClassification.digitallyEdited,
          confidence: AiConfidence.medium,
          verdict: 'Digitally Modified / Edited Image',
          explanation:
              'Image contains editing software signatures ($softwareTag) without complete raw camera sensor data.',
          generator: softwareTag,
          hasC2paManifest: hasC2pa,
          c2paIssuer: c2paIssuer,
          c2paActions: c2paActions,
          detectedSignatures: ['Editing software marker: $softwareTag'],
        );
      }
    }

    // Default: Inconclusive
    return AiDetectionResult(
      classification: ForensicClassification.inconclusive,
      confidence: AiConfidence.none,
      verdict: 'Inconclusive / Clean Metadata',
      explanation:
          'No synthetic AI generation markers or verified raw camera sensor tags were found. Metadata may have been stripped or cleaned by social media platforms.',
      hasC2paManifest: hasC2pa,
      c2paIssuer: c2paIssuer,
      c2paActions: c2paActions,
      detectedSignatures: hasC2pa ? ['C2PA Manifest present'] : [],
    );
  }

  static bool _containsIgnoreCase(String source, String query) {
    return source.toLowerCase().contains(query.toLowerCase());
  }

  static String? _extractMidjourneyPrompt(String text) {
    final index = text.indexOf('--');
    if (index > 0) {
      return text.substring(0, index).trim();
    }
    return null;
  }

  static String _extractSearchableStrings(Uint8List bytes) {
    // Scan leading bytes (up to 128KB) and trailing bytes for text metadata / XMP / C2PA
    final buffer = StringBuffer();
    final headerLength = bytes.length < 131072 ? bytes.length : 131072;
    for (int i = 0; i < headerLength; i++) {
      final b = bytes[i];
      if (b >= 32 && b <= 126) {
        buffer.writeCharCode(b);
      } else {
        buffer.write(' ');
      }
    }

    if (bytes.length > 131072) {
      final tailStart = bytes.length - 32768;
      for (int i = tailStart; i < bytes.length; i++) {
        final b = bytes[i];
        if (b >= 32 && b <= 126) {
          buffer.writeCharCode(b);
        } else {
          buffer.write(' ');
        }
      }
    }
    return buffer.toString();
  }

  static void _extractStableDiffusionParams(
    String text,
    Map<String, dynamic> params,
    void Function(String) setPrompt,
    void Function(String) setNegPrompt,
    void Function(String) setModel,
  ) {
    if (text.contains('Negative prompt:')) {
      final parts = text.split('Negative prompt:');
      final promptText = parts[0].trim();
      setPrompt(promptText);

      final negAndParams = parts[1];
      if (negAndParams.contains('Steps:')) {
        final negParts = negAndParams.split('Steps:');
        setNegPrompt(negParts[0].trim());

        final paramString = 'Steps:${negParts[1]}';
        _parseParamString(paramString, params, setModel);
      } else {
        setNegPrompt(negAndParams.trim());
      }
    } else if (text.contains('Steps:') && text.contains('Sampler:')) {
      final stepsIndex = text.indexOf('Steps:');
      if (stepsIndex > 0) {
        setPrompt(text.substring(0, stepsIndex).trim());
      }
      _parseParamString(text.substring(stepsIndex), params, setModel);
    }
  }

  static void _parseParamString(
    String paramString,
    Map<String, dynamic> params,
    void Function(String) setModel,
  ) {
    final pairs = paramString.split(',');
    for (final pair in pairs) {
      final kv = pair.split(':');
      if (kv.length >= 2) {
        final k = kv[0].trim();
        final v = kv.sublist(1).join(':').trim();
        params[k] = v;
        if (k.toLowerCase() == 'model') {
          setModel(v);
        }
      }
    }
  }
}
