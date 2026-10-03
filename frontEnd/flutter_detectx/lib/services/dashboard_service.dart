import 'package:http/http.dart' as http;

import 'api_service.dart';

class DashboardService {
  /// Dashboard global - Retourne les stats principales
  /// Répond avec: {
  ///   totalReglesActives, totalReglesEnAttente,
  ///   totalDemandesEnAttente, totalSimulations, totalAlertes,
  ///   dernierePrecision, dernierRappel, dernierF1
  /// }
  Future<dynamic> getDashboard(String token) async {
    return ApiService.get(token, '/api/dashboard');
  }

  // Alertes récentes - API accepte les paramètres de requête
  Future<dynamic> getAlertes(String token, {int? limite}) async {
    final path = limite != null ? '/api/alertes?limit=$limite' : '/api/alertes';
    return ApiService.get(token, path);
  }

  // Demandes récentes
  Future<dynamic> getDemandesRecentes(String token, {int? limite}) async {
    final path =
        limite != null ? '/api/demandes?limit=$limite' : '/api/demandes';
    return ApiService.get(token, path);
  }

  // Demandes en attente
  Future<dynamic> getDemandesEnAttente(String token) async {
    return ApiService.get(token, '/api/demandes/en-attente');
  }

  // Journaux - NOTE: endpoint est /api/journal (pas journaux)
  Future<dynamic> getJournauxRecents(String token, {int? limite}) async {
    final path = limite != null ? '/api/journal?limit=$limite' : '/api/journal';
    return ApiService.get(token, path);
  }

  /// Historique des alertes - Utilise /api/alertes
  /// Le backend retourne toutes les alertes triées par horodatage DESC
  Future<dynamic> getHistoriqueAlertes(String token, {int? limite}) async {
    final path = limite != null ? '/api/alertes?limit=$limite' : '/api/alertes';
    return ApiService.get(token, path);
  }

  /// Règles - Liste complète
  Future<dynamic> getRegles(String token) async {
    return ApiService.get(token, '/api/regles');
  }

  /// Utilisateurs
  Future<dynamic> getUtilisateurs(String token) async {
    return ApiService.get(token, '/api/utilisateurs');
  }

  /// Simulations de l'utilisateur
  Future<dynamic> getMesSimulations(String token) async {
    return ApiService.get(token, '/api/simulation/mes-simulations');
  }

  /// Alertes d'une simulation
  Future<dynamic> getAlertesBySimulation(String token, int simulationId) async {
    return ApiService.get(token, '/api/simulation/$simulationId/alertes');
  }

  Future<http.Response> charger(String token) async {
    return ApiService.get(token, '/api/dashboard');
  }
}
