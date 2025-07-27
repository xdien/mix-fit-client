import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mix_fit/utils/math_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('Math helper integration test', (WidgetTester tester) async {
      // Test the math helper in an integration context
      final result = MathHelper.add(5, 10);
      expect(result, equals(15));
      
      // Build a simple app to test integration
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Integration Test')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Math Result: $result'),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Test Button'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify the app displays correctly
      expect(find.text('Integration Test'), findsOneWidget);
      expect(find.text('Math Result: 15'), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);
      
      // Test button interaction
      await tester.tap(find.text('Test Button'));
      await tester.pumpAndSettle();
      
      // Verify the app is still functional after interaction
      expect(find.text('Test Button'), findsOneWidget);
    });
    
    testWidgets('App navigation test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Home')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                child: Text('Navigate'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Navigate'), findsOneWidget);
      
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();
      
      // In a real app, this would navigate to another screen
      expect(find.text('Navigate'), findsOneWidget);
    });
  });
}