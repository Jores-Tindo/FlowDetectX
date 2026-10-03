import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  // Admin stats
  int _totalTransactions = 0;
  int _transactionsSuspectes = 0;
  int _alertes = 0;
  int _totalUtilisateurs = 0;
  int _comptesSuspendus = 0;
  int _journauxAujourdhui = 0;
  double _dernierePrecision = 0;

  // Metier stats
  int _reglesActives = 0;
  int _reglesEnAttente = 0;
  int _alertesNonLues = 0;

  // Collections
  List<Map<String, dynamic>> _alertesRecentes = [];
  List<Map<String, dynamic>> _demandesRecentes = [];
  List<Map<String, dynamic>> _journauxRecents = [];
  List<Map<String, dynamic>> _transactionsByDay = [];
  List<int> _alertesByCriticite = [];
  List<Map<String, dynamic>> _transactionsByType = [];

  bool _loading = false;
  String? _erreur;

  // Getters Admin
  int get totalTransactions => _totalTransactions;
  int get transactionsSuspectes => _transactionsSuspectes;
  int get alertes => _alertes;
  int get totalUtilisateurs => _totalUtilisateurs;
  int get comptesSuspendus => _comptesSuspendus;
  int get journauxAujourdhui => _journauxAujourdhui;
  double get dernierePrecision => _dernierePrecision;

  // Getters Metier
  int get reglesActives => _reglesActives;
  int get reglesEnAttente => _reglesEnAttente;
  int get alertesNonLues => _alertesNonLues;

  // Getters Collections
  /// Liste complète (utilisée par les graphiques/agrégations).
  List<Map<String, dynamic>> get alertesToutes =>
      List.unmodifiable(_alertesRecentes);

  /// Sous-ensemble tronqué pour l'affichage dans les panneaux "récentes".
  List<Map<String, dynamic>> get alertesRecentes =>
      List.unmodifiable(_alertesRecentes.take(6));

  /// Liste complète des demandes (utilisée par l'écran d'historique)
  List<Map<String, dynamic>> get demandesToutes =>
      List.unmodifiable(_demandesRecentes);

  /// Sous-ensemble tronqué (10 éléments) pour l'affichage sur le dashboard
  List<Map<String, dynamic>> get demandesRecentes =>
      List.unmodifiable(_demandesRecentes.take(10));
  List<Map<String, dynamic>> get journauxRecents =>
      List.unmodifiable(_journauxRecents);
  List<Map<String, dynamic>> get transactionsByDay =>
      List.unmodifiable(_transactionsByDay);
  List<int> get alertesByCriticite => List.unmodifiable(_alertesByCriticite);
  List<Map<String, dynamic>> get transactionsByType =>
      List.unmodifiable(_transactionsByType);

  bool get loading => _loading;
  String? get erreur => _erreur;

  /// Charger les stats du dashboard
  /// Endpoint: GET /api/dashboard
  /// Réponse: {
  ///   totalReglesActives, totalReglesEnAttente,
  ///   totalDemandesEnAttente, totalSimulations, totalAlertes,
  ///   dernierePrecision, dernierRappel, dernierF1
  /// }
  Future<void> chargerMetierStats(String token) async {
    _loading = true;
    _erreur = null;
    notifyListeners();

    try {
      debugPrint('\n[📊 Dashboard] Chargement stats dashboard...');
      final response = await _service.getDashboard(token);
      debugPrint('[Dashboard] Réponse status: ${response.statusCode}');
      debugPrint('[Dashboard] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[Dashboard] Données décodées: $data');

        // Mapper les données du backend vers le provider
        _reglesActives = data['totalReglesActives'] ?? 0;
        _reglesEnAttente = data['totalReglesEnAttente'] ?? 0;
        _alertesNonLues = data['totalAlertes'] ?? 0;
        _alertes = data['totalAlertes'] ?? 0;
        _alertes = data['totalAlertes'] ?? 0;
        _dernierePrecision = (data['dernierePrecision'] as num?)?.toDouble() ??
            0; // <-- ajoute ici

        debugPrint('[Dashboard] ✓ Règles actives: $_reglesActives');
        debugPrint('[Dashboard] ✓ Règles en attente: $_reglesEnAttente');
        debugPrint('[Dashboard] ✓ Total alertes: $_alertes');
        notifyListeners();
      } else {
        _erreur = 'Erreur API (${response.statusCode}): ${response.body}';
        debugPrint('[Dashboard] ❌ Erreur: $_erreur');
        notifyListeners();
      }
    } catch (e) {
      _erreur = 'Erreur de connexion: $e';
      debugPrint('[Dashboard] ❌ Exception: $e');
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Alias pour compatibilité - utilise getDashboard
  Future<void> chargerAdminStats(String token) async {
    await chargerMetierStats(token);
  }

  // Helper pour parser les timestamps
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('[DashboardProvider] Erreur parse DateTime: $e');
        return null;
      }
    }
    return null;
  }

  // Charger alertes récentes
  Future<void> chargerAlertes(String token) async {
    try {
      debugPrint('\n[🚨 Alertes] Chargement des alertes récentes...');
      final response = await _service.getAlertes(token, limite: 500);
      debugPrint('[Alertes] Status: ${response.statusCode}');
      debugPrint(
          '[Alertes] Body preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');

      if (response.statusCode == 200) {
        var data = response.body.isEmpty ? [] : jsonDecode(response.body);
        debugPrint('[Alertes] Type données: ${data.runtimeType}');

        // Gérer { data: [...] } ou [...] directement
        if (data is Map && data.containsKey('data')) {
          data = data['data'] ?? [];
        }

        if (data is List) {
          _alertesRecentes = data
              .map((a) => _parseAlerte(a as Map))
              .whereType<Map<String, dynamic>>()
              .toList();
          debugPrint('[Alertes] ✓ ${_alertesRecentes.length} alertes chargées');

          // Calculer les statistiques des graphiques
          _calculerStatistiquesGraphiques();
        } else {
          _alertesRecentes = [];
          debugPrint('[Alertes] ❌ Format incorrect, pas une liste');
        }
        notifyListeners();
      } else {
        debugPrint('[Alertes] ❌ Erreur ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Alertes] ❌ Exception: $e');
    }
  }

  Map<String, dynamic>? _parseAlerte(Map alerte) {
    try {
      return {
        ...Map<String, dynamic>.from(alerte),
        'horodatage': _parseDateTime(alerte['horodatage']) ?? DateTime.now(),
      };
    } catch (e) {
      debugPrint('[DashboardProvider] Erreur parse alerte: $e');
      return null;
    }
  }

  // Charger demandes récentes
  Future<void> chargerDemandes(String token) async {
    try {
      // Charger un nombre plus important côté backend pour permettre
      // l'affichage tronqué sur le dashboard et la consultation complète
      // dans l'écran historique.
      final response = await _service.getDemandesRecentes(token, limite: 200);

      if (response.statusCode == 200) {
        var data = response.body.isEmpty ? [] : jsonDecode(response.body);

        // Gérer { data: [...] } ou [...] directement
        if (data is Map && data.containsKey('data')) {
          data = data['data'] ?? [];
        }

        if (data is List) {
          _demandesRecentes = data
              .map((d) => _parseDemande(d as Map))
              .whereType<Map<String, dynamic>>()
              .toList();
        } else {
          _demandesRecentes = [];
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[DashboardProvider] Erreur demandes: $e');
    }
  }

  Map<String, dynamic>? _parseDemande(Map demande) {
    try {
      final map = Map<String, dynamic>.from(demande);
      // Normalize fields used by UI
      final nom = map['nom'] ??
          map['titre'] ??
          map['name'] ??
          map['nomRegleHistorique'] ??
          map['regleNom'] ??
          'Demande de validation';

      final typeField = map['type'] ??
          map['typeDemande'] ??
          map['demandeType'] ??
          map['action'] ??
          '';
      final type = typeField.toString().toUpperCase();

      final statutField =
          map['statut'] ?? map['status'] ?? map['etat'] ?? map['state'] ?? '';
      final statut = statutField.toString().toUpperCase();

      final submitted = _parseDateTime(map['soumisLe'] ??
          map['dateCreation'] ??
          map['date'] ??
          map['createdAt'] ??
          map['submittedAt']);

      // Normaliser le champ "motif" provenant du validateur ou d'autres APIs
      final motifField = map['motif'] ??
          map['motifDemande'] ??
          map['motifRejet'] ??
          map['raison'] ??
          map['commentaire'] ??
          map['motifs'] ??
          '';
      final motif = motifField == null ? '' : motifField.toString();

      // Compatibilité: exposer explicitement les clés utilisées côté validateur
      final motifDemande = (map['motifDemande'] ?? motif).toString();
      final motifRejet = (map['motifRejet'] ?? '').toString();

      return {
        ...map,
        'nom': nom,
        'type': type,
        'statut': statut,
        'soumisLe': submitted ?? DateTime.now(),
        'motif': motif,
        'motifDemande': motifDemande,
        'motifRejet': motifRejet,
      };
    } catch (e) {
      debugPrint('[DashboardProvider] Erreur parse demande: $e');
      return null;
    }
  }

  // Charger journaux récents
  Future<void> chargerJournaux(String token) async {
    try {
      final response = await _service.getJournauxRecents(token, limite: 5);

      if (response.statusCode == 200) {
        var data = response.body.isEmpty ? [] : jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) {
          data = data['data'] ?? [];
        }
        if (data is List) {
          _journauxRecents = data
              .map((j) => _parseJournal(j as Map))
              .whereType<Map<String, dynamic>>()
              .toList();

          final now = DateTime.now();
          _journauxAujourdhui = _journauxRecents.where((j) {
            final h = j['horodatage'] as DateTime?;
            return h != null &&
                h.year == now.year &&
                h.month == now.month &&
                h.day == now.day;
          }).length;
        } else {
          _journauxRecents = [];
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[DashboardProvider] Erreur journaux: $e');
    }
  }

  Map<String, dynamic>? _parseJournal(Map journal) {
    try {
      return {
        ...Map<String, dynamic>.from(journal),
        'horodatage': _parseDateTime(journal['horodatage']) ?? DateTime.now(),
      };
    } catch (e) {
      debugPrint('[DashboardProvider] Erreur parse journal: $e');
      return null;
    }
  }

  // Charger tous les dashboards en parallèle
  Future<void> chargerTout(String token, {required String role}) async {
    _loading = true;
    notifyListeners();

    try {
      if (role == 'ADMIN') {
        await Future.wait([
          chargerAdminStats(token),
          chargerAlertes(token),
          chargerJournaux(token),
          chargerUtilisateurs(token)
        ]);
        // Calculer les graphiques après le chargement
        _calculerStatistiquesGraphiques();
      } else {
        await Future.wait([
          chargerMetierStats(token),
          chargerDemandes(token),
          chargerJournaux(token),
        ]);
      }
    } catch (e) {
      debugPrint('[DashboardProvider] Erreur chargement global: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> chargerUtilisateurs(String token) async {
    try {
      final response = await _service.getUtilisateurs(token);
      if (response.statusCode == 200) {
        var data = response.body.isEmpty ? [] : jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) {
          data = data['data'] ?? [];
        }
        if (data is List) {
          _totalUtilisateurs = data.length;
          _comptesSuspendus =
              data.where((u) => u['statut'] == 'SUSPENDU').length;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[DashboardProvider] Erreur utilisateurs: $e');
    }
  }

  // ─── Calcul des statistiques pour les graphiques ───────────────────────

  /// Calcule les alertes par criticité à partir des alertes chargées
  /// Retourne: [HAUTE, MOYENNE, BASSE]
  List<int> calculerAlertesByCriticite() {
    Map<String, int> count = {'ELEVE': 0, 'MOYEN': 0, 'FAIBLE': 0};

    for (var alerte in _alertesRecentes) {
      final criticite =
          alerte['criticite']?.toString().toUpperCase() ?? 'FAIBLE';
      count[criticite] = (count[criticite] ?? 0) + 1;
    }

    return [
      count['ELEVE'] ?? 0,
      count['MOYEN'] ?? 0,
      count['FAIBLE'] ?? 0,
    ];
  }

  /// Calcule les transactions par type à partir des alertes
  /// Retourne: List<Map<String, dynamic>> avec label, valeur, couleur
  List<Map<String, dynamic>> calculerTransactionsByType(
      {List<String>? couleurs}) {
    Map<String, int> count = {};

    for (var alerte in _alertesRecentes) {
      // Les alertes ont une transaction avec un type
      final type = alerte['transaction']?['type']?.toString().toUpperCase() ??
          alerte['type']?.toString().toUpperCase() ??
          'UNKNOWN';
      count[type] = (count[type] ?? 0) + 1;
    }

    // Mapper vers les couleurs (TRANSFER, CASH_OUT, PAYMENT, CASH_IN)
    final defaultColors = [
      AppColors.blueImf,
      AppColors.danger,
      AppColors.success,
      AppColors.warning,
    ];

    List<Map<String, dynamic>> result = [];
    int colorIndex = 0;

    count.forEach((type, valeur) {
      result.add({
        'label': type,
        'valeur': valeur.toDouble(),
        'couleur': couleurs != null && colorIndex < couleurs.length
            ? Color(int.parse(couleurs[colorIndex].replaceFirst('#', '0xff')))
            : defaultColors[colorIndex % defaultColors.length],
      });
      colorIndex++;
    });

    return result;
  }

  /// Calcule les transactions par jour (7 derniers jours)
  /// Retourne: List<FlSpot> avec jour et count
  List<Map<String, dynamic>> calculerTransactionsByDay() {
    Map<String, int> txByDay = {};

    final now = DateTime.now();

    // Initialiser les 7 derniers jours
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateKey = '${day.year}-${day.month}-${day.day}';
      txByDay[dateKey] = 0;
    }

    // Compter les alertes par jour
    for (var alerte in _alertesRecentes) {
      try {
        final horodatage = alerte['horodatage'] as DateTime?;
        if (horodatage != null) {
          final dateKey =
              '${horodatage.year}-${horodatage.month}-${horodatage.day}';
          txByDay[dateKey] = (txByDay[dateKey] ?? 0) + 1;
        }
      } catch (e) {
        debugPrint('[Dashboard] Erreur parse horodatage: $e');
      }
    }

    // Convertir en liste indexée
    List<Map<String, dynamic>> result = [];
    final valuesList = txByDay.values.toList();
    valuesList.asMap().entries.forEach((entry) {
      result.add({
        'index': entry.key.toDouble(),
        'valeur': entry.value.toDouble(),
      });
    });

    return result;
  }

  /// Calcule les KPIs à partir des données chargées
  Map<String, int> calculerKPIsAdmin() {
    return {
      'transactionsSuspectes': _alertesRecentes
          .where((a) =>
              a['criticite']?.toString().toUpperCase() == 'ELEVE' ||
              a['criticite']?.toString().toUpperCase() == 'MOYEN')
          .length,
      'alertes': _alertes,
    };
  }

  /// Calcule les statistiques complètes des graphiques
  void _calculerStatistiquesGraphiques() {
    debugPrint('[Dashboard] Calcul des statistiques des graphiques...');

    _alertesByCriticite = calculerAlertesByCriticite();
    _transactionsByType = calculerTransactionsByType();
    final txByDay = calculerTransactionsByDay();
    _transactionsByDay = txByDay;

    debugPrint('[Dashboard] Alertes par criticité: $_alertesByCriticite');
    debugPrint('[Dashboard] Transactions par type: $_transactionsByType');
    debugPrint('[Dashboard] Transactions par jour: $_transactionsByDay');

    notifyListeners();
  }
}
