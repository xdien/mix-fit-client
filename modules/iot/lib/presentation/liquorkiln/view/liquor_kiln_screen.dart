import 'package:app_drawer/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../iot_routes.dart';
import '../../widgets/vintage_control_button.dart';
import '../store/liquor_kiln_store.dart';
import '../widgets/temperature_chart.dart';
import '../widgets/connection_status.dart';
import '../widgets/current_temperature.dart';
import 'package:setting/theme_store.dart';

class LiquorKilnScreen extends StatelessWidget {
  final ThemeStore _themeStore = GetIt.instance<ThemeStore>();
  final LiquorKilnStore store = GetIt.instance<LiquorKilnStore>(param1: 'esp8266_001'); 

  void _openControlScreen(BuildContext context) {
    context.push(IotRoutes.liquorKilnControlPath(store.deviceId));
  }

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
            SizedBox(height: 40),
            Center(
              child: VintageControlButton(
                onPressed: () => _openControlScreen(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
