import 'api_service.dart';

class JournauxService {
  Future<dynamic> charger(String token, {int page = 0, int size = 100}) async {
    return ApiService.get(token, '/api/journal?page=$page&size=$size');
  }
}
