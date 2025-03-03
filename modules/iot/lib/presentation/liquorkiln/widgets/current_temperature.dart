import 'package:flutter/material.dart';

class CurrentTemperature extends StatelessWidget {
  final double temperature;
  final Color color;

  const CurrentTemperature({
    Key? key,
    required this.temperature,
    required this.color,
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
              'Nhiệt độ hiện tại:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              '$temperature°C',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}