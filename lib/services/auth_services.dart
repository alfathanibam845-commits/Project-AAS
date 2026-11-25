
import 'dart:convert';
import 'api.dart';

class AuthService {
  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email.trim(),
        'password': password,
      });

      final data = Map<String, dynamic>.from(response['data'] ?? {});
      final user = Map<String, dynamic>.from(data['user'] ?? {});

      final token = data['token']?.toString();
      final userId = int.tryParse(user['id']?.toString() ?? '');

      if (token == null || token.isEmpty || userId == null) {
        throw Exception('Token atau ID pengguna tidak ditemukan.');
      }

      // Simpan JWT dan ID pengguna
      await ApiService.saveAuth(token, userId);

      return {
        'success': true,
        'message': response['message'] ?? 'Login berhasil',
        'token': token,
        'user': user,
      };
    } catch (error) {
      throw Exception(_getErrorMessage(error));
    }
  }

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/auth/register', {
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
      });

      final data = Map<String, dynamic>.from(response['data'] ?? {});
      final user = Map<String, dynamic>.from(data['user'] ?? {});

      return {
        'success': true,
        'message': response['message'] ?? 'Register berhasil',
        'user': user,
      };
    } catch (error) {
      throw Exception(_getErrorMessage(error));
    }
  }

  // CEK STATUS LOGIN
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    final userId = await ApiService.getId();

    return token != null &&
        token.isNotEmpty &&
        userId != null;
  }

  // AMBIL TOKEN JWT
  static Future<String?> getToken() async {
    return await ApiService.getToken();
  }

  // AMBIL ID PENGGUNA
  static Future<String?> getUserId() async {
    return await ApiService.getId();
  }

  // LOGOUT
  static Future<void> logout() async {
    await ApiService.logout();
  }

  // PESAN ERROR
  static String _getErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
