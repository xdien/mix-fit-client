import 'package:flutter_test/flutter_test.dart';
import 'package:mix_fit/utils/math_helper.dart';

void main() {
  group('MathHelper Tests', () {
    test('addition test', () {
      expect(MathHelper.add(2, 3), equals(5));
      expect(MathHelper.add(-1, 1), equals(0));
      expect(MathHelper.add(0, 0), equals(0));
    });
    
    test('subtraction test', () {
      expect(MathHelper.subtract(5, 3), equals(2));
      expect(MathHelper.subtract(1, 1), equals(0));
      expect(MathHelper.subtract(0, 5), equals(-5));
    });
    
    test('multiplication test', () {
      expect(MathHelper.multiply(3, 4), equals(12));
      expect(MathHelper.multiply(0, 5), equals(0));
      expect(MathHelper.multiply(-2, 3), equals(-6));
    });
    
    test('division test', () {
      expect(MathHelper.divide(10, 2), equals(5.0));
      expect(MathHelper.divide(7, 2), equals(3.5));
      expect(() => MathHelper.divide(5, 0), throwsArgumentError);
    });
    
    test('isEven test', () {
      expect(MathHelper.isEven(2), isTrue);
      expect(MathHelper.isEven(3), isFalse);
      expect(MathHelper.isEven(0), isTrue);
      expect(MathHelper.isEven(-2), isTrue);
      expect(MathHelper.isEven(-3), isFalse);
    });
    
    test('factorial test', () {
      expect(MathHelper.factorial(0), equals(1));
      expect(MathHelper.factorial(1), equals(1));
      expect(MathHelper.factorial(5), equals(120));
      expect(() => MathHelper.factorial(-1), throwsArgumentError);
    });
  });
  
  group('Basic Tests', () {
    test('simple math test', () {
      expect(2 + 2, equals(4));
    });
    
    test('string test', () {
      expect('hello'.toUpperCase(), equals('HELLO'));
    });
    
    test('list test', () {
      final list = [1, 2, 3];
      expect(list.length, equals(3));
      expect(list.contains(2), isTrue);
    });
  });
  
  group('Edge Cases', () {
    test('null safety test', () {
      String? nullableString;
      expect(nullableString, isNull);
      
      nullableString = 'not null';
      expect(nullableString, isNotNull);
      expect(nullableString!.length, equals(8));
    });
  });
}
