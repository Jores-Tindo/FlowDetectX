import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/regles_service.dart';

class ReglesProvider extends ChangeNotifier {
  final ReglesService _service = ReglesService();
  List<Map<String, dynamic>> _regles = [];
  List<Map<String, dynamic>> _demandes = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get regles => List.unmodifiable(_regles);
  List<Map<String, dynamic>> get demandes => List.unmodifiable(_demandes);
  bool get isLoading => _isLoading;

  int get nbDemandesEnAttente =>
      _demandes.where((d) => d['statut'] == 'EN_ATTENTE').length;

  Future<void> chargerRegles(String token) async {
    if (token.isEmpty) {
      _regles = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.chargerRegles(token);
      if (response.statusCode == 200) {
        var decoded = response.body.isEmpty ? [] : jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          decoded = decoded['data'] ?? [];
        }
        if (decoded is List) {
          _regles = decoded.map((item) => _mapRegle(item)).toList();
        } else {
          _regles = [];
          debugPrint(
              '[ReglesProvider] Format inattendu: ${decoded.runtimeType}');
        }
      }
    } catch (e) {
      debugPrint('[ReglesProvider] Erreur chargement règles: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> chargerDemandes(String token) async {
    if (token.isEmpty) {
      _demandes = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.chargerDemandes(token);
      if (response.statusCode == 200) {
        var decoded = response.body.isEmpty ? [] : jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          decoded = decoded['data'] ?? [];
        }
        if (decoded is List) {
          _demandes = decoded.map((item) => _mapDemande(item)).toList();
        } else {
          _demandes = [];
          debugPrint(
              '[ReglesProvider] Format inattendu demandes: ${decoded.runtimeType}');
        }
      }
    } catch (e) {
      debugPrint('[ReglesProvider] Erreur chargement demandes: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Soumet une demande, puis rafraîchit les règles et demandes depuis le
  /// backend (source de vérité pour le statut : ACTIVE / EN_ATTENTE / ...).
  Future<bool> soumettreDemande({
    required String token,
    required String type,
    required Map<String, dynamic> data,
    int? regleId,
  }) async {
    if (token.isEmpty) return false;

    String path;
    Map<String, dynamic> body;

    switch (type.toUpperCase()) {
      case 'CREATION':
        path = '/api/regles/creer';
        body = {
          'nom': data['nom'] ?? '',
          'description': data['description'] ?? '',
          'criticite': data['criticite'] ?? 'MOYEN',
          'conditions': data['conditions'] ?? '',
          'contenuDrl': data['contenuDrl'] ?? '',
        };
        break;
      case 'MODIFICATION':
        path = '/api/regles/$regleId/modifier';
        body = {
          'description': data['description'] ?? '',
          'conditions': data['conditions'] ?? '',
          'contenuDrl': data['contenuDrl'] ?? '',
        };
        break;
      case 'SUPPRESSION':
        path = '/api/regles/$regleId/supprimer';
        body = {};
        break;
      case 'ACTIVATION':
        path = '/api/regles/$regleId/activer';
        body = {};
        break;
      case 'DESACTIVATION':
        path = '/api/regles/$regleId/desactiver';
        body = {};
        break;
      default:
        return false;
    }

    try {
      final response = await _service.soumettreDemande(token, path, body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Le backend est la source de verite pour le statut (ACTIVE,
        // EN_ATTENTE, ...) : on recharge plutot que de deviner l'etat
        // localement.
        await chargerRegles(token);
        await chargerDemandes(token);
        return true;
      }
    } catch (e) {
      debugPrint('[ReglesProvider] Erreur soumission demande: $e');
    }

    return false;
  }

  Future<bool> approuverDemande(String token, int demandeId) async {
    if (token.isEmpty) return false;

    try {
      final response = await _service.approuverDemande(token, demandeId);
      if (response.statusCode == 200) {
        await chargerRegles(token);
        await chargerDemandes(token);
        return true;
      }
    } catch (e) {
      debugPrint('[ReglesProvider] Erreur approbation: $e');
    }

    return false;
  }

  Future<bool> rejeterDemande(String token, int demandeId, String motif) async {
    if (token.isEmpty) return false;

    try {
      final response = await _service.rejeterDemande(token, demandeId, motif);
      if (response.statusCode == 200) {
        await chargerRegles(token);
        await chargerDemandes(token);
        return true;
      }
    } catch (e) {
      debugPrint('[ReglesProvider] Erreur rejet: $e');
    }

    return false;
  }

  /// Mappe une RegleResponse backend. Champs :
  /// id, nom, description, criticite (ELEVE/MOYEN/FAIBLE), statut
  /// (ACTIVE/EN_ATTENTE/REJETEE/INACTIVE), estReglementaire, creePar,
  /// dateCreation (ISO string), versionActive (objet ou null).
  Map<String, dynamic> _mapRegle(dynamic item) {
    final map = Map<String, dynamic>.from(item);
    final versionActive = map['versionActive'] != null
        ? Map<String, dynamic>.from(map['versionActive'])
        : null;

    return {
      'id': map['id'],
      'nom': map['nom'] ?? '',
      'description': map['description'] ?? '',
      'criticite': (map['criticite'] ?? 'MOYEN').toString(),
      'statut': (map['statut'] ?? 'INACTIVE').toString(),
      'active': (map['statut'] ?? '').toString() == 'ACTIVE',
      'demandeEnCours': (map['statut'] ?? '').toString() == 'EN_ATTENTE',
      'estReglementaire': map['estReglementaire'] == true,
      'dateCreation':
          DateTime.tryParse(map['dateCreation']?.toString() ?? '') ??
              DateTime.now(),
      'contenuDrl': versionActive?['contenuDrl'],
      'conditions': versionActive?['conditions'],
      'numeroVersion': versionActive?['numeroVersion'],
    };
  }

  /// Mappe une DemandeResponse backend (desormais enrichie avec
  /// criticite/conditions/contenuDrl/numeroVersion issus de la regle et
  /// de la version associees).
  Map<String, dynamic> _mapDemande(dynamic item) {
    final map = Map<String, dynamic>.from(item);
    return {
      'id': map['id'] ?? 0,
      'type': (map['type'] ?? '').toString(),
      'statut': (map['statut'] ?? '').toString(),
      'nom': map['nomRegleHistorique'] ?? 'Demande de validation',
      'regleId': map['regleId'],
      'motifRejet': map['motifRejet'],
      'motifDemande': map['motifDemande'],
      'criticite': (map['criticite'] ?? 'MOYEN').toString(),
      'conditions': map['conditions'] ?? '',
      'contenuDrl': map['contenuDrl'] ?? '',
      'numeroVersion': map['numeroVersion'] ?? 1,
      'soumisLe': DateTime.tryParse(map['dateCreation']?.toString() ?? '') ??
          DateTime.now(),
      'traiteLe': map['dateTraitement'] != null
          ? DateTime.tryParse(map['dateTraitement'].toString())
          : null,
    };
  }
}
