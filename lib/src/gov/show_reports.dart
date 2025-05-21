import 'package:flutter/material.dart';
import 'package:gov_citizen_app/src/providers/report_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class ShowReportsScreen extends StatefulWidget {
  const ShowReportsScreen({super.key});

  @override
  State<ShowReportsScreen> createState() => _ShowReportsScreenState();
}

class _ShowReportsScreenState extends State<ShowReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return Colors.amber;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background image with parallax effect
          Positioned.fill(
            child: Image.asset(
              'assets/homepage.jpg',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.3),
            ),
          ),
          // Content
          SafeArea(
              child: Column(
                children: [
                // Custom Tab Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelColor: Colors.amber,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(text: 'All Reports'),
                      Tab(text: 'In Progress'),
                      Tab(text: 'Resolved'),
                    ],
                  ),
                ),
                // Reports List
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: StreamBuilder(
                      stream:
                          Provider.of<ReportProvider>(
                            context,
                            listen: false,
                          ).getReports(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.amber,
              ),
            );
          }

          final allReports = snapshot.data ?? [];
          var filteredReports =
              allReports.where((report) {
                switch (_tabController.index) {
                  case 1:
                                  return report.status.toLowerCase() ==
                                      'in progress';
                  case 2:
                                  return report.status.toLowerCase() ==
                                      'resolved';
                  default:
                    return true;
                }
              }).toList();

          if (filteredReports.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            return _buildReportCard(report);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
            return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
              child: Column(
          mainAxisSize: MainAxisSize.min,
                children: [
            Icon(Icons.report_outlined, color: Colors.grey[400], size: 64),
            const SizedBox(height: 16),
                  Text(
                    'No ${_tabController.index == 0
                        ? ''
                        : _tabController.index == 1
                        ? 'in progress'
                        : 'resolved'} reports found',
              style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              textAlign: TextAlign.center,
                  ),
                ],
        ),
              ),
            );
          }

  Widget _buildReportCard(dynamic report) {
    final statusColor = _getStatusColor(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.report_problem, color: statusColor),
          ),
          title: Text(
            'Emergency: ${report.emergencyType}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${report.city}, ${report.area}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      ),
                ],
                      ),
                    ],
                  ),
                  children: [
                    Padding(
              padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  _buildDetailRow('City', report.city),
                  _buildDetailRow('Area', report.area),
                  const SizedBox(height: 16),
                  const Text(
                    'Details:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                          Text(
                    report.details,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                          Text(
                            'Reported by: ${report.userName}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                          if (report.attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                            const Text(
                              'Attachments:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  report.attachments.map<Widget>((url) {
                                    final isImage =
                                        url.toLowerCase().contains('.jpg') ||
                                        url.toLowerCase().contains('.jpeg') ||
                                        url.toLowerCase().contains('.png') ||
                                        url.toLowerCase().contains('.webp');
                                    if (isImage) {
                                      return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          url,
                                  width: 100,
                                  height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                      (c, e, s) => Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.white54,
                                        ),
                                              ),
                                        ),
                                      );
                                    } else {
                                      return GestureDetector(
                                        onTap: () async {
                                          if (await canLaunch(url)) {
                                            await launch(url);
                                          }
                                        },
                                        child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                          child: const Icon(
                                            Icons.insert_drive_file,
                                            size: 40,
                                    color: Colors.white54,
                                          ),
                                        ),
                                      );
                                    }
                                  }).toList(),
                            ),
                          ],
                  if (report.latitude != null && report.longitude != null) ...[
                    const SizedBox(height: 16),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                              ),
                              child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                              userAgentPackageName: 'com.example.app',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: latlong.LatLng(
                                            report.latitude!,
                                            report.longitude!,
                                          ),
                                  width: 40,
                                  height: 40,
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
                            ],
                        ],
                      ),
                    ),
                  ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
