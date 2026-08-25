import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

enum ForensicsStatus { initial, loading, success, error }

class ForensicsController extends ChangeNotifier {
  ForensicsStatus _status = ForensicsStatus.initial;
  ForensicsReport? _report;
  Uint8List? _imageBytes;
  String? _fileName;
  String? _errorMessage;
  String _loadingStage = 'Initializing analysis...';
  String _searchQuery = '';
  String? _selectedTagCategory;
  int _activeTabIndex = 0;
  bool _isDarkMode = true;

  ForensicsStatus get status => _status;
  ForensicsReport? get report => _report;
  Uint8List? get imageBytes => _imageBytes;
  String? get fileName => _fileName;
  String? get errorMessage => _errorMessage;
  String get loadingStage => _loadingStage;
  String get searchQuery => _searchQuery;
  String? get selectedTagCategory => _selectedTagCategory;
  int get activeTabIndex => _activeTabIndex;
  bool get isDarkMode => _isDarkMode;

  bool get isInitial => _status == ForensicsStatus.initial;
  bool get isLoading => _status == ForensicsStatus.loading;
  bool get isSuccess => _status == ForensicsStatus.success;
  bool get isError => _status == ForensicsStatus.error;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setActiveTab(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedTagCategory(String? category) {
    _selectedTagCategory = category;
    notifyListeners();
  }

  void reset() {
    _status = ForensicsStatus.initial;
    _report = null;
    _imageBytes = null;
    _fileName = null;
    _errorMessage = null;
    _searchQuery = '';
    _selectedTagCategory = null;
    _activeTabIndex = 0;
    notifyListeners();
  }

  Future<void> pickAndAnalyze() async {
    try {
      final fileData = await FileServices.selectImageFile();
      await analyzeBytes(fileData.bytes, fileData.fileName);
    } catch (e) {
      if (e.toString().contains('No file selected')) {
        return;
      }
      _status = ForensicsStatus.error;
      _errorMessage = 'Failed to select image: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> analyzeBytes(Uint8List bytes, String fileName) async {
    _status = ForensicsStatus.loading;
    _imageBytes = bytes;
    _fileName = fileName;
    _errorMessage = null;
    _loadingStage = 'Extracting EXIF metadata & calculating cryptographic hashes...';
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 120));
      _loadingStage = 'Analyzing C2PA signatures & AI provenance patterns...';
      notifyListeners();

      final forensicsReport = await ExifServices.analyzeImageBytes(
        bytes: bytes,
        fileName: fileName,
      );

      _report = forensicsReport;
      _status = ForensicsStatus.success;
      notifyListeners();
    } catch (e) {
      _status = ForensicsStatus.error;
      _errorMessage = 'Error analyzing image: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Returns filtered raw tags based on search query and selected category
  Map<String, dynamic> get filteredRawTags {
    if (_report == null) return {};
    final tags = _report!.rawTags;
    final query = _searchQuery.trim().toLowerCase();
    final category = _selectedTagCategory;

    return Map.fromEntries(
      tags.entries.where((entry) {
        final keyMatches = entry.key.toLowerCase().contains(query);
        final valMatches = entry.value.toString().toLowerCase().contains(query);
        final matchesQuery = query.isEmpty || keyMatches || valMatches;

        if (!matchesQuery) return false;

        if (category == null || category == 'All') return true;
        if (category == 'GPS') return entry.key.startsWith('GPS ');
        if (category == 'Image') return entry.key.startsWith('Image ');
        if (category == 'EXIF') return entry.key.startsWith('EXIF ');
        if (category == 'Interoperability') return entry.key.startsWith('Interoperability ');
        if (category == 'MakerNote') return entry.key.toLowerCase().contains('makernote');
        if (category == 'Thumbnail') return entry.key.startsWith('Thumbnail ');
        return true;
      }),
    );
  }
}
