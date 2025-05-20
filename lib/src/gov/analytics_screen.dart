import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../data/egypt_locations.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? selectedCity;
  Map<String, int> cityCounts = {};
  Map<String, int> areaCounts = {};
  bool isLoadingCity = true;
  bool isLoadingArea = false;

  @override
  void initState() {
    super.initState();
    _loadCityCounts();
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
      appBar: AppBar(title: Text('Analytics'), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports per City',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            if (isLoadingCity)
              Center(child: CircularProgressIndicator())
            else if (cityCounts.isEmpty)
              Center(child: Text('No data'))
            else
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    minY: 0,
                    barGroups: [
                      for (int i = 0; i < cityCounts.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: cityCounts.values.elementAt(i).toDouble(),
                              color: Colors.blue,
                              width: 18,
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
                            if (value % 1 != 0) return SizedBox();
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= cityCounts.length)
                              return SizedBox();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                cityCounts.keys.elementAt(idx),
                                style: TextStyle(fontSize: 10),
                              ),
                              space: 4,
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            SizedBox(height: 32),
            Text(
              'Reports per Area',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: InputDecoration(
                      labelText: 'Select City',
                      border: OutlineInputBorder(),
                    ),
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
                        (val) => setState(() {
                          selectedCity = val;
                        }),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: selectedCity == null ? null : _loadAreaCounts,
                  child: Text('Show Graph'),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (isLoadingArea)
              Center(child: CircularProgressIndicator())
            else if (areaCounts.isEmpty && selectedCity != null)
              Center(child: Text('No data for this city'))
            else if (areaCounts.isNotEmpty)
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    minY: 0,
                    barGroups: [
                      for (int i = 0; i < areaCounts.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: areaCounts.values.elementAt(i).toDouble(),
                              color: Colors.green,
                              width: 18,
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
                            if (value % 1 != 0) return SizedBox();
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= areaCounts.length)
                              return SizedBox();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                areaCounts.keys.elementAt(idx),
                                style: TextStyle(fontSize: 10),
                              ),
                              space: 4,
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
