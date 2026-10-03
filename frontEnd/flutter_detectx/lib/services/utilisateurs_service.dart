import 'api_service.dart';

class UtilisateursService {
  Future<dynamic> charger(String token, {String? role}) async {
    final query = role != null ? '?role=$role' : '';
    return ApiService.get(token, '/api/utilisateurs$query');
  }

  Future<dynamic> suspendre(String token, int id) async {
    return ApiService.put(token, '/api/utilisateurs/$id/suspendre', {});
  }

  Future<dynamic> reactiver(String token, int id) async {
    return ApiService.put(token, '/api/utilisateurs/$id/reactiver', {});
  }

  Future<dynamic> supprimer(String token, int id) async {
    try {
      final response = await ApiService.delete(token, '/api/utilisateurs/$id');
      if (response.statusCode == 404) {
        return ApiService.post(token, '/api/utilisateurs/$id/supprimer', {});
      }
      return response;
    } catch (_) {
      return ApiService.post(token, '/api/utilisateurs/$id/supprimer', {});
    }
  }

  Future<dynamic> creerCompte({
    required String token,
    required String nom,
    required String prenom,
    required String email,
    required String role,
  }) async {
    return ApiService.post(token, '/api/auth/creer-compte', {
      // <-- chemin corrigé
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
    });
  }
}
