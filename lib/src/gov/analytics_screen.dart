import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../data/egypt_locations.dart';
import 'dart:ui';

class AnalyticsScreen extends StatefulWidget {
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  String? selectedCity;
  Map<String, int> cityCounts = {};
  Map<String, int> areaCounts = {};
  bool isLoadingCity = true;
  bool isLoadingArea = false;
  late AnimationController _aniController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _aniController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _aniController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _aniController, curve: Curves.easeOutCubic),
    );
    _aniController.forward();
    _loadCityCounts();
  }

  @override
  void dispose() {
    _aniController.dispose();
    super.dispose();
  }

  Future<void> _loadCityCounts() async {
    setState(() => isLoadingCity = true);
    final counts =
        await Provider.of<ReportProvider>(
          context,
          listen: false,
        ).getReportCountsByCity();
    setState(() {
      cityCounts = counts;
      isLoadingCity = false;
    });
  }

  Future<void> _loadAreaCounts() async {
    if (selectedCity == null) return;
    setState(() => isLoadingArea = true);
    final counts = await Provider.of<ReportProvider>(
      context,
      listen: false,
    ).getReportCountsByArea(selectedCity!);
    setState(() {
      areaCounts = counts;
      isLoadingArea = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Image.asset(
            'assets/homepage.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Analytics',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Reports per City',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (isLoadingCity)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.amber,
                                ),
                              )
                            else if (cityCounts.isEmpty)
                              const Center(
                                child: Text(
                                  'No data',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            else
                              SizedBox(
                                height: 300,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    minY: 0,
                                    barGroups: [
                                      for (
                                        int i = 0;
                                        i < cityCounts.length;
                                        i++
                                      )
                                        BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY:
                                                  cityCounts.values
                                                      .elementAt(i)
                                                      .toDouble(),
                                              color: Colors.amber,
                                              width: 18,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ],
                                        ),
                                    ],
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            if (value % 1 != 0)
                                              return const SizedBox();
                                            return Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (
                                            double value,
                                            TitleMeta meta,
                                          ) {
                                            final idx = value.toInt();
                                            if (idx < 0 ||
                                                idx >= cityCounts.length)
                                              return const SizedBox();
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(
                                                cityCounts.keys.elementAt(idx),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              space: 4,
                                            );
                                          },
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(show: false),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 32),
                            const Text(
                              'Reports per Area',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedCity,
                                    dropdownColor: Colors.black87,
                                    decoration: InputDecoration(
                                      labelText: 'Select City',
                                      labelStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    items:
                                        getAllCities()
                                            .map(
                                              (city) => DropdownMenuItem(
                                                value: city,
                                                child: Text(city),
                                              ),
                                            )
                                            .toList(),
                                    onChanged:
                                        (val) =>
                                            setState(() => selectedCity = val),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed:
                                      selectedCity == null
                                          ? null
                                          : _loadAreaCounts,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Show Graph'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (isLoadingArea)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.amber,
                                ),
                              )
                            else if (areaCounts.isEmpty && selectedCity != null)
                              const Center(
                                child: Text(
                                  'No data for this city',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            else if (areaCounts.isNotEmpty)
                              SizedBox(
                                height: 300,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    minY: 0,
                                    barGroups: [
                                      for (
                                        int i = 0;
                                        i < areaCounts.length;
                                        i++
                                      )
                                        BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY:
                                                  areaCounts.values
                                                      .elementAt(i)
                                                      .toDouble(),
                                              color: Colors.greenAccent,
                                              width: 18,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ],
                                        ),
                                    ],
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            if (value % 1 != 0)
                                              return const SizedBox();
                                            return Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (
                                            double value,
                                            TitleMeta meta,
                                          ) {
                                            final idx = value.toInt();
                                            if (idx < 0 ||
                                                idx >= areaCounts.length)
                                              return const SizedBox();
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(
                                                areaCounts.keys.elementAt(idx),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              space: 4,
                                            );
                                          },
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(show: false),
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
            ),
          ),
        ],
      ),
    );
  }
}
