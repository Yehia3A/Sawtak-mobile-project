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
import 'package:provider/provider.dart';
import '../providers/announcement_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _descController = TextEditingController();
  LatLng? _selectedLocation;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _setHumanReadableLocation(
    LatLng latLng,
    AnnouncementProvider provider,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final location = [
          if (place.name != null && place.name!.isNotEmpty) place.name,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality,
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty)
            place.administrativeArea,
          if (place.country != null && place.country!.isNotEmpty) place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        provider.setLocation(location);
      } else {
        provider.setLocation(
          'Lat:  2${latLng.latitude}, Lng: ${latLng.longitude}',
        );
      }
    } catch (e) {
      provider.setLocation('Lat: ${latLng.latitude}, Lng: ${latLng.longitude}');
    }
  }

  Future<void> _changeLocation(AnnouncementProvider provider) async {
    final selectedLocation = await showDialog<latlng.LatLng>(
      context: context,
      builder:
          (context) => FlutterMapLocationPickerDialog(
            initialLocation:
                _selectedLocation ?? latlng.LatLng(24.7136, 46.6753),
          ),
    );
    if (selectedLocation != null) {
      setState(() {
        _selectedLocation = selectedLocation;
      });
      await _setHumanReadableLocation(
        LatLng(selectedLocation.latitude, selectedLocation.longitude),
        provider,
      );
    }
  }

  Future<void> _pickAttachment(
    String type,
    AnnouncementProvider provider,
  ) async {
    try {
      if (type == 'Click Pictures') {
        final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (pickedFile != null) {
          final id = 'pending_${DateTime.now().millisecondsSinceEpoch}';
          final pending = Attachment(
            id: id,
            name: pickedFile.name,
            url: '',
            type: 'image',
            isPending: true,
            progress: 0.0,
          );
          provider.addPendingAttachment(pending);
          final bytes = await pickedFile.readAsBytes();
          String fileName =
              DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: <String, String>{
              'Content-Disposition': 'inline',
              'Cache-Control': 'public, max-age=31536000',
              'Access-Control-Allow-Origin': '*',
            },
          );
          final ref = FirebaseStorage.instance.ref().child(
            'attachments/$fileName',
          );
          final uploadTask = ref.putData(bytes, metadata);
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            print('Upload state: ${snapshot.state}');
            print('Bytes transferred: ${snapshot.bytesTransferred}');
            print('Total bytes: ${snapshot.totalBytes}');
            final progress =
                snapshot.bytesTransferred /
                (snapshot.totalBytes == 0 ? 1 : snapshot.totalBytes);
            provider.updatePendingAttachmentProgress(id, progress);
          });
          final snapshot = await uploadTask;
          final url = await snapshot.ref.getDownloadURL();
          print('Uploaded image URL: $url');
          print('Image metadata:');
          print('Content-Type: ${snapshot.metadata?.contentType}');
          print('Custom metadata: ${snapshot.metadata?.customMetadata}');
          print('Size: ${snapshot.metadata?.size} bytes');
          print('Generation: ${snapshot.metadata?.generation}');
          print('Updated: ${snapshot.metadata?.updated}');

          // Test the URL using Firebase Storage SDK
          try {
            print('Testing URL with Firebase Storage SDK...');
            final ref = FirebaseStorage.instance.refFromURL(url);
            final metadata = await ref.getMetadata();
            print('Retrieved metadata:');
            print('Content-Type: ${metadata.contentType}');
            print('Custom metadata: ${metadata.customMetadata}');
            print('Size: ${metadata.size} bytes');

            // Try to get the download URL again
            final newUrl = await ref.getDownloadURL();
            print('New download URL: $newUrl');

            // Test the new URL
            final response = await http.get(
              Uri.parse(newUrl),
              headers: {'Accept': 'image/jpeg', 'Cache-Control': 'no-cache'},
            );
            print('URL test response status: ${response.statusCode}');
            print('URL test response headers: ${response.headers}');
            if (response.statusCode != 200) {
              print('Error response body: ${response.body}');
            } else {
              print(
                'Successfully downloaded ${response.bodyBytes.length} bytes',
              );
            }
          } catch (e) {
            print('Error testing URL: $e');
            if (e is http.ClientException) {
              print('Client exception details: ${e.message}');
            }
          }

          provider.removePendingAttachment(id);
          provider.addAttachment(
            Attachment(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: pickedFile.name,
              url: url,
              type: 'image',
            ),
          );
          print(
            'Current attachments after image upload: \n${provider.attachments.map((a) => a.toMap())}',
          );
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
          final id = 'pending_${DateTime.now().millisecondsSinceEpoch}';
          final pending = Attachment(
            id: id,
            name: file.name,
            url: '',
            type: 'pdf',
            isPending: true,
            progress: 0.0,
          );
          provider.addPendingAttachment(pending);
          String fileName =
              DateTime.now().millisecondsSinceEpoch.toString() + '.pdf';
          final metadata = SettableMetadata(
            contentType: 'application/pdf',
            customMetadata: {'Content-Disposition': 'inline'},
          );
          final ref = FirebaseStorage.instance.ref().child(
            'attachments/$fileName',
          );
          final uploadTask = ref.putData(file.bytes!, metadata);
          uploadTask.snapshotEvents.listen((event) {
            final progress =
                event.bytesTransferred /
                (event.totalBytes == 0 ? 1 : event.totalBytes);
            provider.updatePendingAttachmentProgress(id, progress);
          });
          final snapshot = await uploadTask;
          final url = await snapshot.ref.getDownloadURL();
          print('Uploaded PDF URL: $url');
          provider.removePendingAttachment(id);
          provider.addAttachment(
            Attachment(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: file.name,
              url: url,
              type: 'pdf',
            ),
          );
          print(
            'Current attachments after PDF upload: \n${provider.attachments.map((a) => a.toMap())}',
          );
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
    }
  }

  Future<void> _createAnnouncement(AnnouncementProvider provider) async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter description.')),
      );
      return;
    }
    final hasPending = provider.attachments.any(
      (a) => a.isPending || a.url.isEmpty,
    );
    if (hasPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for all attachments to finish uploading.'),
        ),
      );
      return;
    }
    provider.setLoading(true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      print(
        'Attachments before creating announcement: \\n${provider.attachments.map((a) => a.toMap())}',
      );
      await PostsService().createAnnouncement(
        title: 'Announcement',
        content: _descController.text.trim(),
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Admin',
        userRole: 'gov_admin',
        attachments: provider.attachments,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement created successfully')),
        );
        provider.clear();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      provider.setLoading(false);
    }
  }

  Future<void> _downloadAttachment(Attachment attachment) async {
    if (attachment.url.isEmpty) return;
    final url = Uri.parse(attachment.url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch file URL.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AnnouncementProvider>(context);
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
                        const Text('Location', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.location.isEmpty
                                    ? 'Kothrud, Pune, 411038'
                                    : provider.location,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await _changeLocation(provider);
                              },
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
                                  provider.isLoading
                                      ? null
                                      : () => _pickAttachment(
                                        'Click Pictures',
                                        provider,
                                      ),
                              color: Colors.red,
                            ),
                            _AttachmentButton(
                              icon: Icons.picture_as_pdf,
                              label: 'PDF',
                              onTap:
                                  provider.isLoading
                                      ? null
                                      : () => _pickAttachment('PDF', provider),
                              color: Colors.red,
                            ),
                          ],
                        ),
                        if (provider.attachments.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Selected Attachments:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...provider.attachments.map(
                            (attachment) => ListTile(
                              leading: Icon(
                                attachment.type == 'image'
                                    ? Icons.image
                                    : Icons.picture_as_pdf,
                                color:
                                    attachment.isPending
                                        ? Colors.grey
                                        : Colors.red,
                              ),
                              title: Text(attachment.name),
                              subtitle:
                                  attachment.isPending
                                      ? Row(
                                        children: [
                                          const Text('Uploading...'),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: attachment.progress,
                                              minHeight: 6,
                                            ),
                                          ),
                                        ],
                                      )
                                      : Text(attachment.type),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed:
                                        attachment.isPending ||
                                                attachment.url.isEmpty
                                            ? null
                                            : () =>
                                                _downloadAttachment(attachment),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        provider.isLoading ||
                                                attachment.isPending
                                            ? null
                                            : () => provider.removeAttachment(
                                              attachment.id,
                                            ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                provider.isLoading ||
                                        provider.attachments.any(
                                          (a) => a.isPending || a.url.isEmpty,
                                        )
                                    ? null
                                    : () => _createAnnouncement(provider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child:
                                provider.isLoading
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
