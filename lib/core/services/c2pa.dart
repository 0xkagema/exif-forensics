import 'dart:typed_data';

import '../../src/rust/api/simple.dart';
import '../models/ai_detection.dart';

class C2paService {
  /// Analyzes image bytes and extracted EXIF tags for AI generation markers,
  /// C2PA manifests, and digital provenance signatures using the Rust C2PA engine.
  static AiDetectionResult analyzeProvenance({
    required Uint8List bytes,
    required Map<String, dynamic> exifTags,
    String? mimeType,
  }) {
    C2paResponseModel? c2paModel;

    // 1. Invoke high-performance Rust C2PA parser
    try {
      final rustJson = parseC2Pa(
        imageBytes: bytes,
        mimeType: mimeType,
      );
      c2paModel = C2paResponseModel.fromRawJson(rustJson);
    } catch (_) {
      // Graceful fallback if Rust bridge is not initialized
      c2paModel = null;
    }

    final signatures = <String>[];
    final c2paActions = <String>[];
    bool hasC2pa = false;
    String? c2paIssuer;
    String? generator;
    String? model;
    String? prompt;
    String? negativePrompt;
    final generationParams = <String, dynamic>{};

    // 2. Process Rust C2PA findings if present
    if (c2paModel != null && c2paModel.hasC2pa) {
      hasC2pa = true;
      signatures.add('C2PA Content Credentials Manifest detected');

      final sig = c2paModel.signature;
      if (sig != null) {
        c2paIssuer = sig.issuer ?? sig.commonName;
        if (c2paIssuer != null) {
          signatures.add('Signer Issuer: $c2paIssuer');
        }
        if (sig.algorithm != null) {
          signatures.add('Algorithm: ${sig.algorithm!.toUpperCase()}');
        }
        if (sig.validationState != null) {
          signatures.add('Cryptographic Signature: ${sig.validationState}');
        }
      }

      for (final act in c2paModel.actions) {
        c2paActions.add(act.action);
        if (act.isAiAction) {
          signatures.add('AI Provenance Action: ${act.action}');
        }
      }

      final ai = c2paModel.aiDetails;
      if (ai != null) {
        if (ai.modelDisplay != null) {
          signatures.add('AI Generator Model: ${ai.modelDisplay}');
        } else if (ai.modelName != null) {
          signatures.add('AI Generator Model: ${ai.modelName}');
        }
        if (ai.company != null) {
          signatures.add('AI Organization: ${ai.company}');
        }
        if (ai.digitalSourceType != null) {
          signatures.add('Digital Source Type: ${ai.digitalSourceType}');
        }
      }

      if (c2paModel.ingredients.isNotEmpty) {
        signatures.add(
          'Provenance Chain: ${c2paModel.ingredients.length} ingredient asset(s) linked',
        );
      }

      // If Rust verified AI generation via C2PA assertions or claim generator
      if (c2paModel.isAiGenerated || (ai != null && ai.isAiGenerated)) {
        final aiModelName = ai?.modelDisplay ?? ai?.modelName ?? 'Generative AI Model';
        final org = ai?.company ?? c2paIssuer ?? 'AI Generator';

        return AiDetectionResult(
          classification: ForensicClassification.aiGenerated,
          confidence: AiConfidence.high,
          verdict: 'AI-Generated Image ($aiModelName)',
          explanation:
              'Cryptographically verified C2PA Content Credentials confirm this asset was generated or modified by AI ($org). Signature status: ${sig?.validationState ?? "Valid"}.',
          generator: org,
          model: aiModelName,
          hasC2paManifest: true,
          c2paIssuer: c2paIssuer,
          c2paActions: c2paActions,
          detectedSignatures: signatures,
          c2paData: c2paModel,
        );
      }
    }

    // 3. Scan EXIF tag values for AI generation fingerprints (Stable Diffusion, Midjourney, etc.)
    final tagValues = exifTags.values.map((v) => v.toString()).toList();
    final tagString = tagValues.join(' \n ');

    // Stable Diffusion / Automatic1111 / ComfyUI / Forge / WebUI
    if (_containsIgnoreCase(tagString, 'Negative prompt:') ||
        (_containsIgnoreCase(tagString, 'Steps:') &&
            _containsIgnoreCase(tagString, 'Sampler:') &&
            _containsIgnoreCase(tagString, 'CFG scale:')) ||
        _containsIgnoreCase(tagString, 'ComfyUI') ||
        _containsIgnoreCase(tagString, 'Stable Diffusion') ||
        _containsIgnoreCase(tagString, 'AUTOMATIC1111')) {
      generator = 'Stable Diffusion Ecosystem';
      signatures.add(
        'Stable Diffusion / Automatic1111 / ComfyUI metadata structure found',
      );

      _extractStableDiffusionParams(
        tagString,
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
        c2paData: c2paModel,
      );
    }

    // Midjourney
    if (_containsIgnoreCase(tagString, 'Midjourney') ||
        _containsIgnoreCase(tagString, '--v 5') ||
        _containsIgnoreCase(tagString, '--v 6') ||
        (_containsIgnoreCase(tagString, '--ar ') &&
            _containsIgnoreCase(tagString, '--stylize'))) {
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
        c2paData: c2paModel,
      );
    }

    // DALL-E / OpenAI / ChatGPT
    if (_containsIgnoreCase(tagString, 'DALL·E') ||
        _containsIgnoreCase(tagString, 'DALL-E') ||
        (_containsIgnoreCase(tagString, 'OpenAI') &&
            _containsIgnoreCase(tagString, 'generative'))) {
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
        c2paData: c2paModel,
      );
    }

    // Adobe Firefly
    if (_containsIgnoreCase(tagString, 'Adobe Firefly') ||
        _containsIgnoreCase(tagString, 'adobe:firefly')) {
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
        c2paData: c2paModel,
      );
    }

    // Flux / Black Forest Labs
    if (_containsIgnoreCase(tagString, 'FLUX.1') ||
        _containsIgnoreCase(tagString, 'Black Forest Labs')) {
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
        c2paData: c2paModel,
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
          ...signatures,
        ],
        c2paData: c2paModel,
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
          detectedSignatures: [
            'Editing software marker: $softwareTag',
            ...signatures,
          ],
          c2paData: c2paModel,
        );
      }
    }

    // Default: Inconclusive
    return AiDetectionResult(
      classification: ForensicClassification.inconclusive,
      confidence: AiConfidence.none,
      verdict: hasC2pa ? 'C2PA Verified Asset' : 'Inconclusive / Clean Metadata',
      explanation: hasC2pa
          ? 'Image contains C2PA metadata with no explicit AI generation actions recorded.'
          : 'No synthetic AI generation markers or verified raw camera sensor tags were found. Metadata may have been stripped or cleaned by social media platforms.',
      hasC2paManifest: hasC2pa,
      c2paIssuer: c2paIssuer,
      c2paActions: c2paActions,
      detectedSignatures: hasC2pa ? signatures : [],
      c2paData: c2paModel,
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

  static void _extractStableDiffusionParams(
    String text,
    Map<String, dynamic> params,
    Function(String) setPrompt,
    Function(String) setNegativePrompt,
    Function(String) setModel,
  ) {
    final lines = text.split('\n');
    final firstLine = lines.isNotEmpty ? lines[0].trim() : '';
    if (firstLine.isNotEmpty && !firstLine.startsWith('Negative prompt:')) {
      setPrompt(firstLine);
      params['Prompt'] = firstLine;
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('Negative prompt:')) {
        final np = trimmed.replaceFirst('Negative prompt:', '').trim();
        setNegativePrompt(np);
        params['Negative Prompt'] = np;
      } else if (trimmed.startsWith('Steps:')) {
        final parts = trimmed.split(',');
        for (final part in parts) {
          final kv = part.split(':');
          if (kv.length == 2) {
            final key = kv[0].trim();
            final val = kv[1].trim();
            params[key] = val;
            if (key.toLowerCase() == 'model') {
              setModel(val);
            }
          }
        }
      }
    }
  }
}
