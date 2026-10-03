import 'api_service.dart';

class ReglesService {
  Future<dynamic> chargerRegles(String token) async {
    return ApiService.get(token, '/api/regles');
  }

  Future<dynamic> chargerDemandes(String token) async {
    return ApiService.get(token, '/api/demandes');
  }

  Future<dynamic> soumettreDemande(
    String token,
    String path,
    Map<String, dynamic> body,
  ) async {
    return ApiService.post(token, path, body);
  }

  Future<dynamic> approuverDemande(String token, int demandeId) async {
    return ApiService.post(token, '/api/demandes/$demandeId/approuver', {});
  }

  Future<dynamic> rejeterDemande(
      String token, int demandeId, String motif) async {
    return ApiService.post(
      token,
      '/api/demandes/$demandeId/rejeter',
      {'motifRejet': motif},
    );
  }
}
