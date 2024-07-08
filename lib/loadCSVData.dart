import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}

Future<List<ChartData>> loadCSVData(String filePath, String columnName) async {
  final csvData = await rootBundle.loadString(filePath);
  final List<List<dynamic>> rows = CsvToListConverter().convert(csvData);

  // Get the index of the column name
  final int columnIndex = rows[0].indexOf(columnName);

  if (columnIndex == -1) {
    throw Exception('Column name $columnName not found in CSV file');
  }

  final List<ChartData> chartData = [];
  for (var row in rows.skip(1)) { // Skip header row
    chartData.add(ChartData(row[0].toString(), double.parse(row[columnIndex].toString())));
  }

  return chartData;
}

