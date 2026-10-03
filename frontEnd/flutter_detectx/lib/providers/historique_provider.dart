import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/historique_service.dart';

/// Provider pour gérer les données historiques et statistiques
class HistoriqueProvider extends ChangeNotifier {
  final HistoriqueService _service = HistoriqueService();

  // Historique alertes
  List<Map<String, dynamic>> _historiqueAlertes = [];
  List<Map<String, dynamic>> _demandesHistorique = [];

  // Statistiques par jour
  List<Map<String, dynamic>> _statsParJour = [];

  // Tendances
  List<Map<String, dynamic>> _tendancesAlertes = [];

  // Alertes par type
  Map<String, int> _alertesByType = {};

  // Métriques globales
  int _totalAlertes30j = 0;
  int _alertesCritiques30j = 0;

  bool _isLoading = false;
  String? _erreur;

  // Getters
  List<Map<String, dynamic>> get historiqueAlertes =>
      List.unmodifiable(_historiqueAlertes);
  List<Map<String, dynamic>> get demandesHistorique =>
      List.unmodifiable(_demandesHistorique);
  List<Map<String, dynamic>> get statsParJour =>
      List.unmodifiable(_statsParJour);
  List<Map<String, dynamic>> get tendancesAlertes =>
      List.unmodifiable(_tendancesAlertes);
  Map<String, int> get alertesByType => Map.unmodifiable(_alertesByType);

  int get totalAlertes30j => _totalAlertes30j;
  int get alertesCritiques30j => _alertesCritiques30j;

  bool get isLoading => _isLoading;
  String? get erreur => _erreur;

  /// Charge l'historique des alertes depuis /api/alertes
  /// Le backend retourne toutes les alertes, le frontend les filtre par date
  Future<void> chargerHistoriqueAlertes(
    String token, {
    int jours = 30,
    String? criticite,
  }) async {
    _isLoading = true;
    _erreur = null;
    notifyListeners();

    try {
      debugPrint('[📜 Historique] Chargement alertes...');
      final response = await _service.getHistoriqueAlertes(
        token,
        jours: jours,
        criticite: criticite,
      );

      debugPrint('[Historique] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var data = response.body.isEmpty ? [] : jsonDecode(response.body);

        if (data is Map && data.containsKey('data')) {
          data = data['data'] ?? [];
        }

        if (data is List) {
          _historiqueAlertes = data
              .map((a) => _parseAlerte(a as Map))
              .whereType<Map<String, dynamic>>()
              .toList();

          debugPrint(
              '[Historique] ✓ ${_historiqueAlertes.length} alertes chargées');
          _calculerMetriques();
        }
        notifyListeners();
      } else {
        _erreur =
            'Erreur lors du chargement de l\'historique (${response.statusCode}).';
        debugPrint('[Historique] ❌ $_erreur');
        notifyListeners();
      }
    } catch (e) {
      _erreur = 'Erreur de connexion: $e';
      debugPrint('[Historique] ❌ Exception: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> chargerDemandesHistorique(String token) async {
    if (token.isEmpty) {
      _demandesHistorique = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _erreur = null;
    notifyListeners();

    try {
      debugPrint('[📜 Historique] Chargement des demandes traitées...');
      final response = await _service.getDemandes(token,
          statut: 'APPROUVEE,REJETEE', pourValidateurMois: true);
      debugPrint('[Historique] Status demandes: ${response.statusCode}');

      if (response.statusCode == 200) {
        var data = response.body.isEmpty ? [] : jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) {
          data = data['data'] ?? [];
        }

        if (data is List) {
          _demandesHistorique = data
              .map((d) => _parseDemande(d as Map))
              .whereType<Map<String, dynamic>>()
              .where(
                  (d) => d['statut'] == 'APPROUVEE' || d['statut'] == 'REJETEE')
              .toList();
        } else {
          _demandesHistorique = [];
          debugPrint(
              '[Historique] Format inattendu demandes: ${data.runtimeType}');
        }
        notifyListeners();
      } else {
        _erreur = 'Erreur de chargement des demandes (${response.statusCode}).';
        debugPrint('[Historique] ❌ $_erreur');
        notifyListeners();
      }
    } catch (e) {
      _erreur = 'Erreur de connexion: $e';
      debugPrint('[Historique] ❌ Exception: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les statistiques par jour (calculées à partir des alertes)
  /// Le backend n'a pas d'endpoint analytics, on calcule côté frontend
  Future<void> chargerStatsParJour(String token, {int jours = 30}) async {
    try {
      debugPrint('[📊 Stats] Calcul des statistiques par jour...');

      // Charger toutes les alertes d'abord si pas déjà chargées
      if (_historiqueAlertes.isEmpty) {
        await chargerHistoriqueAlertes(token, jours: jours);
      }

      // Calculer les stats par jour (grouper les alertes par date)
      Map<String, int> statsByDate = {};
      for (var alerte in _historiqueAlertes) {
        if (alerte['horodatage'] != null) {
          String date = alerte['horodatage'].toString().split(' ')[0];
          statsByDate[date] = (statsByDate[date] ?? 0) + 1;
        }
      }

      _statsParJour = statsByDate.entries
          .map((e) => {'date': e.key, 'count': e.value})
          .toList();

      debugPrint('[Stats] ✓ ${_statsParJour.length} jours avec alertes');
      notifyListeners();
    } catch (e) {
      debugPrint('[Stats] ❌ Erreur: $e');
    }
  }

  /// Charge les tendances des alertes (calculées à partir des alertes)
  Future<void> chargerTendancesAlertes(String token, {int jours = 7}) async {
    try {
      debugPrint('[📈 Tendances] Calcul des tendances...');

      // Utiliser les alertes historique pour calculer la tendance
      if (_historiqueAlertes.isEmpty) {
        await chargerHistoriqueAlertes(token, jours: jours);
      }

      // Grouper par jour et calculer la moyenne mobile
      Map<String, int> countByDate = {};
      for (var alerte in _historiqueAlertes) {
        if (alerte['horodatage'] != null) {
          String date = alerte['horodatage'].toString().split(' ')[0];
          countByDate[date] = (countByDate[date] ?? 0) + 1;
        }
      }

      _tendancesAlertes = countByDate.entries
          .map((e) => {'date': e.key, 'alertes': e.value})
          .toList();

      debugPrint('[Tendances] ✓ Tendances calculées');
      notifyListeners();
    } catch (e) {
      debugPrint('[Tendances] ❌ Erreur: $e');
    }
  }

  /// Charge les alertes par type (criticité)
  /// Groupe les alertes existantes par leur type/criticité
  Future<void> chargerAlertesByType(String token) async {
    try {
      debugPrint('[🔴 Types] Calcul des alertes par type/criticité...');

      // Charger les alertes si pas déjà chargées
      if (_historiqueAlertes.isEmpty) {
        await chargerHistoriqueAlertes(token);
      }

      // Grouper par criticité
      Map<String, int> typeCount = {};
      for (var alerte in _historiqueAlertes) {
        String type = alerte['criticite'] ?? 'INCONNU';
        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }

      _alertesByType = typeCount;
      debugPrint('[Types] ✓ Alertes groupées par type');
      notifyListeners();
    } catch (e) {
      debugPrint('[HistoriqueProvider] Erreur alertesByType: $e');
    }
  }

  /// Charge toutes les données historiques (utile pour une mise à jour globale)
  Future<void> chargerTout(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        chargerHistoriqueAlertes(token),
        chargerStatsParJour(token),
        chargerTendancesAlertes(token),
        chargerAlertesByType(token),
      ]);
    } catch (e) {
      debugPrint('[HistoriqueProvider] Erreur charger tout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calcule les métriques globales à partir de l'historique
  void _calculerMetriques() {
    _totalAlertes30j = _historiqueAlertes.length;
    _alertesCritiques30j =
        _historiqueAlertes.where((a) => a['criticite'] == 'ELEVE').length;
  }

  Map<String, dynamic>? _parseAlerte(Map alerte) {
    try {
      return {
        ...Map<String, dynamic>.from(alerte),
        'horodatage': _parseDateTime(alerte['horodatage']) ?? DateTime.now(),
      };
    } catch (e) {
      debugPrint('[HistoriqueProvider] Erreur parse alerte: $e');
      return null;
    }
  }

  Map<String, dynamic>? _parseDemande(Map demande) {
    try {
      final map = Map<String, dynamic>.from(demande);
      return {
        ...map,
        'nom': map['nom'] ??
            map['nomRegleHistorique'] ??
            map['regleNom'] ??
            map['titre'] ??
            'Demande',
        'description': map['description'] ?? map['libelle'] ?? '',
        'criticite':
            (map['criticite'] ?? map['importance'] ?? 'MOYEN').toString(),
        'statut': (map['statut'] ?? map['status'] ?? '').toString(),
        'soumisLe': _parseDateTime(
                map['dateCreation'] ?? map['soumisLe'] ?? map['createdAt']) ??
            DateTime.now(),
        'traiteLe': _parseDateTime(
            map['dateTraitement'] ?? map['traiteLe'] ?? map['updatedAt']),
      };
    } catch (e) {
      debugPrint('[HistoriqueProvider] Erreur parse demande: $e');
      return null;
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
