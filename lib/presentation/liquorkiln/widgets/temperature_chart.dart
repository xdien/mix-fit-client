import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TemperatureChart extends StatelessWidget {
  final List<FlSpot> data;

  const TemperatureChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biểu đồ nhiệt độ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Expanded(
                child: _buildChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: _buildGridData(),
        titlesData: _buildTitlesData(),
        borderData: _buildBorderData(),
        lineBarsData: _buildLineBarsData(),
        minX: data.isEmpty ? 0 : data.first.x,
        maxX: data.isEmpty ? 0 : data.last.x,
        minY: _calculateMinY(),
        maxY: _calculateMaxY(),
      ),
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      horizontalInterval: 10,
      verticalInterval: _calculateTimeInterval(),
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.grey.withOpacity(0.3),
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: Colors.grey.withOpacity(0.3),
          strokeWidth: 1,
        );
      },
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            );
          },
          interval: _calculateTimeInterval(),
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                '${value.toInt()}°C',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            );
          },
          interval: 20,
        ),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(
        color: Colors.grey.withOpacity(0.5),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    return [
      LineChartBarData(
        spots: data,
        isCurved: true,
        color: _getLineColor(),
        barWidth: 2,
        dotData: FlDotData(
          show: false,
        ),
        belowBarData: BarAreaData(
          show: true,
          color: _getLineColor().withOpacity(0.2),
        ),
      ),
    ];
  }

  double _calculateMinY() {
    if (data.isEmpty) return 0;
    final minTemp = data.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    return (minTemp - 10).clamp(0, double.infinity);
  }

  double _calculateMaxY() {
    if (data.isEmpty) return 100;
    final maxTemp = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return maxTemp + 10;
  }

  double _calculateTimeInterval() {
    if (data.length < 2) return 1;
    final timeSpan = data.last.x - data.first.x;
    // Hiển thị khoảng 6 điểm trên trục x
    return timeSpan / 6;
  }

  Color _getLineColor() {
    if (data.isEmpty) return Colors.blue;
    final lastTemp = data.last.y;
    if (lastTemp > 80) return Colors.red;
    if (lastTemp > 50) return Colors.orange;
    return Colors.blue;
  }
}