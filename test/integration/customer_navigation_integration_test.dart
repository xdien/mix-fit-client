import 'package:flutter_test/flutter_test.dart';
import 'package:constants/app_routes.dart';

/// Integration test for customer navigation functionality
/// Tests the navigation routes and constants are properly configured
void main() {
  group('Customer Navigation Integration Tests', () {
    test('should have customer routes defined in AppRoutes', () {
      // Verify that customer routes are properly defined
      expect(AppRoutes.customers, equals('/customers'));
      expect(AppRoutes.customerAdd, equals('/customers/add'));
      expect(AppRoutes.customerSelectionDemo, equals('/customers/selection-demo'));
      
      // Test dynamic route generation
      final editRoute = AppRoutes.customerEdit('123');
      expect(editRoute, equals('/customers/123/edit'));
    });

    test('should have consistent route naming', () {
      // Verify route naming follows consistent pattern
      expect(AppRoutes.customers, startsWith('/customers'));
      expect(AppRoutes.customerAdd, startsWith('/customers'));
      expect(AppRoutes.customerSelectionDemo, startsWith('/customers'));
      
      final editRoute = AppRoutes.customerEdit('test-id');
      expect(editRoute, startsWith('/customers'));
      expect(editRoute, contains('test-id'));
      expect(editRoute, endsWith('/edit'));
    });

    test('should generate valid edit routes with different IDs', () {
      // Test with various ID formats
      final testIds = ['123', 'abc-def', 'user_001', 'CUSTOMER-456'];
      
      for (final id in testIds) {
        final route = AppRoutes.customerEdit(id);
        expect(route, equals('/customers/$id/edit'));
        expect(route, contains(id));
      }
    });
  });
}