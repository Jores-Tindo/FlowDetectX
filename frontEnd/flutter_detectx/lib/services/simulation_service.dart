import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class SimulationService {
  Future<http.Response> demarrerSimulation(String token) async {
    return _sendRequest('POST', token, '/api/simulation/demarrer');
  }

  Future<bool> arreterSimulation(String token, int simulationId) async {
    final endpoints = [
      ('POST', '/api/simulation/$simulationId/arreter'),
      ('POST', '/api/simulation/arreter/$simulationId'),
      ('POST', '/api/simulation/stop/$simulationId'),
      ('PUT', '/api/simulation/$simulationId/stop'),
      ('DELETE', '/api/simulation/$simulationId'),
    ];

    for (final (method, path) in endpoints) {
      try {
        final response = await _sendRequest(method, token, path);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  Future<dynamic> listerSimulations(String token) async {
    return ApiService.get(token, '/api/simulation/mes-simulations');
  }

  Future<http.Response> _sendRequest(
    String method,
    String token,
    String path,
  ) async {
    final uri = ApiService.uri(path);
    final headers = ApiService.headers(token);

    switch (method) {
      case 'POST':
        return http
            .post(uri, headers: headers, body: jsonEncode({}))
            .timeout(const Duration(seconds: 8));
      case 'PUT':
        return http
            .put(uri, headers: headers, body: jsonEncode({}))
            .timeout(const Duration(seconds: 8));
      case 'DELETE':
        return http
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 8));
      default:
        throw UnsupportedError('Méthode non supportée: $method');
    }
  }
}
