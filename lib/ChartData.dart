class ChartData {
  ChartData(this.x, this.y, {this.pm10, this.isPredicted = false, this.isPeak = false});
  final String x;
  final double y;
  final double? pm10;
  final bool isPredicted;
  final bool isPeak;

  @override
  String toString() {
    return 'ChartData(x: $x, y: $y)';
  }
}
