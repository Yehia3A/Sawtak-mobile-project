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
        title: Text('Report Issue'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          120,
        ), // Extra bottom padding for nav bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Emergency type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  provider.emergencyTypes
                      .map(
                        (type) => GestureDetector(
                          onTap: () => provider.selectType(type),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  provider.selectedType == type
                                      ? Colors.red[200]
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                Icon(type.icon, color: Colors.red),
                                SizedBox(height: 4),
                                Text(
                                  type.label,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            SizedBox(height: 20),
            TextField(
              controller: provider.titleController,
              decoration: InputDecoration(
                hintText: 'Stuck in elevator',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: provider.selectedCity,
              decoration: InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
              items:
                  getAllCities()
                      .map(
                        (city) =>
                            DropdownMenuItem(value: city, child: Text(city)),
                      )
                      .toList(),
              onChanged: provider.selectCity,
              validator: (value) => value == null ? 'Select a city' : null,
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: provider.selectedArea,
              decoration: InputDecoration(
                labelText: 'Area',
                border: OutlineInputBorder(),
              ),
              items:
                  provider.selectedCity == null
                      ? []
                      : getAreasForCity(provider.selectedCity!)
                          .map(
                            (area) => DropdownMenuItem(
                              value: area,
                              child: Text(area),
                            ),
                          )
                          .toList(),
              onChanged: provider.selectArea,
              validator: (value) => value == null ? 'Select an area' : null,
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    provider.location ?? 'Location',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => _showMapPicker(context, provider),
                  child: Text('Pick Location'),
                ),
                TextButton(
                  onPressed: () => provider.useCurrentLocation(),
                  child: Text('Use Current'),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: provider.descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Specify emergency in brief',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text('Attach proof', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            provider.proofs.isEmpty
                ? Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('No proof attached')),
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
                          proof.name.toLowerCase().endsWith('.png') ||
                          proof.name.toLowerCase().endsWith('.jpg') ||
                          proof.name.toLowerCase().endsWith('.jpeg');
                      Widget preview;
                      if (isImage) {
                        preview = Image.memory(
                          proof.bytes,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(Icons.broken_image),
                        );
                      } else {
                        preview = Container(
                          width: 80,
                          height: 80,
                          color: Colors.black12,
                          child: Icon(
                            Icons.insert_drive_file,
                            size: 40,
                            color: Colors.grey,
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            child: preview,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => provider.removeProof(i),
                              child: CircleAvatar(
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
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.pickImage,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Click Pictures'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
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
                child: Text('Submit Issue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapPicker(BuildContext context, ReportProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        latlng.LatLng? tempLatLng = provider.selectedLatLng;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                height: 500,
                child: Column(
                  children: [
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
                            tileProvider:
                                kIsWeb
                                    ? CancellableNetworkTileProvider()
                                    : null,
                          ),
                          MarkerLayer(
                            markers:
                                tempLatLng != null
                                    ? [
                                      Marker(
                                        point: tempLatLng!,
                                        child: Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 30,
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
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (tempLatLng != null) {
                                await provider.setHumanReadableLocation(
                                  tempLatLng!,
                                );
                              }
                              Navigator.pop(context);
                            },
                            child: Text('Confirm'),
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
