import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://62.171.140.229/api';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        // SharedPreferences'a eriş
        final prefs = await SharedPreferences.getInstance();
        
        // Token'ı kaydet
        await prefs.setString('token', data['token']);
        await prefs.setBool('isLoggedIn', true);
        
        // Tüm kullanıcı bilgilerini JSON olarak kaydet
        await prefs.setString('user', json.encode(data['user']));
        
        // Sık kullanılan bilgileri ayrıca kaydet
        final user = data['user'];
        await prefs.setInt('userId', user['id']);
        await prefs.setString('userName', user['name']);
        await prefs.setString('userSurname', user['surname']);
        await prefs.setString('userEmail', user['email']);

        return {
          'status': true,
          'data': data,
        };
      } else {
        return {
          'status': false,
          'message': data['message'] ?? 'Giriş başarısız',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Bir hata oluştu: ${e.toString()}',
      };
    }
  }

  // Kullanıcı bilgilerini al
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Önce sık kullanılan bilgileri kontrol et
      final userId = prefs.getInt('userId');
      final userName = prefs.getString('userName');
      final userSurname = prefs.getString('userSurname');
      final userEmail = prefs.getString('userEmail');
      
      if (userId != null && userName != null) {
        // Sık kullanılan bilgiler varsa onları döndür
        return {
          'id': userId,
          'name': userName,
          'surname': userSurname,
          'email': userEmail,
        };
      }
      
      // Sık kullanılan bilgiler yoksa tüm JSON'ı kontrol et
      final userString = prefs.getString('user');
      if (userString != null) {
        return json.decode(userString);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Token'ı al
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      return null;
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Kullanıcı adını al
  Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userName');
    } catch (e) {
      return null;
    }
  }

  // Kullanıcı ID'sini al
  Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('userId');
    } catch (e) {
      return null;
    }
  }
} 