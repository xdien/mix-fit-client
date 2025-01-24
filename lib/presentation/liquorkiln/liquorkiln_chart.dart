import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mix_fit/data/network/apis/lib/api.dart';
import 'package:mix_fit/di/service_locator.dart';
import 'package:mix_fit/domain/usecase/iot/get_liquorklin_online_steam_usecase.dart';
import 'package:mix_fit/domain/usecase/iot/get_temperature_stream_usecase.dart';
import '../../core/domain/usecase/use_case.dart';
import '../../domain/usecase/websocket/get_connection_status_usecase.dart';

class LiquorKilnScreen extends StatefulWidget {

  @override
  _LiquorKilnScreenState createState() => _LiquorKilnScreenState();
}

class _LiquorKilnScreenState extends State<LiquorKilnScreen> {
  final List<FlSpot> temperatureData = [];
  bool isSocketConnected = false;
  bool isOnline = false;
  double currentTemperature = 0.0;

  late final StreamSubscription<SensorDataEventDto> _temperatureSubscription;
  late final StreamSubscription<bool> _connectionSubscription;
  late final StreamSubscription<DeviceStatusEventDto> _onlineSubscription;
  final GetConnectionStatusUseCase getConnectionStatusUseCase = getIt<GetConnectionStatusUseCase>();
  final GetLiquorKilnStreamUseCase getLiquorKilnStreamUseCase = getIt<GetLiquorKilnStreamUseCase>();
  final GetLiquorKilnOnlineStreamUseCase getLiquorKilnOnlineStreamUseCase = getIt<GetLiquorKilnOnlineStreamUseCase>();

  @override
  void initState() {
    super.initState();
    _setupSubscriptions();
  }

  void _setupSubscriptions() async{
    // Subscribe to temperature updates
    _temperatureSubscription = await getLiquorKilnStreamUseCase.call(params: NoParams()).listen(
      (data) {
        setState(() {
          var metrics = data.telemetryData.metrics;
          for (var metric in metrics) {
            if (metric.name == 'oli_temperature') {
              currentTemperature = (metric.value as num).toDouble();
              final timestamp = data.telemetryData.timestamp.millisecondsSinceEpoch.toDouble();
              temperatureData.add(FlSpot(timestamp, currentTemperature));
              break;
            }
          }
          if (temperatureData.length > 60) {
            temperatureData.removeAt(0);
          }
        });
      },
    );
    _connectionSubscription =
        getConnectionStatusUseCase.call(params: NoParams()).listen(
      (connected) {
        setState(() {
          isSocketConnected = connected;
        });
      },
    );
    _onlineSubscription = await getLiquorKilnOnlineStreamUseCase.call(params: 'device_id').listen(
      (deviceStatus) {
        setState(() {
          isOnline = deviceStatus.status == DeviceStatusEventDtoStatusEnum.ONLINE;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Điều khiển lò rượu'),
        actions: [
          _buildConnectionStatus(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentTemperature(),
            SizedBox(height: 20),
            _buildTemperatureChart(),
            SizedBox(height: 20),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSocketConnected ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(width: 8),
          Text(isSocketConnected ? 'Online' : 'Offline'),
        ],
      ),
    );
  }

  Widget _buildCurrentTemperature() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhiệt độ hiện tại:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              '$currentTemperature°C',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _getTemperatureColor(currentTemperature),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureChart() {
    return Container(
      height: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: temperatureData,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Điều khiển',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildControlButton(
                  icon: Icons.power_settings_new,
                  label: 'Bật/Tắt',
                  onPressed: _togglePower,
                ),
                _buildControlButton(
                  icon: Icons.thermostat,
                  label: 'Cài đặt nhiệt độ',
                  onPressed: _showTemperatureDialog,
                ),
                _buildControlButton(
                  icon: Icons.timer,
                  label: 'Hẹn giờ',
                  onPressed: _showTimerDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          iconSize: 32,
        ),
        SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  void _togglePower() {
    if (isOnline) {
      // Implement power toggle
    }
  }

  void _showTemperatureDialog() {
    // Implement temperature setting dialog
  }

  void _showTimerDialog() {
    // Implement timer setting dialog
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature > 80) {
      return Colors.red;
    } else if (temperature > 50) {
      return Colors.orange;
    }
    return Colors.green;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
