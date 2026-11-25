
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:item_shop/models/product_model.dart';

class ApiService {
  // Backend Express
  static const String baseUrl = 
   'http://localhost:5002/api/v1';  

  // SharedPreferences keys
  static const String _tokenKey = 'itemshop-token';
  static const String _idKey = 'itemshop-user-id';

  // Membuat URL endpoint
  static Uri _uri(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';

    return Uri.parse('$baseUrl$cleanEndpoint');
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  static Future<void> saveAuth(String token, int id) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_idKey, id.toString());
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_idKey);
  }

  // ==========================================
  // HEADERS
  // ==========================================

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ==========================================
  // RESPONSE HANDLER
  // ==========================================

  static dynamic _decode(http.Response response) {
    dynamic body;

    try {
      body = response.body.isEmpty
          ? null
          : jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Server mengirim respons bukan JSON '
        '(HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return body;
    }

    final message = body is Map ? body['message'] : null;

    throw Exception(
      message?.toString() ??
          'Request gagal (HTTP ${response.statusCode}).',
    );
  }

  // ==========================================
  // GET
  // ==========================================

  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(
            _uri(endpoint),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 25));

      return _decode(response);
    } catch (e) {
      throw _networkError(e);
    }
  }

  // ==========================================
  // POST JSON
  // ==========================================

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            _uri(endpoint),
            headers: await _headers(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 25));

      return _decode(response);
    } catch (e) {
      throw _networkError(e);
    }
  }

  // ==========================================
  // DELETE
  // ==========================================

  static Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            _uri(endpoint),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 25));

      return _decode(response);
    } catch (e) {
      throw _networkError(e);
    }
  }

  // ==========================================
  // POST / PUT MULTIPART
  // CREATE & UPDATE PRODUCT
  // ==========================================

  static Future<dynamic> postMultiPart({
    required String endpoint,
    required Map<String, dynamic> data,
    XFile? image,
    String method = 'POST',
  }) async {
    try {
      final request = http.MultipartRequest(
        method,
        _uri(endpoint),
      );

      final token = await getToken();

      request.headers['Accept'] = 'application/json';

      // JWT Authentication
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Product fields
      request.fields.addAll(
        data.map(
          (key, value) => MapEntry(
            key,
            value.toString(),
          ),
        ),
      );

      // Image is optional for UPDATE
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: image.name,
          ),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamed);

      return _decode(response);
    } catch (e) {
      throw _networkError(e);
    }
  }

  // ==========================================
  // GET PRODUCTS USING PRODUCT MODEL
  // ==========================================

  Future<List<ProductModel>> getProducts() async {
    final response = await ApiService.get('/products');

    final responseData = Map<String, dynamic>.from(response);

    final data = Map<String, dynamic>.from(
      responseData['data'] ?? {},
    );

    final List<dynamic> productList =
        data['products'] ?? [];

    return productList
        .map(
          (item) => ProductModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ==========================================
  // NETWORK ERROR HANDLER
  // ==========================================

  static Exception _networkError(Object error) {
    final message = error.toString();

    if (message.contains('Failed to fetch') ||
        message.contains('ClientException') ||
        message.contains('SocketException')) {
      return Exception(
        'Tidak dapat terhubung ke backend. '
        'Pastikan Express berjalan di '
        'http://localhost:5002 dan CORS mengizinkan Flutter Web.',
      );
    }

    return Exception(
      message.replaceFirst('Exception: ', ''),
    );
  }

  // ==========================================
// PUT JSON
// ==========================================

static Future<dynamic> put(
  String endpoint,
  Map<String, dynamic> data,
) async {
  try {
    final response = await http
        .put(
          _uri(endpoint),
          headers: await _headers(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 25));

    return _decode(response);
  } catch (e) {
    throw _networkError(e);
  }
}
}
