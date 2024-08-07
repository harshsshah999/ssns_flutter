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
            SizedBox(height: 16),
            _buildAQI24hChartWithPM(),
            SizedBox(height: 16),
            FutureBuilder<List<ChartData>>(
              future: DataLoader.fetchPeakHourData(
                'https://cillyfox.com/ssns/peak_hour_data_new.csv',
                'Temperature (C)',
                'Peak_Hour_Temperature',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading peak hour data'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No data available'));
                } else {
                  final peakHourData = snapshot.data!;
                  return _buildPeakHourTemperatureChart(peakHourData);
                }
              },
            ),
            //SizedBox(height: 16),
            //_buildAQI24hChartWithPM(),
            SizedBox(height: 16),
            _buildPredictedAQIChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictedAQIChart() {
    return FutureBuilder<List<ChartData>>(
      future: DataLoader.fetchPredictedAQIData(
          'https://cillyfox.com/ssns/pred_file_latest.csv'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading predicted AQI data'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        } else {
          final predictedAQIData = snapshot.data!;
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Predicted AQI for next day',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Container(
                    height: 300,
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(
                        title: AxisTitle(text: 'Hour'),
                        majorGridLines: MajorGridLines(width: 0),
                        labelPlacement: LabelPlacement.onTicks,
                        edgeLabelPlacement: EdgeLabelPlacement.shift,
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: 'Predicted AQI Levels'),
                      ),
                      series: <ChartSeries>[
                        LineSeries<ChartData, String>(
                          dataSource: predictedAQIData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          dataLabelSettings: DataLabelSettings(isVisible: true),
                        ),
                      ],
                      tooltipBehavior: TooltipBehavior(enable: true),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildAQI24hChartWithPM() {
    return FutureBuilder<List<ChartData>>(
      future: DataLoader.fetchAQI24hData(
          'https://cillyfox.com/ssns/aqi_data_last_24hrs.csv'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading AQI 24h data'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        } else {
          final aqiData = snapshot.data!;
          final last24Data = aqiData.length > 24
              ? aqiData.sublist(aqiData.length - 24)
              : aqiData;

          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('AQI Over the Last 24 Hours (PM2.5 and PM10)',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Container(
                    height: 300,
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(
                        title: AxisTitle(text: 'Hour'),
                        majorGridLines: MajorGridLines(width: 0),
                        labelPlacement: LabelPlacement.onTicks,
                        edgeLabelPlacement: EdgeLabelPlacement.shift,
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: 'AQI Levels'),
                        plotBands: <PlotBand>[
                          PlotBand(
                            isVisible: true,
                            start: 0,
                            end: 50,
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.3),
                                Colors.green.withOpacity(0)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            text: 'Good',
                            textStyle: TextStyle(color: Colors.green),
                          ),
                          PlotBand(
                            isVisible: true,
                            start: 51,
                            end: 100,
                            gradient: LinearGradient(
                              colors: [
                                Colors.yellow.withOpacity(0.3),
                                Colors.yellow.withOpacity(0)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            text: 'Moderate',
                            textStyle: TextStyle(color: Colors.yellow[800]),
                          ),
                          PlotBand(
                            isVisible: true,
                            start: 101,
                            end: 150,
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.withOpacity(0.3),
                                Colors.orange.withOpacity(0)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            text: 'Unhealthy for Sensitive Groups',
                            textStyle: TextStyle(color: Colors.orange),
                          ),
                          PlotBand(
                            isVisible: true,
                            start: 151,
                            end: 200,
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.withOpacity(0.3),
                                Colors.red.withOpacity(0)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            text: 'Unhealthy',
                            textStyle: TextStyle(color: Colors.red),
                          ),
                          PlotBand(
                            isVisible: true,
                            start: 201,
                            end: 300,
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.withOpacity(0.3),
                                Colors.purple.withOpacity(0)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            text: 'Very Unhealthy',
                            textStyle: TextStyle(color: Colors.purple),
                          ),
                          PlotBand(
                            isVisible: true,
                            start: 301,
                            end: 500,
                            gradient: LinearGradient(
                              colors: [
                                Colors.red[900]!.withOpacity(0.3),
                                Colors.red[900]!.withOpacity(0)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            text: 'Hazardous',
                            textStyle: TextStyle(color: Colors.red[900]),
                          ),
                        ],
                      ),
                      series: <ChartSeries>[
                        LineSeries<ChartData, String>(
                          name: 'PM2.5',
                          dataSource: last24Data,
                          xValueMapper: (ChartData data, _) {
                            DateTime dateTime = DateTime.parse(data.x);
                            String period = dateTime.hour >= 12 ? 'PM' : 'AM';
                            int hour = dateTime.hour > 12
                                ? dateTime.hour - 12
                                : dateTime.hour;
                            return '$hour $period';
                          },
                          yValueMapper: (ChartData data, _) =>
                              data.y, // PM2.5 values
                          dataLabelSettings: DataLabelSettings(isVisible: true),
                          color: Colors.blue, // Specify color for PM2.5
                        ),
                        LineSeries<ChartData, String>(
                          name: 'PM10',
                          dataSource: last24Data,
                          xValueMapper: (ChartData data, _) {
                            DateTime dateTime = DateTime.parse(data.x);
                            String period = dateTime.hour >= 12 ? 'PM' : 'AM';
                            int hour = dateTime.hour > 12
                                ? dateTime.hour - 12
                                : dateTime.hour;
                            return '$hour $period';
                          },
                          yValueMapper: (ChartData data, _) =>
                              data.pm10, // PM10 values
                          dataLabelSettings: DataLabelSettings(isVisible: true),
                          color: Colors.red, // Specify color for PM10
                        ),
                      ],
                      tooltipBehavior: TooltipBehavior(enable: true),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIndicator(Colors.blue, 'PM2.5'),
                      _buildIndicator(Colors.red, 'PM10'),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildIndicator(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildPeakHourTemperatureChart(List<ChartData> data) {
    // Ensure we only have the last 24 hours of data
    final last24Data = data.length > 24 ? data.sublist(data.length - 24) : data;

    // Determine the minimum and maximum y-values
    final yValues = last24Data.map((data) => data.y.toInt()).toList(); // Cast to int
    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Temperature Throughout The Last 24 Hours',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Container(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(text: 'Hour'),
                  majorGridLines: MajorGridLines(width: 0),
                  labelPlacement: LabelPlacement.onTicks,
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  interval: 1,
                  labelStyle: TextStyle(fontSize: 12),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Temperature (°C)'),
                  minimum: minY - 3.toDouble(), // Add some padding and cast to double
                  maximum: maxY + 3.toDouble(), // Add some padding and cast to double
                  interval: ((maxY - minY) / 5).ceilToDouble(), // Dynamically set interval
                  labelStyle: TextStyle(fontSize: 12),
                  decimalPlaces: 0,
                  labelFormat: '{value}',
                ),
                series: <ChartSeries>[
                  LineSeries<ChartData, String>(
                    dataSource: last24Data,
                    xValueMapper: (ChartData data, _) {
                      DateTime dateTime = DateTime.parse(data.x);
                      return '${dateTime.hour}';
                    },
                    yValueMapper: (ChartData data, _) => data.y.toInt(), // Cast to int
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                      textStyle: TextStyle(fontSize: 12),
                    ),
                    markerSettings: MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.circle,
                      borderColor: Colors.blue,
                      borderWidth: 2,
                    ),
                    pointColorMapper: (ChartData data, _) =>
                    data.isPeak ? Colors.red : Colors.blue,
                  ),
                  ScatterSeries<ChartData, String>(
                    dataSource: last24Data.where((data) => data.isPeak).toList(),
                    xValueMapper: (ChartData data, _) {
                      DateTime dateTime = DateTime.parse(data.x);
                      return '${dateTime.hour}';
                    },
                    yValueMapper: (ChartData data, _) => data.y.toInt(), // Cast to int
                    markerSettings: MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.diamond,
                      color: Colors.red,
                      borderColor: Colors.red,
                      borderWidth: 2,
                    ),
                  ),
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
