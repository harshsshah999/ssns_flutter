import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'ChartData.dart';
import 'data_loader.dart'; // Import DataLoader

class AnalysisScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analysis'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<List<ChartData>>(
              future: DataLoader.fetchCSVData('https://cillyfox.com/ssns/daily_averages_sensor_data.csv', 'Temperature'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading data'));
                } else {
                  final temperatureData = snapshot.data!;
                  final peakTemperature = temperatureData.reduce((a, b) => a.y > b.y ? a : b);

                  return _buildTemperatureChart(temperatureData, peakTemperature);
                }
              },
            ),
            SizedBox(height: 16),
            FutureBuilder<List<ChartData>>(
              future: DataLoader.fetchCSVData('https://cillyfox.com/ssns/daily_averages_sensor_data.csv', 'CO2'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading data'));
                } else {
                  final co2Data = snapshot.data!;
                  final peakCO2 = co2Data.reduce((a, b) => a.y > b.y ? a : b);

                  return _buildCO2Chart(co2Data, peakCO2);
                }
              },
            ),
            SizedBox(height: 16),
            FutureBuilder<List<ChartData>>(
              future: loadPMRatioData('https://cillyfox.com/ssns/daily_averages_sensor_data.csv'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading data'));
                } else {
                  final pmData = snapshot.data!;
                  return _buildPMDonutChart(pmData);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPMDonutChart(List<ChartData> pmData) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PM2.5 vs PM10 Ratio', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Container(
              height: 300,
              child: SfCircularChart(
                legend: Legend(isVisible: true),
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: pmData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureChart(List<ChartData> temperatureData, ChartData peakTemperature) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Average Temperature by Hour (Last 24 Hours)', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Container(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(text: 'Time (Hours)'),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Temperature (°C)'),
                ),
                series: <ChartSeries>[
                  ColumnSeries<ChartData, String>(
                    dataSource: temperatureData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                    color: Colors.blue,
                  ),
                ],
                annotations: <CartesianChartAnnotation>[
                  CartesianChartAnnotation(
                    widget: Container(
                      child: Icon(
                        Icons.arrow_drop_up,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    coordinateUnit: CoordinateUnit.point,
                    region: AnnotationRegion.chart,
                    x: peakTemperature.x,
                    y: peakTemperature.y + 1,
                  ),
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Peak temperature occurs at ${peakTemperature.x} hours with ${peakTemperature.y}°C. '
                  'Consider keeping the environment cool by using air conditioning or fans.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCO2Chart(List<ChartData> co2Data, ChartData peakCO2) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Average CO2 Levels by Hour (Last 24 Hours)', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Container(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(text: 'Time (Hours)'),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'CO2 Levels (ppm)'),
                ),
                series: <ChartSeries>[
                  ColumnSeries<ChartData, String>(
                    dataSource: co2Data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                    color: Colors.green,
                  ),
                ],
                annotations: <CartesianChartAnnotation>[
                  CartesianChartAnnotation(
                    widget: Container(
                      child: Icon(
                        Icons.arrow_drop_up,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    coordinateUnit: CoordinateUnit.point,
                    region: AnnotationRegion.chart,
                    x: peakCO2.x,
                    y: peakCO2.y + 1,
                  ),
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Peak CO2 levels occur at ${peakCO2.x} hours with ${peakCO2.y} ppm. '
                  'Ensure proper ventilation or use air purifiers to maintain good air quality.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<ChartData>> loadPMRatioData(String url) async {
    final List<ChartData> chartData = [];
    final response = await http.get(Uri.parse(url), headers: {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });

    if (response.statusCode == 200) {
      final csvData = const Utf8Decoder().convert(response.bodyBytes);
      final normalizedCsvData = csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');  // Normalize all line endings to \n
      List<List<dynamic>> rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ',').convert(normalizedCsvData);

      final int pm2_5Index = rows[0].indexOf('PM2.5');
      final int pm10Index = rows[0].indexOf('PM10');

      if (pm2_5Index == -1 || pm10Index == -1) {
        throw Exception('Column names PM2.5 or PM10 not found in CSV file');
      }

      // Calculate the ratio and add to chartData
      for (var row in rows.skip(1)) { // Skip header row
        final double pm2_5 = double.parse(row[pm2_5Index].toString());
        final double pm10 = double.parse(row[pm10Index].toString());
        final double ratio = pm2_5 / pm10;

        chartData.add(ChartData(row[0].toString(), ratio));
      }
    } else {
      throw Exception('Failed to load CSV');
    }

    return chartData;
  }
}
