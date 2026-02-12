import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report.dart';
import '../models/news.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.18.75:3000';
  final SharedPreferences prefs;

  ApiService(this.prefs);

  Future<String?> _getToken() async {
    return prefs.getString('auth_token');
  }

  // Autenticación
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_id', data['user']['id']);
        return {'success': true};
      }

      final body = json.decode(response.body);
      return {
        'success': false,
        'message':
            body['message'] ?? 'Error ${response.statusCode}: ${response.body}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }

      final body = json.decode(response.body);
      return {
        'success': false,
        'message':
            body['message'] ?? 'Error ${response.statusCode}: ${response.body}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Noticias
  Future<List<News>> getNews() async {
    final token = await _getToken();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/news'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => News.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get news error: $e');
      return [];
    }
  }

  // Reportes
  Future<bool> submitReport(Report report, File image) async {
    final token = await _getToken();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/reports'),
      )..headers['Authorization'] = 'Bearer $token';

      // Agregar campos del reporte
      request.fields['title'] = report.title;
      request.fields['description'] = report.description;
      request.fields['category'] = report.category;
      request.fields['latitude'] = report.latitude.toString();
      request.fields['longitude'] = report.longitude.toString();
      request.fields['status'] = report.status;

      // Agregar imagen
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: '${report.id}.jpg',
        ),
      );

      final response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print('Submit report error: $e');
      return false;
    }
  }

  // Perfil de usuario
  Future<User?> getUserProfile() async {
    final token = await _getToken();
    final userId = prefs.getString('user_id');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final token = await _getToken();
    final userId = prefs.getString('user_id');

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        // Actualizar estado de perfil completo
        await prefs.setBool('profile_complete', true);
        return true;
      }
      return false;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }

  // Obtener reportes del usuario
  Future<List<Report>> getUserReports() async {
    final token = await _getToken();
    final userId = prefs.getString('user_id');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/reports'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Mapping API response to Report objects
        // Assuming API returns data compatible with Report.fromMap/fromJson
        // We might need to adjust if API field names differ from local DB
        return data.map((item) => Report.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get user reports error: $e');
      return [];
    }
  }

  // Sincronización offline
  Future<bool> syncOfflineReports(List<Report> reports) async {
    // Token is retrieved inside submitReport, so we don't strictly need it here
    // unless we want to validate it before looping.
    // final token = await _getToken(); // Removed unused variable

    try {
      for (var report in reports) {
        final image = File(report.imagePath);
        if (image.existsSync()) {
          final success = await submitReport(report, image);
          if (!success) return false;
        }
      }
      return true;
    } catch (e) {
      print('Sync offline reports error: $e');
      return false;
    }
  }
}
