# EXIF Forensics

A lightweight Flutter desktop/web application for extracting and analyzing EXIF metadata from images.

EXIF Forensics helps investigators, photographers, journalists, OSINT researchers, and curious users inspect metadata embedded inside images and visualize GPS locations directly on an interactive OpenStreetMap.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Desktop-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## Features

### Current Features

- Drag and drop image support
- File picker image selection
- EXIF metadata extraction
- Load Images from remote sources
- Display all available EXIF tags
- GPS coordinate extraction
- Automatic DMS → Decimal coordinate conversion
- Interactive OpenStreetMap integration
- GPS location visualization with map markers

### Example Metadata

```text
Image Model: Nokia C22
Image Make: HMD Global
Image Software: 00WW_2_470
EXIF DateTimeOriginal: 2025:07:08 13:17:10
GPS GPSLatitude: [1, 14, 549/50]
GPS GPSLongitude: [36, 33, 59/10]
```

---

## How It Works

### 1. Select an Image

Users can:

- Drag and drop an image
- Select an image using the file picker

### 2. Extract Metadata

The application reads EXIF metadata using the `exif` package.

Example:

```text
GPS GPSLatitude: [1, 14, 549/50]
GPS GPSLatitudeRef: S

GPS GPSLongitude: [36, 33, 59/10]
GPS GPSLongitudeRef: E
```

### 3. Convert Coordinates

EXIF stores GPS coordinates in Degrees, Minutes, Seconds (DMS).

Example:

```text
1° 12' 10.98" S
36° 55' 5.9" E
```

Converted into:

```text
Latitude:  -1.202883
Longitude: 36.918306
```

### 4. Display on Map

The coordinates are displayed using OpenStreetMap

---

## Installation

### Clone the Repository

```bash
git clone https://github.com/kagemanjoroge/exif-forensics.git

cd exif-forensics
```

### Install Dependencies

```bash
flutter pub get
```

### Run

#### Web

```bash
flutter run -d chrome
```

## Supported Metadata

The application currently displays any EXIF tag returned by the image.

Common examples include:

### Camera Information

- Device Manufacturer
- Device Model
- Software Version

### Image Information

- Orientation
- Resolution
- Color Space

### Photography Information

- ISO
- Aperture (F-Number)
- Exposure Time
- Focal Length
- White Balance
- Flash Status

### GPS Information

- Latitude
- Longitude
- Date Captured
- GPS Timestamp
