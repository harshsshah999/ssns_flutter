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
      final csvData = const Utf8Decoder().convert(response.bodyBytes);
      final normalizedCsvData = csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');  // Normalize all line endings to \n
      List<List<dynamic>> rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ',').convert(normalizedCsvData);
      print('Row length: ${rows.length}'); // Debugging line

      print('CSV Data: $rows'); // Debugging line

      final List<String> headers = rows[0].map((e) => e.toString().trim()).toList();
      final int columnIndex = headers.indexOf(columnName);
      print('Column index for $columnName: $columnIndex'); // Debugging line

      if (columnIndex == -1) {
        throw Exception('Column name $columnName not found in CSV file');
      }

      // Remove the header row
      rows.removeAt(0);

      final List<ChartData> chartData = [];
      for (var row in rows) {
        print('Row: $row'); // Debugging line
        print('Row length: ${row.length}'); // Debugging line

        if (row.length > columnIndex) {
          try {
            String xValue = row[0].toString();
            double yValue = double.parse(row[columnIndex].toString());
            print('Parsed Row - x: $xValue, y: $yValue'); // Debugging line
            chartData.add(ChartData(xValue, yValue));
          } catch (e) {
            print('Error parsing row: $row - Error: $e'); // Debugging line
          }
        } else {
          print('Row does not contain enough elements: $row'); // Debugging line
        }
      }

      print('Parsed Chart Data: $chartData'); // Debugging line

      return chartData;
    } else {
      throw Exception('Failed to load CSV');
    }
  }
}
