import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class PaymentService {
  // Paymob integration for Egypt
  // You'll need to replace these with your actual Paymob credentials
  static const String _paymobApiKey = 'YOUR_PAYMOB_API_KEY';
  static const String _paymobIntegrationId = 'YOUR_INTEGRATION_ID';

  // Initialize payment with Paymob
  Future<Map<String, dynamic>> initializePaymobPayment({
    required int amount,
    required String orderId,
    required Map<String, dynamic> billingData,
  }) async {
    try {
      // Step 1: Get authentication token
      final authToken = await _getPaymobAuthToken();
      
      // Step 2: Create order
      final orderResponse = await _createPaymobOrder(
        authToken: authToken,
        amount: amount,
        orderId: orderId,
      );
      
      // Step 3: Get payment key
      final paymentKey = await _getPaymentKey(
        authToken: authToken,
        amount: amount,
        orderId: orderId,
        billingData: billingData,
        integrationId: _paymobIntegrationId,
      );

      return {
        'success': true,
        'paymentKey': paymentKey,
        'orderId': orderResponse['id'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Returns true if Paymob credentials are configured (not placeholders).
  static bool get isConfigured =>
      _paymobApiKey.isNotEmpty &&
      _paymobApiKey != 'YOUR_PAYMOB_API_KEY' &&
      _paymobIntegrationId != 'YOUR_INTEGRATION_ID';

  Future<String> _getPaymobAuthToken() async {
    if (!isConfigured) {
      throw Exception(
        'Paymob is not configured. Set your API key and Integration ID in lib/services/payment_service.dart (or use env). See Paymob dashboard for credentials.',
      );
    }

    final response = await http.post(
      Uri.parse('https://accept.paymob.com/api/auth/tokens'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'api_key': _paymobApiKey,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Paymob auth: no token in response. Body: ${response.body}');
      }
      return token;
    } else {
      throw Exception(
        'Paymob auth failed (${response.statusCode}). Check your API key. Response: ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> _createPaymobOrder({
    required String authToken,
    required int amount,
    required String orderId,
  }) async {
    final response = await http.post(
      Uri.parse('https://accept.paymob.com/api/ecommerce/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'auth_token': authToken,
        'delivery_needed': 'false',
        'amount_cents': amount * 100, // Convert to piasters
        'currency': 'EGP',
        'merchant_order_id': orderId,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create order');
    }
  }

  Future<String> _getPaymentKey({
    required String authToken,
    required int amount,
    required String orderId,
    required Map<String, dynamic> billingData,
    required String integrationId,
  }) async {
    final response = await http.post(
      Uri.parse('https://accept.paymob.com/api/acceptance/payment_keys'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'auth_token': authToken,
        'amount_cents': amount * 100,
        'expiration': 3600,
        'order_id': orderId,
        'billing_data': billingData,
        'currency': 'EGP',
        'integration_id': integrationId,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      throw Exception('Failed to get payment key');
    }
  }

  // Verify payment callback (to be called from your backend/cloud function)
  Future<bool> verifyPayment(String transactionId) async {
    try {
      final authToken = await _getPaymobAuthToken();
      final response = await http.get(
        Uri.parse(
          'https://accept.paymob.com/api/acceptance/transactions/$transactionId',
        ),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
