class PhotoLocation {
  final double latitude;
  final double longitude;
  final double? altitude;
  final String latitudeDms;
  final String longitudeDms;
  final String? gpsDateStamp;
  final String? gpsTimeStamp;
  final double? speed;
  final double? imgDirection;
  final String? mapDatum;

  const PhotoLocation({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.latitudeDms = '',
    this.longitudeDms = '',
    this.gpsDateStamp,
    this.gpsTimeStamp,
    this.speed,
    this.imgDirection,
    this.mapDatum,
  });

  String get formattedDecimal =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get formattedDms {
    if (latitudeDms.isNotEmpty && longitudeDms.isNotEmpty) {
      return '$latitudeDms, $longitudeDms';
    }
    return formattedDecimal;
  }

  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  String get openStreetMapUrl =>
      'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=16/$latitude/$longitude';

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'latitudeDms': latitudeDms,
      'longitudeDms': longitudeDms,
      'gpsDateStamp': gpsDateStamp,
      'gpsTimeStamp': gpsTimeStamp,
      'speed': speed,
      'imgDirection': imgDirection,
      'mapDatum': mapDatum,
      'googleMapsUrl': googleMapsUrl,
      'openStreetMapUrl': openStreetMapUrl,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

