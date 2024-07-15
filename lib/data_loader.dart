import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'ChartData.dart';
import 'package:intl/intl.dart';  // Import this package

class DataLoader {
  static Future<List<ChartData>> fetchCSVData(String url, String columnName) async {
    try {
      print('Requesting URL: $url');
      final response = await http.get(Uri.parse(url), headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      });

      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final csvData = utf8.decode(response.bodyBytes);
        final normalizedCsvData = csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        List<List<dynamic>> rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ',').convert(normalizedCsvData);

        final List<String> headers = rows[0].map((e) => e.toString().trim()).toList();
        final int columnIndex = headers.indexOf(columnName);

        if (columnIndex == -1) {
          throw Exception('Column name $columnName not found in CSV file');
        }

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
        print('Failed to load CSV: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load CSV');
      }
    } catch (e) {
      print('Exception in fetchCSVData: $e');
      rethrow;
    }
  }

  static Future<List<ChartData>> fetchPeakHourData(String url, String columnName, String peakHourColumn) async {
    try {
      print('Requesting URL: $url');
      final response = await http.get(Uri.parse(url), headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      });

      print('Response status code: ${response.statusCode}');
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

        rows.removeAt(0);

        final List<ChartData> chartData = [];
        for (var row in rows) {
          if (row.length > columnIndex && row.length > peakHourColumnIndex) {
            try {
              String xValue = row[0].toString();
              double yValue = double.parse(row[columnIndex].toString());
              bool isPeak = row[peakHourColumnIndex].toString() == '1';
              chartData.add(ChartData(xValue, yValue, isPeak: isPeak));
            } catch (e) {
              print('Error parsing row: $row - Error: $e');
            }
          }
        }

        return chartData;
      } else {
        print('Failed to load CSV: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load CSV');
      }
    } catch (e) {
      print('Exception in fetchPeakHourData: $e');
      rethrow;
    }
  }

  static Future<List<ChartData>> fetchHourlyCO2Data(String url) async {
    try {
      print('Requesting URL: $url');
      final response = await http.get(Uri.parse(url), headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      });

      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final csvData = utf8.decode(response.bodyBytes);
        final normalizedCsvData = csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        List<List<dynamic>> rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ',').convert(normalizedCsvData);

        final List<ChartData> chartData = [];
        for (var row in rows.skip(1)) {
          try {
            String timestamp = row[0].toString();
            double co2 = double.parse(row[2].toString());
            bool isPredicted = row[4].toString() == '1';
            chartData.add(ChartData(timestamp, co2, isPredicted: isPredicted));
          } catch (e) {
            print('Error parsing row: $row - Error: $e');
          }
        }

        return chartData;
      } else {
        print('Failed to load CSV: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load CSV');
      }
    } catch (e) {
      print('Exception in fetchHourlyCO2Data: $e');
      rethrow;
    }
  }
  static Future<List<ChartData>> fetchPredictedAQIData(String url) async {
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
        double predictedAQI = double.parse(row[1].toString());
        chartData.add(ChartData(hour, predictedAQI));
      }

      return chartData;
    } else {
      throw Exception('Failed to load predicted AQI data');
    }
  }
  static Future<List<ChartData>> fetchAQI24hData(String url) async {
    try {
      print('Requesting URL: $url');
      final response = await http.get(Uri.parse(url), headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      });

      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final csvData = utf8.decode(response.bodyBytes);
        final normalizedCsvData = csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        List<List<dynamic>> rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ',').convert(normalizedCsvData);

        final List<ChartData> chartData = [];
        for (var row in rows.skip(1)) { // Skip header row
          try {
            String timestamp = row[0].toString();
            double pm25 = double.parse(row[1].toString());
            double pm10 = double.parse(row[2].toString());
            double overallAQI = double.parse(row[3].toString());

            // Parse the timestamp correctly
            chartData.add(ChartData(timestamp, pm25, pm10: pm10, overallAQI: overallAQI));
          } catch (e) {
            print('Error parsing row: $row - Error: $e');
          }
        }

        return chartData;
      } else {
        print('Failed to load CSV: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load AQI 24h data');
      }
    } catch (e) {
      print('Exception in fetchAQI24hData: $e');
      rethrow;
    }
  }
  }