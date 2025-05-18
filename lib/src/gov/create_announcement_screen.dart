import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../services/posts.service.dart';
import '../services/auth.service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geocoding/geocoding.dart';
import '../data/egypt_locations.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  String _location = '';
  bool _isLoading = false;
  List<Attachment> _attachments = [];
  String? _selectedCity;
  String? _selectedArea;
  List<String> _availableAreas = [];

  @override
  void initState() {
    super.initState();
    _initializeLocations();
  }

  void _initializeLocations() {
    if (_selectedCity != null) {
      _availableAreas = getAreasForCity(_selectedCity!);
    }
  }

  void _onCityChanged(String? newCity) {
    setState(() {
      _selectedCity = newCity;
      _availableAreas = newCity != null ? getAreasForCity(newCity) : [];
      _selectedArea = null; // Reset area when city changes
      _updateLocation();
    });
  }

  void _onAreaChanged(String? newArea) {
    setState(() {
      _selectedArea = newArea;
      _updateLocation();
    });
  }

  void _updateLocation() {
    if (_selectedCity != null && _selectedArea != null) {
      setState(() {
        _location = '$_selectedCity, $_selectedArea';
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _changeLocation() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Location'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // City Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  hint: const Text('Select City'),
                  isExpanded: true,
                  items:
                      getAllCities()
                          .map(
                            (city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ),
                          )
                          .toList(),
                  onChanged: _onCityChanged,
                ),
                const SizedBox(height: 16),
                // Area Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedArea,
                  hint: const Text('Select Area'),
                  isExpanded: true,
                  items:
                      _availableAreas
                          .map(
                            (area) => DropdownMenuItem(
                              value: area,
                              child: Text(area),
                            ),
                          )
                          .toList(),
                  onChanged: _onAreaChanged,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_selectedCity != null && _selectedArea != null) {
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select both city and area'),
                      ),
                    );
                  }
                },
                child: const Text('Select'),
              ),
            ],
          ),
    );
  }

  Future<void> _pickAttachment(String type) async {
    try {
      setState(() => _isLoading = true);

      if (type == 'Click Pictures') {
        final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          final ref = FirebaseStorage.instance
              .ref()
              .child('attachments')
              .child(
                '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}',
              );

          await ref.putData(bytes);
          final url = await ref.getDownloadURL();

          setState(() {
            _attachments.add(
              Attachment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: pickedFile.name,
                url: url,
                type: 'image',
              ),
            );
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Image "${pickedFile.name}" uploaded successfully',
                ),
              ),
            );
          }
        }
      } else if (type == 'PDF') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null && result.files.single.bytes != null) {
          final file = result.files.single;
          final ref = FirebaseStorage.instance
              .ref()
              .child('attachments')
              .child('${DateTime.now().millisecondsSinceEpoch}_${file.name}');

          await ref.putData(file.bytes!);
          final url = await ref.getDownloadURL();

          setState(() {
            _attachments.add(
              Attachment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: file.name,
                url: url,
                type: 'pdf',
              ),
            );
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF "${file.name}" uploaded successfully'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading attachment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createAnnouncement() async {
    if (_descController.text.trim().isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter description and select date.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      await PostsService().createAnnouncement(
        title: 'Announcement',
        content: _descController.text.trim(),
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Admin',
        userRole: 'gov_admin',
        attachments: _attachments,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder:
            (context, scrollController) => Material(
              color: Colors.transparent,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        TextField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: 'Announcement Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Select date',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Date',
                                hintText: 'mm/dd/yyyy',
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              controller: TextEditingController(
                                text:
                                    _selectedDate == null
                                        ? ''
                                        : DateFormat(
                                          'MM/dd/yyyy',
                                        ).format(_selectedDate!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Location', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _location.isEmpty
                                    ? 'Select a location'
                                    : _location,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            TextButton(
                              onPressed: _changeLocation,
                              child: const Text(
                                'Change',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        const Text(
                          'Attachments (optional)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _AttachmentButton(
                              icon: Icons.camera_alt,
                              label: 'Click Pictures',
                              onTap:
                                  _isLoading
                                      ? null
                                      : () => _pickAttachment('Click Pictures'),
                              color: Colors.red,
                            ),
                            _AttachmentButton(
                              icon: Icons.picture_as_pdf,
                              label: 'PDF',
                              onTap:
                                  _isLoading
                                      ? null
                                      : () => _pickAttachment('PDF'),
                              color: Colors.red,
                            ),
                          ],
                        ),
                        if (_attachments.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Selected Attachments:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._attachments.map(
                            (attachment) => ListTile(
                              leading: Icon(
                                attachment.type == 'image'
                                    ? Icons.image
                                    : Icons.picture_as_pdf,
                                color: Colors.red,
                              ),
                              title: Text(attachment.name),
                              subtitle: Text(attachment.type),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () {
                                          setState(() {
                                            _attachments.removeWhere(
                                              (a) => a.id == attachment.id,
                                            );
                                          });
                                        },
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createAnnouncement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text('Create Announcement'),
                          ),
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
}

class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, color: color, size: 32), onPressed: onTap),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

class FlutterMapLocationPickerDialog extends StatefulWidget {
  final latlng.LatLng initialLocation;
  const FlutterMapLocationPickerDialog({
    super.key,
    required this.initialLocation,
  });

  @override
  State<FlutterMapLocationPickerDialog> createState() =>
      _FlutterMapLocationPickerDialogState();
}

class _FlutterMapLocationPickerDialogState
    extends State<FlutterMapLocationPickerDialog> {
  late latlng.LatLng _selectedLocation;
  final MapController _mapController = MapController();

  Future<void> _findMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newLocation = latlng.LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLocation;
      });
      _mapController.move(newLocation, 13.0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get current location: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select Location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _findMyLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Find My Location'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _selectedLocation,
                    zoom: 13.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: _selectedLocation,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedLocation);
                  },
                  child: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ManualLocationDialog extends StatefulWidget {
  @override
  State<ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final latController = TextEditingController();
  final lngController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: latController,
            decoration: InputDecoration(labelText: 'Latitude'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: lngController,
            decoration: InputDecoration(labelText: 'Longitude'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final lat = double.tryParse(latController.text);
            final lng = double.tryParse(lngController.text);
            if (lat != null && lng != null) {
              Navigator.pop(context, {'lat': lat, 'lng': lng});
            }
          },
          child: Text('Select'),
        ),
      ],
    );
  }
}
