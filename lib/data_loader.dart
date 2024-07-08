import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'ChartData.dart';

class DataLoader {
  static Future<List<ChartData>> fetchCSVData(String url, String columnName) async {
    final response = await http.get(Uri.parse(url), headers: {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });

    if (response.statusCode == 200) {
      final csvData = utf8.decode(response.bodyBytes);
      final normalizedCsvData = csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');  // Normalize all line endings to \n
      List<List<dynamic>> rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ',').convert(normalizedCsvData);

      final List<String> headers = rows[0].map((e) => e.toString().trim()).toList();
      final int columnIndex = headers.indexOf(columnName);

      if (columnIndex == -1) {
        throw Exception('Column name $columnName not found in CSV file');
      }

      // Remove the header row
      rows.removeAt(0);

      final List<ChartData> chartData = [];
      for (var row in rows) {
        if (row.length > columnIndex) {
          try {
            String xValue = row[0].toString();
            double yValue = double.parse(row[columnIndex].toString());
            chartData.add(ChartData(xValue, yValue));
          } catch (e) {
            print('Error parsing row: $row - Error: $e');
          }
        }
      }

      return chartData;
    } else {
      throw Exception('Failed to load CSV');
    }
  }

  static Future<List<ChartData>> fetchPeakHourData(String url, String columnName, String peakHourColumn) async {
    final response = await http.get(Uri.parse(url), headers: {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });

    if (response.statusCode == 200) {
      final csvData = utf8.decode(response.bodyBytes);
      final normalizedCsvData = csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      List<List<dynamic>> rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ',').convert(normalizedCsvData);

      final List<String> headers = rows[0].map((e) => e.toString().trim()).toList();
      final int columnIndex = headers.indexOf(columnName);
      final int peakHourColumnIndex = headers.indexOf(peakHourColumn);

      if (columnIndex == -1) {
        throw Exception('Column name $columnName not found in CSV file');
      }

      if (peakHourColumnIndex == -1) {
        throw Exception('Column name $peakHourColumn not found in CSV file');
      }

      // Remove the header row
      rows.removeAt(0);

      final List<ChartData> chartData = [];
      for (var row in rows) {
        if (row.length > columnIndex && row.length > peakHourColumnIndex) {
          try {
            String xValue = row[0].toString();
            double yValue = double.parse(row[columnIndex].toString());
            bool isPeak = row[peakHourColumnIndex].toString() == '1';
            chartData.add(ChartData(xValue, yValue, isPeak: isPeak));
            print('is peak: $row isPeak: $isPeak');
          } catch (e) {
            print('Error parsing row: $row - Error: $e');
          }
        }
      }

      return chartData;
    } else {
      throw Exception('Failed to load peak hour data');
    }
  }  static Future<List<ChartData>> fetchHourlyCO2Data(String url) async {
    final response = await http.get(Uri.parse(url), headers: {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });

    if (response.statusCode == 200) {
      final csvData = utf8.decode(response.bodyBytes);
      final normalizedCsvData = csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      List<List<dynamic>> rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ',').convert(normalizedCsvData);

      final List<ChartData> chartData = [];
      for (var row in rows.skip(1)) {
        String timestamp = row[0].toString();
        double co2 = double.parse(row[2].toString());
        bool isPredicted = row[4].toString() == '1';

        chartData.add(ChartData(timestamp, co2, isPredicted: isPredicted));
      }

      return chartData;
    } else {
      throw Exception('Failed to load hourly CO2 data');
    }
  }
  static Future<List<ChartData>> fetchAQI24hData(String url) async {
    final response = await http.get(Uri.parse(url), headers: {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });

    if (response.statusCode == 200) {
      final csvData = utf8.decode(response.bodyBytes);
      final normalizedCsvData = csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      List<List<dynamic>> rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ',').convert(normalizedCsvData);

      final List<ChartData> chartData = [];
      for (var row in rows.skip(1)) {
        String hour = row[0].toString();
        double pm25 = double.parse(row[1].toString());
        double pm10 = double.parse(row[2].toString());
        chartData.add(ChartData(hour, pm25, pm10: pm10));
      }

      return chartData;
    } else {
      throw Exception('Failed to load AQI 24h data');
    }
  }
}
