import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../di/service_locator.dart';
import '../../home/store/theme/theme_store.dart';
import '../../widgets/app_drawer.dart';
import '../store/liquor_kiln_store.dart';
import '../widgets/temperature_chart.dart';
import '../widgets/connection_status.dart';
import '../widgets/current_temperature.dart';
import '../widgets/temperature_controls.dart';

class LiquorKilnScreen extends StatelessWidget {
  final ThemeStore _themeStore = getIt<ThemeStore>();
  final LiquorKilnStore store = getIt<LiquorKilnStore>(param1: 'esp8266_001'); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(themeStore: _themeStore),
      appBar: AppBar(
        title: Text('Điều khiển lò rượu'),
        actions: [
          Observer(
            builder: (_) => ConnectionStatus(
              isConnected: store.isSocketConnected,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Observer(
              builder: (_) => CurrentTemperature(
                temperature: store.currentTemperature,
                color: store.temperatureColor,
              ),
            ),
            SizedBox(height: 20),
            Observer(
              builder: (_) => TemperatureChart(
                data: store.temperatureData.toList(),
              ),
            ),
            SizedBox(height: 20),
            Observer(
              builder: (_) => TemperatureControls(
                isControl1On: store.isControl1On,
                isControl2On: store.isControl2On,
                isControl3On: store.isControl3On,
                onToggleControl: store.toggleControl,
                isOnline: store.isOnline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
