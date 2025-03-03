import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../store/liquor_kiln_control_store.dart';

class SystemControlSection extends StatelessWidget {
  final LiquorKilnControlStore store;

  SystemControlSection({
    Key? key,
    required this.store,
  }) : super(key: key) {
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Điều khiển hệ thống',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Reset WiFi Button
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xác nhận'),
                    content: const Text('Bạn có chắc chắn muốn reset WiFi?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          store.resetWifi();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã reset WiFi')),
                          );
                        },
                        child: const Text('Đồng ý'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.wifi_protected_setup),
              label: const Text('Reset WiFi'),
            ),
            const SizedBox(height: 16),
            
            // Update Time Button
            ElevatedButton.icon(
              onPressed: () {
                store.updateSystemTime();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật thời gian hệ thống'),
                  ),
                );
              },
              icon: const Icon(Icons.access_time),
              label: const Text('Cập nhật thời gian'),
            ),
            const SizedBox(height: 16),
            
            // Water Pump Control
            Row(
              children: [
                const Text('Máy bơm nước:'),
                const SizedBox(width: 16),
                Observer(
                  builder: (_) => ElevatedButton.icon(
                    onPressed: () => store.toggleWaterPump(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: store.isWaterPumpOn 
                          ? Colors.green 
                          : null,
                    ),
                    icon: Icon(
                      store.isWaterPumpOn 
                          ? Icons.water_drop
                          : Icons.water_drop_outlined,
                    ),
                    label: Text(
                      store.isWaterPumpOn ? 'Đang chạy' : 'Đã tắt',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}