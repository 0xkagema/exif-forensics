enum AiConfidence { high, medium, low, none }

enum ForensicClassification {
  aiGenerated,
  cameraOriginal,
  digitallyEdited,
  inconclusive,
}

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
  });

  bool get isAiGenerated =>
      classification == ForensicClassification.aiGenerated;

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
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
