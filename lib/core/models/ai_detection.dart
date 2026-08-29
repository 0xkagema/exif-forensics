import 'dart:convert';

enum AiConfidence { high, medium, low, none }

enum ForensicClassification {
  aiGenerated,
  cameraOriginal,
  digitallyEdited,
  inconclusive,
}

/// Extracted AI details from C2PA metadata and actions.
class C2paAiDetails {
  final bool isAiGenerated;
  final String? modelName;
  final String? modelVersion;
  final String? modelDisplay;
  final String? company;
  final String? digitalSourceType;
  final String? generationTime;
  final String? generationDate;
  final String? softwareAgent;
  final String? claimGenerator;
  final String? generatorApp;

  const C2paAiDetails({
    this.isAiGenerated = false,
    this.modelName,
    this.modelVersion,
    this.modelDisplay,
    this.company,
    this.digitalSourceType,
    this.generationTime,
    this.generationDate,
    this.softwareAgent,
    this.claimGenerator,
    this.generatorApp,
  });

  factory C2paAiDetails.fromJson(Map<String, dynamic> json) {
    return C2paAiDetails(
      isAiGenerated: json['is_ai_generated'] == true,
      modelName: json['model_name'] as String?,
      modelVersion: json['model_version'] as String?,
      modelDisplay: json['model_display'] as String?,
      company: json['company'] as String?,
      digitalSourceType: json['digital_source_type'] as String?,
      generationTime: json['generation_time'] as String?,
      generationDate: json['generation_date'] as String?,
      softwareAgent: json['software_agent'] as String?,
      claimGenerator: json['claim_generator'] as String?,
      generatorApp: json['generator_app'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_ai_generated': isAiGenerated,
      'model_name': modelName,
      'model_version': modelVersion,
      'model_display': modelDisplay,
      'company': company,
      'digital_source_type': digitalSourceType,
      'generation_time': generationTime,
      'generation_date': generationDate,
      'software_agent': softwareAgent,
      'claim_generator': claimGenerator,
      'generator_app': generatorApp,
    };
  }
}

/// Certificate, issuer, and signature details from C2PA manifest.
class C2paSignatureDetails {
  final String? issuer;
  final String? commonName;
  final String? algorithm;
  final String? signingTime;
  final String? certSerialNumber;
  final String? validationState;
  final bool isSignatureValid;
  final bool isTrusted;

  const C2paSignatureDetails({
    this.issuer,
    this.commonName,
    this.algorithm,
    this.signingTime,
    this.certSerialNumber,
    this.validationState,
    this.isSignatureValid = false,
    this.isTrusted = false,
  });

  factory C2paSignatureDetails.fromJson(Map<String, dynamic> json) {
    return C2paSignatureDetails(
      issuer: json['issuer'] as String?,
      commonName: json['common_name'] as String?,
      algorithm: json['algorithm'] as String?,
      signingTime: json['signing_time'] as String?,
      certSerialNumber: json['cert_serial_number'] as String?,
      validationState: json['validation_state'] as String?,
      isSignatureValid: json['is_signature_valid'] == true,
      isTrusted: json['is_trusted'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'issuer': issuer,
      'common_name': commonName,
      'algorithm': algorithm,
      'signing_time': signingTime,
      'cert_serial_number': certSerialNumber,
      'validation_state': validationState,
      'is_signature_valid': isSignatureValid,
      'is_trusted': isTrusted,
    };
  }
}

/// Active or ingredient manifest summary.
class C2paManifestSummary {
  final String? label;
  final String? title;
  final String? format;
  final String? instanceId;
  final int? claimVersion;
  final String? claimGenerator;

  const C2paManifestSummary({
    this.label,
    this.title,
    this.format,
    this.instanceId,
    this.claimVersion,
    this.claimGenerator,
  });

  factory C2paManifestSummary.fromJson(Map<String, dynamic> json) {
    return C2paManifestSummary(
      label: json['label'] as String?,
      title: json['title'] as String?,
      format: json['format'] as String?,
      instanceId: json['instance_id'] as String?,
      claimVersion: (json['claim_version'] as num?)?.toInt(),
      claimGenerator: json['claim_generator'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'title': title,
      'format': format,
      'instance_id': instanceId,
      'claim_version': claimVersion,
      'claim_generator': claimGenerator,
    };
  }
}

/// Ingredient asset summary in provenance chain.
class C2paIngredientSummary {
  final String? label;
  final String? title;
  final String? format;
  final String? instanceId;
  final String? claimGenerator;
  final bool isAiGenerated;
  final String? aiModel;

  const C2paIngredientSummary({
    this.label,
    this.title,
    this.format,
    this.instanceId,
    this.claimGenerator,
    this.isAiGenerated = false,
    this.aiModel,
  });

  factory C2paIngredientSummary.fromJson(Map<String, dynamic> json) {
    return C2paIngredientSummary(
      label: json['label'] as String?,
      title: json['title'] as String?,
      format: json['format'] as String?,
      instanceId: json['instance_id'] as String?,
      claimGenerator: json['claim_generator'] as String?,
      isAiGenerated: json['is_ai_generated'] == true,
      aiModel: json['ai_model'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'title': title,
      'format': format,
      'instance_id': instanceId,
      'claim_generator': claimGenerator,
      'is_ai_generated': isAiGenerated,
      'ai_model': aiModel,
    };
  }
}

/// Description of a single action in the C2PA provenance history.
class C2paActionSummary {
  final String action;
  final String? when;
  final String? softwareAgent;
  final String? softwareAgentName;
  final String? softwareAgentVersion;
  final String? digitalSourceType;
  final bool isAiAction;
  final String? manifestLabel;
  final String? description;

  const C2paActionSummary({
    required this.action,
    this.when,
    this.softwareAgent,
    this.softwareAgentName,
    this.softwareAgentVersion,
    this.digitalSourceType,
    this.isAiAction = false,
    this.manifestLabel,
    this.description,
  });

  factory C2paActionSummary.fromJson(Map<String, dynamic> json) {
    return C2paActionSummary(
      action: json['action']?.toString() ?? 'c2pa.unknown',
      when: json['when'] as String?,
      softwareAgent: json['software_agent'] as String?,
      softwareAgentName: json['software_agent_name'] as String?,
      softwareAgentVersion: json['software_agent_version'] as String?,
      digitalSourceType: json['digital_source_type'] as String?,
      isAiAction: json['is_ai_action'] == true,
      manifestLabel: json['manifest_label'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'when': when,
      'software_agent': softwareAgent,
      'software_agent_name': softwareAgentName,
      'software_agent_version': softwareAgentVersion,
      'digital_source_type': digitalSourceType,
      'is_ai_action': isAiAction,
      'manifest_label': manifestLabel,
      'description': description,
    };
  }
}

/// Single validation status log entry.
class C2paValidationEntry {
  final String code;
  final String explanation;
  final String? url;

  const C2paValidationEntry({
    required this.code,
    required this.explanation,
    this.url,
  });

  factory C2paValidationEntry.fromJson(Map<String, dynamic> json) {
    return C2paValidationEntry(
      code: json['code']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'explanation': explanation,
      'url': url,
    };
  }
}

/// Detailed validation findings for cryptographic signatures and trust chains.
class C2paValidationSummary {
  final String state;
  final bool isValid;
  final bool isTrusted;
  final List<C2paValidationEntry> successes;
  final List<C2paValidationEntry> informational;
  final List<C2paValidationEntry> failures;

  const C2paValidationSummary({
    this.state = 'Unknown',
    this.isValid = false,
    this.isTrusted = false,
    this.successes = const [],
    this.informational = const [],
    this.failures = const [],
  });

  factory C2paValidationSummary.fromJson(Map<String, dynamic> json) {
    return C2paValidationSummary(
      state: json['state']?.toString() ?? 'Unknown',
      isValid: json['is_valid'] == true,
      isTrusted: json['is_trusted'] == true,
      successes: (json['successes'] as List<dynamic>?)
              ?.map((e) => C2paValidationEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      informational: (json['informational'] as List<dynamic>?)
              ?.map((e) => C2paValidationEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      failures: (json['failures'] as List<dynamic>?)
              ?.map((e) => C2paValidationEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'state': state,
      'is_valid': isValid,
      'is_trusted': isTrusted,
      'successes': successes.map((e) => e.toMap()).toList(),
      'informational': informational.map((e) => e.toMap()).toList(),
      'failures': failures.map((e) => e.toMap()).toList(),
    };
  }
}

/// Full parsed response from the Rust C2PA engine.
class C2paResponseModel {
  final bool success;
  final bool hasC2pa;
  final String? message;
  final String? error;
  final String? format;
  final bool isAiGenerated;
  final C2paAiDetails? aiDetails;
  final C2paSignatureDetails? signature;
  final C2paManifestSummary? manifest;
  final List<C2paIngredientSummary> ingredients;
  final List<C2paActionSummary> actions;
  final C2paValidationSummary? validation;
  final Map<String, dynamic>? rawManifest;

  const C2paResponseModel({
    this.success = false,
    this.hasC2pa = false,
    this.message,
    this.error,
    this.format,
    this.isAiGenerated = false,
    this.aiDetails,
    this.signature,
    this.manifest,
    this.ingredients = const [],
    this.actions = const [],
    this.validation,
    this.rawManifest,
  });

  factory C2paResponseModel.fromJson(Map<String, dynamic> json) {
    return C2paResponseModel(
      success: json['success'] == true,
      hasC2pa: json['has_c2pa'] == true,
      message: json['message'] as String?,
      error: json['error'] as String?,
      format: json['format'] as String?,
      isAiGenerated: json['is_ai_generated'] == true,
      aiDetails: json['ai_details'] != null
          ? C2paAiDetails.fromJson(json['ai_details'] as Map<String, dynamic>)
          : null,
      signature: json['signature'] != null
          ? C2paSignatureDetails.fromJson(
              json['signature'] as Map<String, dynamic>)
          : null,
      manifest: json['manifest'] != null
          ? C2paManifestSummary.fromJson(
              json['manifest'] as Map<String, dynamic>)
          : null,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) =>
                  C2paIngredientSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => C2paActionSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      validation: json['validation'] != null
          ? C2paValidationSummary.fromJson(
              json['validation'] as Map<String, dynamic>)
          : null,
      rawManifest: json['raw_manifest'] as Map<String, dynamic>?,
    );
  }

  factory C2paResponseModel.fromRawJson(String rawJson) {
    try {
      final decoded = json.decode(rawJson) as Map<String, dynamic>;
      return C2paResponseModel.fromJson(decoded);
    } catch (e) {
      return C2paResponseModel(
        success: false,
        hasC2pa: false,
        error: 'JSON decode error: $e',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'has_c2pa': hasC2pa,
      'message': message,
      'error': error,
      'format': format,
      'is_ai_generated': isAiGenerated,
      'ai_details': aiDetails?.toMap(),
      'signature': signature?.toMap(),
      'manifest': manifest?.toMap(),
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
      'actions': actions.map((e) => e.toMap()).toList(),
      'validation': validation?.toMap(),
      'raw_manifest': rawManifest,
    };
  }
}

/// Unified AI and Provenance Forensics detection result.
class AiDetectionResult {
  final ForensicClassification classification;
  final AiConfidence confidence;
  final String verdict;
  final String explanation;
  final String? generator;
  final String? model;
  final String? prompt;
  final String? negativePrompt;
  final Map<String, dynamic> generationParameters;
  final bool hasC2paManifest;
  final String? c2paIssuer;
  final List<String> c2paActions;
  final List<String> detectedSignatures;

  // Rich C2PA Data from Rust
  final C2paResponseModel? c2paData;

  const AiDetectionResult({
    required this.classification,
    required this.confidence,
    required this.verdict,
    required this.explanation,
    this.generator,
    this.model,
    this.prompt,
    this.negativePrompt,
    this.generationParameters = const {},
    this.hasC2paManifest = false,
    this.c2paIssuer,
    this.c2paActions = const [],
    this.detectedSignatures = const [],
    this.c2paData,
  });

  C2paAiDetails? get c2paAiDetails => c2paData?.aiDetails;
  C2paSignatureDetails? get c2paSignature => c2paData?.signature;
  C2paManifestSummary? get c2paManifest => c2paData?.manifest;
  List<C2paIngredientSummary> get c2paIngredients =>
      c2paData?.ingredients ?? const [];
  List<C2paActionSummary> get c2paActionSummaries =>
      c2paData?.actions ?? const [];
  C2paValidationSummary? get c2paValidation => c2paData?.validation;
  Map<String, dynamic>? get c2paRawManifest => c2paData?.rawManifest;

  String get confidenceLabel {
    switch (confidence) {
      case AiConfidence.high:
        return 'High Confidence';
      case AiConfidence.medium:
        return 'Moderate Confidence';
      case AiConfidence.low:
        return 'Low Confidence';
      case AiConfidence.none:
        return 'Not Applicable';
    }
  }

  bool get isAiGenerated =>
      classification == ForensicClassification.aiGenerated;

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'classification': classification.name,
      'confidence': confidence.name,
      'verdict': verdict,
      'explanation': explanation,
      'generator': generator,
      'model': model,
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'generationParameters': generationParameters,
      'hasC2paManifest': hasC2paManifest,
      'c2paIssuer': c2paIssuer,
      'c2paActions': c2paActions,
      'detectedSignatures': detectedSignatures,
      'c2paData': c2paData?.toMap(),
    };
  }
}
