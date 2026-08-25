import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:exif/exif.dart';
import 'package:exifapp/core/services/exif.dart';
import 'package:exifapp/core/services/files.dart';
import 'package:exifapp/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:toastification/toastification.dart';

import 'core/models/models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ToastificationWrapper(
      config: ToastificationConfig(alignment: Alignment.bottomCenter),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ExifApp(),
        theme: AppTheme.lightTheme.copyWith(
          extensions: [AppThemeExtension.light],
        ),

        darkTheme: AppTheme.darkTheme.copyWith(
          extensions: [AppThemeExtension.dark],
        ),
      ),
    ),
  );
}

class ExifApp extends StatefulWidget {
  const ExifApp({super.key});

  @override
  State<ExifApp> createState() => _ExifAppState();
}

class _ExifAppState extends State<ExifApp> {
  bool _isDragging = false;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : DropTarget(
                onDragDone: (detail) async {
                  if (detail.files.length > 1) {
                    toastification.show(
                      title: Text("Error"),
                      description: Text("Only one file is allowed"),
                      type: ToastificationType.error,
                    );
                    return;
                  }
                  if (detail.files.isEmpty) {
                    toastification.show(
                      title: Text("Error"),
                      description: Text("You have not selected any file"),
                      type: ToastificationType.error,
                    );
                    return;
                  }

                  setState(() {
                    _isLoading = true;
                  });

                  var bytes = await detail.files.first.readAsBytes();
                  var data = await ExifServices.readExifData(bytes);
                  setState(() {
                    _isLoading = false;
                  });
                  _showExifResults(data);
                },
                onDragEntered: (detail) {
                  setState(() {
                    _isDragging = true;
                  });
                },
                onDragExited: (detail) {
                  setState(() {
                    _isDragging = false;
                  });
                },
                child: DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    dashPattern: [10, 7],
                    strokeWidth: 3,
                    color: _isDragging ? Colors.green : Colors.blueGrey,
                    radius: Radius.circular(10),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    height: 300,
                    width: 400,

                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Select or drag and drop file here to extract EXIF data",
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              setState(() {
                                _isLoading = true;
                              });
                              try {
                                var bytes =
                                    await FileServices.selectImageFileAndReturnBytes();
                                final data = await ExifServices.readExifData(
                                  bytes,
                                );

                                _showExifResults(data);
                              } catch (e) {
                                toastification.show(
                                  title: Text("Error"),
                                  type: ToastificationType.error,
                                  description: Text(e.toString()),
                                );
                              } finally {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            },
                            icon: Icon(Icons.upload_file),
                            label: Text("Select File"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  double dmsToDecimal(
    int degrees,
    int minutes,
    double seconds,
    String direction,
  ) {
    double decimal = degrees + (minutes / 60) + (seconds / 3600);

    if (direction == 'S' || direction == 'W') {
      decimal *= -1;
    }

    return decimal;
  }

  PhotoLocation? extractLocation(Map<String, dynamic> exif) {
    final latTag = exif['GPS GPSLatitude'] as IfdTag?;
    final latRefTag = exif['GPS GPSLatitudeRef'] as IfdTag?;

    final lngTag = exif['GPS GPSLongitude'] as IfdTag?;
    final lngRefTag = exif['GPS GPSLongitudeRef'] as IfdTag?;

    if (latTag == null ||
        latRefTag == null ||
        lngTag == null ||
        lngRefTag == null) {
      return null;
    }

    final lat = parseExifCoordinate(latTag.printable, latRefTag.printable);

    final lng = parseExifCoordinate(lngTag.printable, lngRefTag.printable);

    return PhotoLocation(latitude: lat, longitude: lng);
  }

  double parseExifCoordinate(String value, String ref) {
    // Remove brackets
    value = value.replaceAll('[', '').replaceAll(']', '');

    final parts = value.split(',');

    final degrees = int.parse(parts[0].trim());
    final minutes = int.parse(parts[1].trim());

    final secParts = parts[2].trim().split('/');
    final seconds = double.parse(secParts[0]) / double.parse(secParts[1]);

    return dmsToDecimal(degrees, minutes, seconds, ref);
  }

  void _showExifResults(Map<String, dynamic> data) {
    bool hasGpsData = data.containsKey('GPS GPSLongitude');

    /* */

    // display modal with the data as a table
    showDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text("EXIF Data"),
        content: SizedBox(
          width: 500,
          height: 500,
          child: ListView(
            children: data.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                subtitle: SelectableText(entry.value.toString()),
                trailing: hasGpsData && entry.key == 'GPS GPSLongitude'
                    ? IconButton(
                        onPressed: () async {
                          PhotoLocation location = extractLocation(data)!;

                          Navigator.pop(context);
                          _showPictureLocation(location);
                        },
                        icon: Icon(Icons.map),
                      )
                    : null,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPictureLocation(PhotoLocation loc) async {
    final mapController = MapController.withPosition(
      initPosition: GeoPoint(latitude: loc.latitude, longitude: loc.longitude),
    );

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
          title: Text('Photo Location'),
          content: SizedBox(
            width: 700,
            height: 500,
            child: OSMFlutter(
              controller: mapController,
              osmOption: const OSMOption(zoomOption: ZoomOption(initZoom: 16)),
              onMapIsReady: (ready) async {
                if (ready) {
                  await mapController.addMarker(
                    GeoPoint(latitude: loc.latitude, longitude: loc.longitude),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
