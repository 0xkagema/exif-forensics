class DeviceDetails {
  final String? manufacturer;
  final String? model;
  final String? softwareVersion;
  final String? lensMake;
  final String? lensModel;
  final String? lensSpecification;
  final String? cameraOwner;
  final String? bodySerialNumber;
  final String? lensSerialNumber;
  final String? artist;
  final String? copyright;

  const DeviceDetails({
    this.manufacturer,
    this.model,
    this.softwareVersion,
    this.lensMake,
    this.lensModel,
    this.lensSpecification,
    this.cameraOwner,
    this.bodySerialNumber,
    this.lensSerialNumber,
    this.artist,
    this.copyright,
  });

  String get displayName {
    final mfg = manufacturer?.trim() ?? '';
    final mdl = model?.trim() ?? '';
    if (mfg.isEmpty && mdl.isEmpty) return 'Unknown Device';
    if (mdl.toLowerCase().contains(mfg.toLowerCase())) return mdl;
    if (mfg.isNotEmpty && mdl.isNotEmpty) return '$mfg $mdl';
    return mfg.isNotEmpty ? mfg : mdl;
  }

  bool get hasDeviceData =>
      (manufacturer?.isNotEmpty ?? false) ||
      (model?.isNotEmpty ?? false) ||
      (softwareVersion?.isNotEmpty ?? false) ||
      (lensModel?.isNotEmpty ?? false) ||
      (bodySerialNumber?.isNotEmpty ?? false) ||
      (artist?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'manufacturer': manufacturer,
      'model': model,
      'softwareVersion': softwareVersion,
      'lensMake': lensMake,
      'lensModel': lensModel,
      'lensSpecification': lensSpecification,
      'cameraOwner': cameraOwner,
      'bodySerialNumber': bodySerialNumber,
      'lensSerialNumber': lensSerialNumber,
      'artist': artist,
      'copyright': copyright,
      'displayName': displayName,
    };
  }
}
