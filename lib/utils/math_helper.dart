/// Simple math helper class for testing purposes
class MathHelper {
  /// Adds two numbers
  static int add(int a, int b) {
    return a + b;
  }
  
  /// Subtracts two numbers
  static int subtract(int a, int b) {
    return a - b;
  }
  
  /// Multiplies two numbers
  static int multiply(int a, int b) {
    return a * b;
  }
  
  /// Divides two numbers
  static double divide(int a, int b) {
    if (b == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return a / b;
  }
  
  /// Checks if a number is even
  static bool isEven(int number) {
    return number % 2 == 0;
  }
  
  /// Calculates factorial
  static int factorial(int n) {
    if (n < 0) {
      throw ArgumentError('Factorial is not defined for negative numbers');
    }
    if (n == 0 || n == 1) {
      return 1;
    }
    return n * factorial(n - 1);
  }
}