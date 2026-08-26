class PhotographyDetails {
  final String? iso;
  final String? exposureTime;
  final String? fNumber;
  final String? shutterSpeed;
  final String? focalLength;
  final String? focalLength35mm;
  final String? exposureProgram;
  final String? exposureBias;
  final String? meteringMode;
  final String? flash;
  final String? whiteBalance;
  final String? colorSpace;
  final String? orientation;
  final int? imageWidth;
  final int? imageHeight;
  final String? xResolution;
  final String? yResolution;
  final String? resolutionUnit;
  final String? contrast;
  final String? saturation;
  final String? sharpness;
  final String? digitalZoomRatio;
  final String? sceneCaptureType;
  final String? lightSource;
  final String? sensingMethod;

  const PhotographyDetails({
    this.iso,
    this.exposureTime,
    this.fNumber,
    this.shutterSpeed,
    this.focalLength,
    this.focalLength35mm,
    this.exposureProgram,
    this.exposureBias,
    this.meteringMode,
    this.flash,
    this.whiteBalance,
    this.colorSpace,
    this.orientation,
    this.imageWidth,
    this.imageHeight,
    this.xResolution,
    this.yResolution,
    this.resolutionUnit,
    this.contrast,
    this.saturation,
    this.sharpness,
    this.digitalZoomRatio,
    this.sceneCaptureType,
    this.lightSource,
    this.sensingMethod,
  });

  bool get hasPhotoData =>
      iso != null ||
      exposureTime != null ||
      fNumber != null ||
      focalLength != null ||
      flash != null ||
      whiteBalance != null;

  String get resolutionString {
    if (imageWidth != null && imageHeight != null) {
      final mp = ((imageWidth! * imageHeight!) / 1000000).toStringAsFixed(1);
      return '$imageWidth × $imageHeight (${mp}MP)';
    }
    return 'Unknown';
  }

  Map<String, dynamic> toMap() {
    return {
      'iso': iso,
      'exposureTime': exposureTime,
      'fNumber': fNumber,
      'shutterSpeed': shutterSpeed,
      'focalLength': focalLength,
      'focalLength35mm': focalLength35mm,
      'exposureProgram': exposureProgram,
      'exposureBias': exposureBias,
      'meteringMode': meteringMode,
      'flash': flash,
      'whiteBalance': whiteBalance,
      'colorSpace': colorSpace,
      'orientation': orientation,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'resolution': resolutionString,
      'xResolution': xResolution,
      'yResolution': yResolution,
      'resolutionUnit': resolutionUnit,
      'contrast': contrast,
      'saturation': saturation,
      'sharpness': sharpness,
      'digitalZoomRatio': digitalZoomRatio,
      'sceneCaptureType': sceneCaptureType,
      'lightSource': lightSource,
      'sensingMethod': sensingMethod,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
