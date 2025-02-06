import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../home/store/theme/theme_store.dart';
import '../liquorkiln/widgets/connection_status.dart';
import 'store/liquor_kiln_control_store.dart';
import '../../di/service_locator.dart';

class LiquorKilnControlScreen extends StatelessWidget {
  final String deviceId;
  final ThemeStore _themeStore = getIt<ThemeStore>();
  late final LiquorKilnControlStore store;

  LiquorKilnControlScreen({
    Key? key,
    required this.deviceId,
  }) : super(key: key) {
    store = getIt<LiquorKilnControlStore>(param1: deviceId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Heater Control Section
              // HeaterControlSection(store: store),
              
              // Temperature Settings Section
              // TemperatureSettingsSection(store: store),
              
              // Distillation Control Section
              // DistillationControlSection(store: store),
              
              // System Control Section
              // SystemControlSection(store: store),
            ],
          ),
        ),
      ),
    );
  }
}