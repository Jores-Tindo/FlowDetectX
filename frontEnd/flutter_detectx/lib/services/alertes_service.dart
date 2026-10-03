import 'api_service.dart';

class AlertesService {
  Future<dynamic> charger(String token, {int? simulationId}) async {
    final path = simulationId != null
        ? '/api/simulation/$simulationId/alertes'
        : '/api/alertes';
    return ApiService.get(token, path);
  }
}
