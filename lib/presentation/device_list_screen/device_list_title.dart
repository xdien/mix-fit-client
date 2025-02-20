import 'package:core/local/models/device.dart';
import 'package:flutter/material.dart';

class DeviceListTile extends StatelessWidget {
  final Device device;

  const DeviceListTile({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.device_hub,
        color: device.isOnline ? Colors.green : Colors.grey,
      ),
      title: Text(device.name),
      subtitle: Text(device.isOnline ? 'Online' : 'Offline'),
      trailing: Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Check type of device and navigate to corresponding screen
        UnimplementedError();
      },
    );
  }
}