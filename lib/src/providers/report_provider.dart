import 'package:flutter/material.dart';
import 'package:gov_citizen_app/src/models/report.dart';
import 'package:gov_citizen_app/src/services/report.service.dart';
import 'package:gov_citizen_app/src/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'dart:typed_data';

class EmergencyType {
  final String label;

  final IconData icon;
  EmergencyType(this.label, this.icon);
}

class ProofAttachment {
  final String name;
  final Uint8List bytes;
  final String type; // 'image', 'pdf', etc.
  ProofAttachment({
    required this.name,
    required this.bytes,
    required this.type,
  });
}

class ReportProvider extends ChangeNotifier {
  final ReportService reportService;
  final StorageService _storageService = StorageService();
  ReportProvider(this.reportService);

  List<EmergencyType> emergencyTypes = [
    EmergencyType('Accident', Icons.car_crash),
    EmergencyType('Fire', Icons.local_fire_department),
    EmergencyType('Medical', Icons.medical_services),
    EmergencyType('Flood', Icons.water),
    EmergencyType('Roads', Icons.map),
    EmergencyType('Robbery', Icons.people),
    EmergencyType('Assault', Icons.gavel),
    EmergencyType('Other', Icons.more_horiz),
  ];

  Stream<List<Report>> getReports() {
    return reportService.getReports();
  }

  Future<void> updateReportStatus(String reportId, String newStatus) async {
    await reportService.updateReportStatus(reportId, newStatus);
    notifyListeners();
  }

  EmergencyType? selectedType;
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String? location;
  List<ProofAttachment> proofs = [];
  latlng.LatLng? selectedLatLng;
  String? selectedCity;
  String? selectedArea;

  void selectType(EmergencyType type) {
    selectedType = type;
    notifyListeners();
  }

  void setMapLocation(latlng.LatLng latLng) {
    selectedLatLng = latLng;
    notifyListeners();
  }

  Future<void> setHumanReadableLocation(latlng.LatLng latLng) async {
    try {
      location = 'Fetching address...';
      notifyListeners();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          if (place.name != null && place.name!.isNotEmpty) place.name,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality,
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty)
            place.administrativeArea,
          if (place.country != null && place.country!.isNotEmpty) place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        if (address.isNotEmpty) {
          location = address;
        } else {
          location = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
        }
      } else {
        location = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
      }
      selectedLatLng = latLng;
    } catch (e) {
      location = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
      selectedLatLng = latLng;
    }
    notifyListeners();
  }

  Future<void> useCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await setHumanReadableLocation(
        latlng.LatLng(position.latitude, position.longitude),
      );
    } catch (e) {
      location = 'Failed to get current location: $e';
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      proofs.add(
        ProofAttachment(name: picked.name, bytes: bytes, type: 'image'),
      );
      notifyListeners();
    }
  }

  Future<void> pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      proofs.add(
        ProofAttachment(name: picked.name, bytes: bytes, type: 'video'),
      );
      notifyListeners();
    }
  }

  Future<void> pickAudio() async {
    // TODO: Implement audio picker
    notifyListeners();
  }

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.bytes != null) {
      proofs.add(
        ProofAttachment(
          name: result.files.single.name,
          bytes: result.files.single.bytes!,
          type: 'pdf',
        ),
      );
      notifyListeners();
    }
  }

  Future<void> downloadProof(String path) async {
    if (kIsWeb) {
      await launchUrl(Uri.parse(path));
    } else {
      await OpenFilex.open(path);
    }
  }

  void removeProof(int index) {
    proofs.removeAt(index);
    notifyListeners();
  }

  void selectCity(String? city) {
    selectedCity = city;
    selectedArea = null;
    notifyListeners();
  }

  void selectArea(String? area) {
    selectedArea = area;
    notifyListeners();
  }

  Future<void> submitReport(
    BuildContext context, {
    required String userId,
    required String userName,
  }) async {
    try {
      if (selectedType == null ||
          titleController.text.isEmpty ||
          descriptionController.text.isEmpty ||
          location == null ||
          selectedCity == null ||
          selectedArea == null) {
        throw Exception('Please fill all required fields.');
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading report...')));

      List<String> attachmentUrls = [];
      for (var proof in proofs) {
        final url = await _storageService.uploadBytes(
          proof.bytes,
          proof.name,
          'reports',
        );
        attachmentUrls.add(url);
      }

      await reportService.submitReport(
        emergencyType: selectedType!.label,
        location: location!,
        details: descriptionController.text,
        attachments: attachmentUrls,
        audioPath: null,
        userId: userId,
        userName: userName,
        city: selectedCity!,
        area: selectedArea!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully!')),
      );

      // Clear form
      selectedType = null;
      titleController.clear();
      descriptionController.clear();
      location = null;
      proofs.clear();
      selectedLatLng = null;
      selectedCity = null;
      selectedArea = null;
      notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: ${e.toString()}')),
      );
    }
  }

  // Analytics: Get report counts by city
  Future<Map<String, int>> getReportCountsByCity() async {
    final reports = await reportService.getReports().first;
    final Map<String, int> counts = {};
    for (final report in reports) {
      counts[report.city] = (counts[report.city] ?? 0) + 1;
    }
    return counts;
  }

  // Analytics: Get report counts by area for a given city
  Future<Map<String, int>> getReportCountsByArea(String city) async {
    final reports = await reportService.getReports().first;
    final Map<String, int> counts = {};
    for (final report in reports.where((r) => r.city == city)) {
      counts[report.area] = (counts[report.area] ?? 0) + 1;
    }
    return counts;
  }
}
