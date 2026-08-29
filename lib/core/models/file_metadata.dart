class FileMetadata {
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String md5Hash;
  final String sha256Hash;
  final int? width;
  final int? height;

  const FileMetadata({
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.md5Hash,
    required this.sha256Hash,
    this.width,
    this.height,
  });

  String get dimensionsString {
    if (width != null && height != null) {
      return '$width x $height px';
    }
    return 'Unknown';
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'formattedSize': formattedSize,
      'mimeType': mimeType,
      'md5Hash': md5Hash,
      'sha256Hash': sha256Hash,
      'width': width,
      'height': height,
      'dimensions': dimensionsString,
    };
  }
}
