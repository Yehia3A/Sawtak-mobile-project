import 'package:flutter/material.dart';
import 'package:gov_citizen_app/src/providers/report_provider.dart';
import 'package:gov_citizen_app/src/widgets/custom_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

class ShowReportsScreen extends StatefulWidget {
  @override
  State<ShowReportsScreen> createState() => _ShowReportsScreenState();
}

class _ShowReportsScreenState extends State<ShowReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'In Progress'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: StreamBuilder(
        stream:
            Provider.of<ReportProvider>(context, listen: false).getReports(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final allReports = snapshot.data ?? [];

          // Filter reports based on selected tab
          var filteredReports =
              allReports.where((report) {
                switch (_tabController.index) {
                  case 1:
                    return report.status.toLowerCase() == 'in progress';
                  case 2:
                    return report.status.toLowerCase() == 'resolved';
                  default:
                    return true;
                }
              }).toList();

          if (filteredReports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_outlined, color: Colors.grey, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No ${_tabController.index == 0
                        ? ''
                        : _tabController.index == 1
                        ? 'in progress'
                        : 'resolved'} reports found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredReports.length,
            itemBuilder: (context, index) {
              final report = filteredReports[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(report.status),
                    child: Icon(Icons.report_problem, color: Colors.white),
                  ),
                  title: Text('Emergency: ${report.emergencyType}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${report.status}',
                        style: TextStyle(color: _getStatusColor(report.status)),
                      ),
                      Text(
                        'Location: ${report.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Details:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(report.details),
                          SizedBox(height: 16),
                          Text(
                            'Reported by: ${report.userName}',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          SizedBox(height: 16),
                          if (report.latitude != null &&
                              report.longitude != null)
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: latlong.LatLng(
                                      report.latitude!,
                                      report.longitude!,
                                    ),
                                    initialZoom: 13.0,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: latlong.LatLng(
                                            report.latitude!,
                                            report.longitude!,
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            color: Colors.red,
                                            size: 30,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (report.status.toLowerCase() !=
                                      'in progress' &&
                                  report.status.toLowerCase() != 'resolved')
                                ElevatedButton.icon(
                                  icon: Icon(Icons.pending_actions),
                                  label: Text('Mark In Progress'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.orange,
                                  ),
                                  onPressed:
                                      () => Provider.of<ReportProvider>(
                                        context,
                                        listen: false,
                                      ).updateReportStatus(
                                        report.id,
                                        'In Progress',
                                      ),
                                ),
                              if (report.status.toLowerCase() != 'resolved')
                                ElevatedButton.icon(
                                  icon: Icon(Icons.check_circle),
                                  label: Text('Mark Resolved'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed:
                                      () => Provider.of<ReportProvider>(
                                        context,
                                        listen: false,
                                      ).updateReportStatus(
                                        report.id,
                                        'Resolved',
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
