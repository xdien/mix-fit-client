import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:customer_management/customer_management.dart';

class CustomerApiService {
  final Dio _dio;
  final String _baseUrl;

  CustomerApiService({required Dio dio, required String baseUrl})
      : _dio = dio,
        _baseUrl = baseUrl;

  // Get all customers with pagination and search
  Future<Map<String, dynamic>> getCustomers({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await _dio.get(
        '$_baseUrl/api/cms/customers',
        queryParameters: queryParameters,
      );

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get customer by ID
  Future<Map<String, dynamic>> getCustomerById(String id) async {
    try {
      final response = await _dio.get('$_baseUrl/api/cms/customers/$id');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Create new customer
  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> customerData) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/cms/customers',
        data: customerData,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Update customer
  Future<Map<String, dynamic>> updateCustomer(String id, Map<String, dynamic> customerData) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/api/cms/customers/$id',
        data: customerData,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Delete customer
  Future<void> deleteCustomer(String id) async {
    try {
      await _dio.delete('$_baseUrl/api/cms/customers/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Search customer by phone
  Future<Map<String, dynamic>> getCustomerByPhone(String phone) async {
    try {
      final response = await _dio.get('$_baseUrl/api/cms/customers/search/phone/$phone');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Search customer by email
  Future<Map<String, dynamic>> getCustomerByEmail(String email) async {
    try {
      final response = await _dio.get('$_baseUrl/api/cms/customers/search/email/$email');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Convert API response to Customer model
  Customer _mapToCustomer(Map<String, dynamic> data) {
    return Customer(
      id: data['id'],
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      address: data['address'],
      status: _mapStatus(data['status']),
      isApproved: data['isApproved'] ?? false,
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
    );
  }

  CustomerStatus _mapStatus(String? status) {
    switch (status) {
      case 'synced':
        return CustomerStatus.synced;
      case 'pendingSync':
        return CustomerStatus.pendingSync;
      case 'syncError':
        return CustomerStatus.syncError;
      default:
        return CustomerStatus.draft;
    }
  }

  // Error handling
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('Connection timeout. Please check your internet connection.');
        
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;
          
          if (statusCode == 400) {
            return Exception('Invalid data: ${responseData?['message'] ?? 'Bad request'}');
          } else if (statusCode == 401) {
            return Exception('Unauthorized. Please login again.');
          } else if (statusCode == 403) {
            return Exception('Access denied. You don\'t have permission to perform this action.');
          } else if (statusCode == 404) {
            return Exception('Customer not found.');
          } else if (statusCode == 409) {
            return Exception('Conflict: ${responseData?['message'] ?? 'Data conflict'}');
          } else if (statusCode == 500) {
            return Exception('Server error. Please try again later.');
          } else {
            return Exception('Error ${statusCode}: ${responseData?['message'] ?? 'Unknown error'}');
          }
        
        case DioExceptionType.cancel:
          return Exception('Request was cancelled.');
        
        case DioExceptionType.connectionError:
          return Exception('No internet connection. Please check your network.');
        
        default:
          return Exception('Network error: ${error.message}');
      }
    }
    
    return Exception('Unexpected error: $error');
  }
} 