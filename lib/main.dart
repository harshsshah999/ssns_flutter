import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:async';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'AnalysisScreen.dart'; // Update this path to the correct path of your AnalysisScreen.dart file
import 'ChartData.dart';
import 'data_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notification plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      debugShowCheckedModeBanner: false, // Remove the debug label
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [MainPage(), AnalysisScreen()]; // Removed HistoricalDataScreen
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analysis'),
        ],
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int latestCO2 = 920;
  Timer? _timer;
  late Future<List<ChartData>> _aqi24hData;
  late Future<List<ChartData>> _hourlyCO2Data;
  late Future<List<ChartData>> _predictedAQIData;

  double latestTemperature = 0; // Default value for latestTemperature
  int latestAQI = 0; // Default value for latestAQI
  double latestPMC = 0; // Default value for latestPMC

  double latestHumidity = 0;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
    _fetchLatestSensorData(); // Fetch the latest sensor data initially
    _aqi24hData = DataLoader.fetchAQI24hData('https://cillyfox.com/ssns/aqi_data_last_24hrs.csv');
    _hourlyCO2Data = DataLoader.fetchPeakHourData(
      'https://cillyfox.com/ssns/peak_hour_data_new.csv',
      'CO2 (ppm)',
      'Peak_Hour_CO2',
    );
    _predictedAQIData = DataLoader.fetchPredictedAQIData('https://cillyfox.com/ssns/pred_file_latest.csv');

  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      _fetchLatestSensorData();
    });
  }

  Future<void> _fetchLatestSensorData() async {
    print('Fetching latest sensor data...');
    try {
      final url = Uri.parse('https://cillyfox.com/ssns/sensor_data.csv?timestamp=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(
        url,
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        final csvData = const Utf8Decoder().convert(response.bodyBytes);
        List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter(eol: "\n").convert(csvData);

        if (rowsAsListOfValues.isNotEmpty) {
          final lastRow = rowsAsListOfValues.last;
          print('Last Row: $lastRow');

          setState(() {
            latestCO2 = int.parse(lastRow[3].toString()); // CO2 (ppm) column
            latestTemperature = double.parse(lastRow[4].toString()); // Temperature (C) column
            latestPMC = double.parse(lastRow[7].toString()); // pm2.5 column, you can apply AQI formula here
            latestHumidity = double.parse(lastRow[5].toString()); // Humidity column
          });
        } else {
          print('CSV data is empty');
        }
      } else {
        print('Failed to load CSV: ${response.statusCode}');
        throw Exception('Failed to load CSV');
      }
    } catch (e) {
      print('Error fetching sensor data: $e');
    }
  }

  Future<String> _getSummaryAndSuggestions() async {
    String summary = '';
    String suggestions = '';
    int notificationId = 0;

    // CO2 Level Analysis
    if (latestCO2 > 1000) {
      summary += 'The CO2 level is currently $latestCO2 ppm, which is higher than recommended.\n';
      suggestions += '1. Ensure proper ventilation to lower CO2 levels.\n';
      await _scheduleNotification(
          notificationId++, 'High CO2 Levels', 'Ensure proper ventilation to lower CO2 levels.');
    } else {
      summary += 'The CO2 level is currently $latestCO2 ppm, which is within the normal range.\n';
      suggestions += '1. Maintain proper ventilation to keep CO2 levels normal.\n';
    }

    // Humidity Level Analysis
    if (latestHumidity > 60) {
      summary += 'With a high humidity level of ${latestHumidity.toStringAsFixed(1)}%, the air feels quite muggy.\n';
      suggestions += '2. Consider using a dehumidifier to reduce indoor humidity.\n';
      await _scheduleNotification(
          notificationId++, 'High Humidity Levels', 'Consider using a dehumidifier to reduce indoor humidity.');
    } else {
      summary += 'The humidity level is ${latestHumidity.toStringAsFixed(1)}%, which is comfortable.\n';
    }

    // AQI Level Analysis
    if (latestAQI > 100) {
      summary += 'The latest AQI is ${latestAQI.toString()}, which is above the safe limit.\n';
      suggestions += '3. Consider using an air purifier to reduce particulate matter indoors.\n';
      suggestions += '4. If you have respiratory issues, avoid strenuous outdoor activities today.\n';
      await _scheduleNotification(
          notificationId++, 'High PM 2.5 Levels', 'Consider using an air purifier to reduce particulate matter indoors.');
      await _scheduleNotification(
          notificationId++, 'High PM 2.5 Levels', 'If you have respiratory issues, avoid strenuous outdoor activities today.');
    } else {
    //  summary += 'The PM 2.5 concentration is ${latestPMC.toStringAsFixed(1)} µg/m³, which is acceptable.\n';
      summary += 'Most recent AQI is ${latestAQI.toString()} , which is acceptable.\n';
    }

    // Peak Temperature Analysis
    int peakTemperature = await _getPeakTemperature();
    summary += 'The peak temperature today was ${peakTemperature.toString()}°C.\n';
    if (peakTemperature > 30) {
      suggestions += '5. It is quite hot today. Stay hydrated and avoid outdoor activities during peak hours.\n';
      await _scheduleNotification(notificationId++, 'High Temperature', 'Stay hydrated and avoid outdoor activities during peak hours.');
    } else if (peakTemperature < 10) {
      suggestions += '5. It is quite cold today. Wear warm clothes and stay indoors if possible.\n';
      await _scheduleNotification(notificationId++, 'Low Temperature', 'Wear warm clothes and stay indoors if possible.');
    }

    // Predicted AQI Analysis
    final predictedAQIData = await _predictedAQIData;
    if (predictedAQIData.isNotEmpty) {
      final worstPredictedAQI = predictedAQIData.reduce((a, b) => a.y > b.y ? a : b);
      final worstHour = worstPredictedAQI.x;
      final worstAQIValue = worstPredictedAQI.y.toInt();

      summary += 'The worst predicted AQI today will be at $worstHour hours with a value of $worstAQIValue.\n';
      if (worstAQIValue > 100) {
        suggestions += '6. The air quality will be poor at $worstHour. Consider ventilating or using an air purifier.\n';
        await _scheduleNotification(notificationId++, 'Poor Predicted Air Quality', 'The air quality will be poor at $worstHour with a value of $worstAQIValue. Consider ventilating or using an air purifier.');
      } else {
        suggestions += '6. The predicted air quality is expected to remain within safe levels throughout the day.\n';
      }
    }

    return summary + '\nSuggestions:\n' + suggestions;
  }

  Future<int> _getPeakTemperature() async {
    try {
      final peakHourData = await DataLoader.fetchPeakHourData(
          'https://cillyfox.com/ssns/peak_hour_data_new.csv',
          'Temperature (C)',
          'Peak_Hour_Temperature');
      if (peakHourData.isNotEmpty) {
        // Filter to get only the peak hour data
        final peakTemperatureData = peakHourData.where((data) => data.isPeak).toList();
        if (peakTemperatureData.isNotEmpty) {
          // Find the peak temperature
          return peakTemperatureData.map((data) => data.y).reduce((a, b) => a > b ? a : b).toInt();
        } else {
          return 0; // Default value if no peak data is found
        }
      } else {
        return 0; // Default value if no data is found
      }
    } catch (e) {
      print('Error fetching peak temperature: $e');
      return 0; // Default value if there's an error
    }
  }

  Future<void> _scheduleNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'your_channel_id', // id
        'your_channel_name', // name
        channelDescription: 'your_channel_description', // description
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false);

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        id, title, body, platformChannelSpecifics);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Air Quality Monitoring'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCurrentInfoCard(),
            SizedBox(height: 16),
            FutureBuilder<String>(
              future: _getSummaryAndSuggestions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading summary and suggestions: ${snapshot.error}'));
                } else {
                  return _buildSummaryCard(snapshot.data ?? '');
                }
              },
            ),

            SizedBox(height: 16),
            _buildAQI24hChart(),
            SizedBox(height: 16),
            _buildAverageCO2Daily(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Current Information', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('Temperature', '${latestTemperature.toString()}°C'),
                _buildInfoColumn('AQI', latestAQI.toString()),
                _buildInfoColumn('Humidity', '${latestHumidity.toString()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildSummaryCard(String summaryAndSuggestions) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary & Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              summaryAndSuggestions,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAQI24hChart() {
    return FutureBuilder<List<ChartData>>(
      future: _aqi24hData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading AQI 24h data'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        } else {
          final aqiData = snapshot.data!;
          // Take only the last 24 entries
          final last24Data = aqiData.length > 24 ? aqiData.sublist(aqiData.length - 24) : aqiData;
          final lastRow = aqiData.last; // Get the last row from the aqiData
          latestAQI = lastRow.overallAQI?.toDouble().toInt() ?? 0;
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('AQI Over the Last 24 Hours', style: TextStyle(fontSize: 18)),
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
                              colors: [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0)],
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
                              colors: [Colors.yellow.withOpacity(0.3), Colors.yellow.withOpacity(0)],
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
                              colors: [Colors.orange.withOpacity(0.3), Colors.orange.withOpacity(0)],
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
                              colors: [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0)],
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
                              colors: [Colors.purple.withOpacity(0.3), Colors.purple.withOpacity(0)],
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
                              colors: [Colors.red[900]!.withOpacity(0.3), Colors.red[900]!.withOpacity(0)],
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
                          dataSource: last24Data,
                          xValueMapper: (ChartData data, _) {
                            DateTime dateTime = DateTime.parse(data.x);
                            String period = dateTime.hour >= 12 ? 'PM' : 'AM';
                            int hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
                            return '$hour $period';
                          },
                          yValueMapper: (ChartData data, _) => data.overallAQI,
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

  Widget _buildAverageCO2Daily() {
    return FutureBuilder<List<ChartData>>(
        future: _hourlyCO2Data,
        builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error loading CO2 data'));
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(child: Text('No data available'));
      } else {
        final co2Data = snapshot.data!;
        final List<ChartData> filteredData = [];
        for (int i = 0; i < 24; i = i + 2) { // Adjusted step from 3 to 1
          filteredData.add(co2Data[i]);
        }

        return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
            padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
    Text('Average CO2 Levels Throughout The Day', style: TextStyle(fontSize: 18)),
    SizedBox(height: 8),
    Column(
    children: filteredData.map((data) {
    final DateTime dateTime = DateTime.parse(data.x);
    final String hourLabel = '${dateTime.hour}:00';
    return _buildDailyBar(hourLabel, data.y, data.isPeak); // Change from isPredicted to isPeak
    }).toList(),
    ),
    ],
    ),
            ),
        );
      }
        },
    );
  }

  Widget _buildDailyBar(String time, double value, bool isPeak) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(time),
          SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 2500, // Adjusted the scale for better visualization
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(isPeak ? Colors.orange : Colors.purple), // Ensure orange is used for peak values
            ),
          ),
          SizedBox(width: 8),
          Text('${value.toStringAsFixed(2)} ppm'),
        ],
      ),
    );
  }

  List<ChartData> getAQIChartData() {
    return [
      ChartData('Mon', 50),
      ChartData('Tue', 55),
      ChartData('Wed', 60),
      ChartData('Thu', 195),
      ChartData('Fri', 400),
      ChartData('Sat', 205),
      ChartData('Sun', 40),
    ];
  }
}
