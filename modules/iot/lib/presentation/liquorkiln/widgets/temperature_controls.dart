import 'package:flutter/material.dart';

class TemperatureControls extends StatelessWidget {
  final bool isControl1On;
  final bool isControl2On;
  final bool isControl3On;
  final bool isOnline;
  final Function(String, bool) onToggleControl;

  const TemperatureControls({
    Key? key,
    required this.isControl1On,
    required this.isControl2On,
    required this.isControl3On,
    required this.isOnline,
    required this.onToggleControl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Điều khiển nhiệt độ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildControl(
                  'Nhiệt độ 1',
                  isControl1On,
                  () => onToggleControl('control1', isControl1On),
                ),
                _buildControl(
                  'Nhiệt độ 2',
                  isControl2On,
                  () => onToggleControl('control2', isControl2On),
                ),
                _buildControl(
                  'Nhiệt độ 3',
                  isControl3On,
                  () => onToggleControl('control3', isControl3On),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControl(String label, bool isOn, VoidCallback onPressed) {
    return Column(
      children: [
        Switch(
          value: isOn,
          onChanged: isOnline ? (_) => onPressed() : null,
          activeColor: Colors.green,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isOn ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}