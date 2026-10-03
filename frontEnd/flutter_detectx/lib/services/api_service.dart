import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // Utilise ApiConfig pour détecter automatiquement l'URL selon la plateforme
  static String baseUrl = ApiConfig.baseUrl;

  // Headers avec JWT
  static Map<String, String> headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Map<String, String> headersPublic() => {
        'Content-Type': 'application/json',
      };

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Uri uri(String path) => _uri(path);

  static void configureBaseUrl(String url) {
    baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    debugPrint('[API] Base URL configurée: $baseUrl');
  }

  static void resetBaseUrl() {
    baseUrl = ApiConfig.baseUrl;
    debugPrint('[API] Base URL réinitialisée: $baseUrl');
  }

  // POST public (login, activation, etc.)
  static Future<http.Response> postPublic(
      String path, Map<String, dynamic> body) async {
    final url = _uri(path);
    debugPrint('[API POST PUBLIC] $url');
    debugPrint('[API POST PUBLIC] Body: $body');
    try {
      final response = await http
          .post(
        url,
        headers: headersPublic(),
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('[API POST PUBLIC] ⏱️ TIMEOUT (30s): $url');
          return http.Response(
              '{"message": "Timeout - Serveur injoignable"}', 408,
              request: http.Request('POST', url));
        },
      );
      debugPrint(
          '[API POST PUBLIC] Status: ${response.statusCode} - ${url.path}');
      debugPrint('[API POST PUBLIC] Response: ${response.body}');
      return response;
    } catch (e, stackTrace) {
      debugPrint('[API POST PUBLIC] Exception: $url - $e');
      debugPrint('[API POST PUBLIC] StackTrace: $stackTrace');
      return http.Response('{"message": "Erreur de connexion: $e"}', 500,
          request: http.Request('POST', url));
    }
  }

  // POST authentifié
  static Future<http.Response> post(
      String token, String path, Map<String, dynamic> body) async {
    final url = _uri(path);
    debugPrint('[API POST] $url');
    try {
      final response = await http
          .post(
        url,
        headers: headers(token),
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('[API POST] ⏱️ TIMEOUT (30s): $url');
          return http.Response('Timeout', 408);
        },
      );
      debugPrint('[API POST] Status: ${response.statusCode} - ${url.path}');
      return response;
    } catch (e) {
      debugPrint('[API POST] Exception: $url - $e');
      rethrow;
    }
  }

  // GET authentifié
  static Future<http.Response> get(String token, String path) async {
    final url = _uri(path);
    debugPrint('[API GET] $url');
    try {
      final response = await http
          .get(
        url,
        headers: headers(token),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('[API GET] ⏱️ TIMEOUT (30s): $url');
          return http.Response('Timeout', 408);
        },
      );
      debugPrint('[API GET] Status: ${response.statusCode} - ${url.path}');
      if (response.statusCode != 200) {
        debugPrint('[API GET] Erreur ${response.statusCode}: ${response.body}');
      }
      return response;
    } catch (e) {
      debugPrint('[API GET] Exception: $url - $e');
      rethrow;
    }
  }

  // PUT authentifié
  static Future<http.Response> put(
      String token, String path, Map<String, dynamic> body) async {
    final response = await http.put(
      _uri(path),
      headers: headers(token),
      body: jsonEncode(body),
    );
    return response;
  }

  // DELETE authentifié
  static Future<http.Response> delete(String token, String path) async {
    final url = _uri(path);
    debugPrint('[API DELETE] $url');
    try {
      final response = await http
          .delete(
        url,
        headers: headers(token),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('[API DELETE] ⏱️ TIMEOUT (30s): $url');
          return http.Response('Timeout', 408);
        },
      );
      debugPrint('[API DELETE] Status: ${response.statusCode} - ${url.path}');
      return response;
    } catch (e) {
      debugPrint('[API DELETE] Exception: $url - $e');
      rethrow;
    }
  }
}
