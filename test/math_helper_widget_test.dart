import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_fit/utils/math_helper.dart';

void main() {
  group('MathHelper Widget Tests', () {
    testWidgets('Calculator widget test', (WidgetTester tester) async {
      // Build a simple calculator widget for testing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Calculator'),
                Text('Result: ${MathHelper.add(2, 3)}'),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Calculate'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify the widget displays the correct result
      expect(find.text('Calculator'), findsOneWidget);
      expect(find.text('Result: 5'), findsOneWidget);
      expect(find.text('Calculate'), findsOneWidget);
      
      // Test button interaction
      await tester.tap(find.text('Calculate'));
      await tester.pump();
      
      // Verify button was tapped (no state change in this simple example)
      expect(find.text('Calculate'), findsOneWidget);
    });
    
    testWidgets('Math operations display test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Addition: ${MathHelper.add(10, 5)}'),
                Text('Subtraction: ${MathHelper.subtract(10, 5)}'),
                Text('Multiplication: ${MathHelper.multiply(10, 5)}'),
                Text('Division: ${MathHelper.divide(10, 5)}'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Addition: 15'), findsOneWidget);
      expect(find.text('Subtraction: 5'), findsOneWidget);
      expect(find.text('Multiplication: 50'), findsOneWidget);
      expect(find.text('Division: 2.0'), findsOneWidget);
    });
  });
}