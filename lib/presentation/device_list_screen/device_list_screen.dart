import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import 'device_list_title.dart';
import 'store/device_store.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceStore = Provider.of<DeviceStore>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('IoT Devices'),
        actions: [
          Observer(
            builder: (_) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'Online: ${deviceStore.totalOnlineDevices}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Observer(
        builder: (_) => ListView.builder(
          itemCount: deviceStore.devices.length,
          itemBuilder: (context, index) {
            final device = deviceStore.devices[index];
            return DeviceListTile(device: device);
          },
        ),
      ),
    );
  }
}
