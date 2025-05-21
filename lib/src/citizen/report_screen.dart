import 'package:flutter/material.dart';
import 'package:gov_citizen_app/src/services/report.service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../providers/report_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import '../data/egypt_locations.dart';
import 'dart:ui';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class ReportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportProvider(ReportService()),
      child: ReportForm(),
    );
  }
}

class ReportForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Issue',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/homepage.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Main content with frosted glass effect
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 600, // or double.infinity for full width
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Emergency type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              provider.emergencyTypes
                                  .map(
                                    (type) => GestureDetector(
                                      onTap: () => provider.selectType(type),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color:
                                              provider.selectedType == type
                                                  ? Colors.red[200]
                                                  : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(type.icon, color: Colors.red),
                                            const SizedBox(height: 4),
                                            Text(
                                              type.label,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: provider.titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Stuck in elevator',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: provider.selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            labelStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white),
                          items:
                              getAllCities()
                                  .map(
                                    (city) => DropdownMenuItem(
                                      value: city,
                                      child: Text(
                                        city,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: provider.selectCity,
                          validator:
                              (value) => value == null ? 'Select a city' : null,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: provider.selectedArea,
                          decoration: const InputDecoration(
                            labelText: 'Area',
                            labelStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white),
                          items:
                              provider.selectedCity == null
                                  ? []
                                  : getAreasForCity(provider.selectedCity!)
                                      .map(
                                        (area) => DropdownMenuItem(
                                          value: area,
                                          child: Text(
                                            area,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                          onChanged: provider.selectArea,
                          validator:
                              (value) =>
                                  value == null ? 'Select an area' : null,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.location ?? 'Location',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  () => _showMapPicker(context, provider),
                              child: const Text(
                                'Pick Location',
                                style: TextStyle(color: Colors.amber),
                              ),
                            ),
                            TextButton(
                              onPressed: () => provider.useCurrentLocation(),
                              child: const Text(
                                'Use Current',
                                style: TextStyle(color: Colors.amber),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: provider.descriptionController,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Specify emergency in brief',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Attach proof',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        provider.proofs.isEmpty
                            ? Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'No proof attached',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            )
                            : SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: provider.proofs.length,
                                itemBuilder: (context, i) {
                                  final proof = provider.proofs[i];
                                  final isImage =
                                      proof.type == 'image' ||
                                      proof.name.toLowerCase().endsWith(
                                        '.png',
                                      ) ||
                                      proof.name.toLowerCase().endsWith(
                                        '.jpg',
                                      ) ||
                                      proof.name.toLowerCase().endsWith(
                                        '.jpeg',
                                      );
                                  Widget preview;
                                  if (isImage) {
                                    preview = Image.memory(
                                      proof.bytes,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (c, e, s) => const Icon(
                                            Icons.broken_image,
                                            color: Colors.white,
                                          ),
                                    );
                                  } else {
                                    preview = Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.black12,
                                      child: const Icon(
                                        Icons.insert_drive_file,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    );
                                  }
                                  return Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: preview,
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () => provider.removeProof(i),
                                          child: const CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.red,
                                            child: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: provider.pickImage,
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.black,
                                ),
                                label: const Text(
                                  'Click Pictures',
                                  style: TextStyle(color: Colors.black),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton(
                            onPressed:
                                user != null
                                    ? () => provider.submitReport(
                                      context,
                                      userId: user.uid,
                                      userName: user.displayName ?? 'Anonymous',
                                    )
                                    : null,
                            child: const Text(
                              'Submit Issue',
                              style: TextStyle(color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMapPicker(BuildContext context, ReportProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        latlng.LatLng? tempLatLng = provider.selectedLatLng;
        final TextEditingController _searchController = TextEditingController();
        bool _isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _findMyLocation() async {
              setState(() => _isLoading = true);
              try {
                final position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );
                final newLocation = latlng.LatLng(
                  position.latitude,
                  position.longitude,
                );
                setState(() {
                  tempLatLng = newLocation;
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not get current location: $e')),
                );
              }
              setState(() => _isLoading = false);
            }

            Future<void> _searchAddress() async {
              if (_searchController.text.isEmpty) return;
              setState(() => _isLoading = true);
              try {
                final locations = await locationFromAddress(
                  _searchController.text,
                );
                if (locations.isNotEmpty) {
                  final loc = locations.first;
                  final latLng = latlng.LatLng(loc.latitude, loc.longitude);
                  setState(() {
                    tempLatLng = latLng;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address not found.')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
              setState(() => _isLoading = false);
            }

            return Dialog(
              child: Container(
                height: 500,
                child: Column(
                  children: [
                    const Text(
                      'Select Location',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search address...',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (_) => _searchAddress(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchAddress,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _findMyLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Find My Location'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter:
                              tempLatLng ?? latlng.LatLng(30.033333, 31.233334),
                          initialZoom: 10.0,
                          onTap: (tapPosition, point) async {
                            setState(() {
                              tempLatLng = point;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          ),
                          MarkerLayer(
                            markers:
                                tempLatLng != null
                                    ? [
                                      Marker(
                                        point: tempLatLng!,
                                        width: 50,
                                        height: 50,
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 50,
                                        ),
                                      ),
                                    ]
                                    : [],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () async {
                                      if (tempLatLng != null) {
                                        await provider.setHumanReadableLocation(
                                          tempLatLng!,
                                        );
                                      }
                                      Navigator.pop(context);
                                    },
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
