import 'api_service.dart';

class HistoriqueService {
  /// Récupère l'historique des alertes
  /// Utilise /api/alertes qui retourne toutes les alertes triées par horodatage
  /// La pagination côté frontend est gérée par le provider
  Future<dynamic> getHistoriqueAlertes(
    String token, {
    int jours = 30,
    String? criticite,
  }) async {
    // Construire les paramètres de requête
    final params = <String>[];
    if (criticite != null) params.add('criticite=$criticite');

    final path =
        '/api/alertes${params.isNotEmpty ? '?${params.join('&')}' : ''}';
    return ApiService.get(token, path);
  }

  /// Récupère les alertes filtrées par criticité
  /// Utilise le paramètre ?criticite= de /api/alertes
  Future<dynamic> getAlertesByCriticite(
    String token, {
    required String criticite,
  }) async {
    return ApiService.get(token, '/api/alertes?criticite=$criticite');
  }

  /// Récupère les alertes par ID (une alerte spécifique)
  Future<dynamic> getAlerteById(String token, int alerteId) async {
    return ApiService.get(token, '/api/alertes/$alerteId');
  }

  /// Récupère les demandes de validation
  /// Les demandes peuvent servir à suivre les actions sur les règles
  Future<dynamic> getDemandes(String token,
      {String? statut, bool pourValidateurMois = false}) async {
    final params = <String>[];
    if (statut != null && statut.isNotEmpty) {
      params.add('statut=$statut');
    }
    if (pourValidateurMois) {
      params.add('validateur=moi');
    }
    final path =
        '/api/demandes${params.isNotEmpty ? '?${params.join('&')}' : ''}';
    return ApiService.get(token, path);
  }

  /// Récupère les demandes en attente de validation
  Future<dynamic> getDemandesEnAttente(String token) async {
    return ApiService.get(token, '/api/demandes/en-attente');
  }

  /// Récupère le journal d'activité
  /// Utile pour l'historique des actions
  Future<dynamic> getJournal(String token) async {
    return ApiService.get(token, '/api/journal');
  }

  /// Récupère le journal d'activité d'un utilisateur
  Future<dynamic> getJournalUtilisateur(String token, int userId) async {
    return ApiService.get(token, '/api/journal/utilisateur/$userId');
  }

  /// NOTE: Les endpoints suivants n'existent pas dans le backend:
  /// - /api/analytics/* (statistiques et tendances)
  /// - /api/dashboard/statistiques-complet
  /// - /api/alertes/export
  ///
  /// À la place, on utilise les données disponibles:
  /// - /api/alertes (toutes les alertes)
  /// - /api/dashboard (stats générales)
  /// - /api/demandes (demandes de validation)
  /// - /api/journal (historique d'activité)
  ///
  /// Le frontend doit calculer les stats et tendances à partir des données brutes.
}
