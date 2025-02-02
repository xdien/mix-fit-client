import 'package:flutter/material.dart';
import 'package:mix_fit/core/data/local/entity/devices_entity.dart';

class DeviceListTile extends StatelessWidget {
  final DeviceEntity device;

  const DeviceListTile({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.device_hub,
        color: device.isOnline as bool ? Colors.green : Colors.grey,
      ),
      title: Text(device.name as String),
      subtitle: Text(device.isOnline as bool ? 'Online' : 'Offline'),
      trailing: Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceDetailScreen(device: device),
          ),
        );
      },
    );
  }
}