import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:async';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'AnalysisScreen.dart'; // Update this path to the correct path of your AnalysisScreen.dart file
import 'ChartData.dart'
    '';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [MainPage(), AnalysisScreen(), HistoricalDataScreen()];

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
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historical Data'),
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

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      _fetchLatestCO2();
    });
  }

  Future<void> _fetchLatestCO2() async {
    print('Fetching latest CO2...');
    try {
      final url = Uri.parse('https://cillyfox.com/ssns/output.csv?timestamp=${DateTime.now().millisecondsSinceEpoch}');
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
        List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvData);
        print('CSV Data: $rowsAsListOfValues');
        final lastRow = rowsAsListOfValues.last;
        print('Last Row: $lastRow');
        final latestCO2String = lastRow.first.toString().split(' ').last;
        print('Latest CO2 fetched: $latestCO2String');
        setState(() {
          latestCO2 = int.parse(latestCO2String);
        });
      } else {
        print('Failed to load CSV: ${response.statusCode}');
        throw Exception('Failed to load CSV');
      }
    } catch (e) {
      print('Error fetching CO2: $e');
    }
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
            _buildSummaryCard(),
            SizedBox(height: 16),
            _buildAQIOvertime(),
            SizedBox(height: 16),
            _buildAverageCO2Daily(),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchLatestCO2,
              child: Text('Refresh CO2'),
            ),
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
                _buildInfoColumn('Temperature', '25°C'),
                _buildInfoColumn('AQI', '50'),
                _buildInfoColumn('Humidity', '70%'),
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

  Widget _buildSummaryCard() {
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
              'The CO2 level is currently 920 ppm, which is within the normal range. With a high humidity level of 70%, the air feels quite muggy. '
                  'The PM 2.5 concentration is slightly elevated at 12 µg/m³, which is acceptable but could be better.\n\n'
                  'Suggestions:\n'
                  '1. Ensure proper ventilation to maintain CO2 levels and reduce indoor humidity.\n'
                  '2. Consider using an air purifier to reduce particulate matter indoors.\n'
                  '3. If you have respiratory issues, avoid strenuous outdoor activities today.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAQIOvertime() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('AQI Overtime', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Container(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
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
                    dataSource: getAQIChartData(),
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

  Widget _buildAverageCO2Daily() {
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
            _buildDailyBar('7 AM', 420),
            _buildDailyBar('10 AM', 430),
            _buildDailyBar('1 PM', 450),
            _buildDailyBar('4 PM', 460),
            _buildDailyBar('7 PM', 480),
            _buildDailyBar('10 PM', 500),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBar(String time, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(time),
          SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 600,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
          SizedBox(width: 8),
          Text('$value ppm'),
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

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}

class HistoricalDataScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historical Data'),
      ),
      body: Center(
        child: Text('Historical Data Screen Content Goes Here'),
      ),
    );
  }
}