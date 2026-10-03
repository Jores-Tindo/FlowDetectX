import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/utilisateurs_service.dart';

/// Gère la liste des comptes utilisateurs pour l'Admin.
/// Branché sur : GET /api/utilisateurs
///               PUT /api/utilisateurs/{id}/suspendre
///               PUT /api/utilisateurs/{id}/reactiver
class UtilisateursProvider extends ChangeNotifier {
  final UtilisateursService _service = UtilisateursService();
  List<Map<String, dynamic>> _utilisateurs = [];
  bool _isLoading = false;
  String? _erreur;

  List<Map<String, dynamic>> get utilisateurs =>
      List.unmodifiable(_utilisateurs);
  bool get isLoading => _isLoading;
  String? get erreur => _erreur;

  int maxUtilisateursMetier = 5;
  int maxValidateurs = 5;

  int get totalActifs =>
      _utilisateurs.where((u) => u['statut'] == 'ACTIF').length;
  int get totalSuspendus =>
      _utilisateurs.where((u) => u['statut'] == 'SUSPENDU').length;
  int get totalEnAttente =>
      _utilisateurs.where((u) => u['statut'] == 'EN_ATTENTE').length;

  int get actifsUtilisateursMetier => _utilisateurs
      .where((u) => u['role'] == 'UTILISATEUR_METIER' && u['statut'] == 'ACTIF')
      .length;

  int get enAttenteUtilisateursMetier => _utilisateurs
      .where((u) =>
          u['role'] == 'UTILISATEUR_METIER' && u['statut'] == 'EN_ATTENTE')
      .length;

  int get actifsValidateurs => _utilisateurs
      .where((u) => u['role'] == 'VALIDATEUR' && u['statut'] == 'ACTIF')
      .length;

  int get enAttenteValidateurs => _utilisateurs
      .where((u) => u['role'] == 'VALIDATEUR' && u['statut'] == 'EN_ATTENTE')
      .length;

  bool canCreateCompte(String role) {
    if (role == 'VALIDATEUR') {
      return actifsValidateurs + enAttenteValidateurs < maxValidateurs;
    }
    if (role == 'UTILISATEUR_METIER') {
      return actifsUtilisateursMetier + enAttenteUtilisateursMetier <
          maxUtilisateursMetier;
    }
    return true;
  }

  String quotaErreurPourRole(String role) {
    if (role == 'VALIDATEUR') {
      return 'Quota validateurs atteint $actifsValidateurs/$maxValidateurs. '
          'Réduisez le nombre de comptes actifs ou augmentez le quota si possible.';
    }
    if (role == 'UTILISATEUR_METIER') {
      return 'Quota utilisateurs métier atteint $actifsUtilisateursMetier/$maxUtilisateursMetier. '
          'Réduisez le nombre de comptes actifs ou augmentez le quota si possible.';
    }
    return 'Impossible de créer ce type de compte pour le moment.';
  }

  void setMaxUtilisateursMetier(int value) {
    maxUtilisateursMetier = value.clamp(0, 5);
    notifyListeners();
  }

  void setMaxValidateurs(int value) {
    maxValidateurs = value.clamp(0, 5);
    notifyListeners();
  }

  Future<void> charger(String token) async {
    _isLoading = true;
    _erreur = null;
    notifyListeners();

    try {
      final response = await _service.charger(token);
      if (response.statusCode == 200) {
        final List data =
            response.body.isEmpty ? [] : jsonDecode(response.body);
        _utilisateurs = data.map((u) => _mapperUtilisateur(u)).toList();
      } else {
        _erreur = 'Erreur de chargement des utilisateurs.';
      }
    } catch (e) {
      _erreur = 'Impossible de charger les utilisateurs.';
      debugPrint('[UtilisateursProvider] Erreur: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> creerCompte({
    required String token,
    required String nom,
    required String prenom,
    required String email,
    required String role,
  }) async {
    if (!canCreateCompte(role)) {
      return false;
    }

    try {
      final response = await _service.creerCompte(
        token: token,
        nom: nom,
        prenom: prenom,
        email: email,
        role: role,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.body.isEmpty ? {} : jsonDecode(response.body);
        _utilisateurs.add(_mapperUtilisateur(data));
        notifyListeners();
        return true;
      }

      debugPrint(
          '[UtilisateursProvider] Erreur creerCompte: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('[UtilisateursProvider] Exception creerCompte: $e');
    }

    return false;
  }

  Future<bool> suspendre(String token, int id) async {
    try {
      final response = await _service.suspendre(token, id);
      if (response.statusCode == 200) {
        final idx = _utilisateurs.indexWhere((u) => u['id'] == id);
        if (idx != -1) {
          _utilisateurs[idx]['statut'] = 'SUSPENDU';
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('[UtilisateursProvider] Erreur suspension: $e');
    }
    return false;
  }

  Future<bool> reactiver(String token, int id) async {
    try {
      final response = await _service.reactiver(token, id);
      if (response.statusCode == 200) {
        final idx = _utilisateurs.indexWhere((u) => u['id'] == id);
        if (idx != -1) {
          _utilisateurs[idx]['statut'] = 'ACTIF';
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('[UtilisateursProvider] Erreur réactivation: $e');
    }
    return false;
  }

  Future<bool> supprimer(String token, int id) async {
    try {
      final response = await _service.supprimer(token, id);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _utilisateurs.removeWhere((u) => u['id'] == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[UtilisateursProvider] Erreur suppression: $e');
    }
    return false;
  }

  List<Map<String, dynamic>> filtrer({
    String statut = 'TOUS',
    String recherche = '',
  }) {
    return _utilisateurs.where((u) {
      final matchStatut = statut == 'TOUS' || u['statut'] == statut;
      final q = recherche.toLowerCase();
      final matchRecherche = q.isEmpty ||
          u['nom'].toString().toLowerCase().contains(q) ||
          u['prenom'].toString().toLowerCase().contains(q) ||
          u['email'].toString().toLowerCase().contains(q) ||
          u['identifiant'].toString().toLowerCase().contains(q);
      return matchStatut && matchRecherche;
    }).toList();
  }

  Map<String, dynamic> _mapperUtilisateur(dynamic user) {
    final map = Map<String, dynamic>.from(user as Map<dynamic, dynamic>);
    final dateValue = map['dateCreation'];
    final parsedDate = dateValue is String
        ? DateTime.tryParse(dateValue)
        : dateValue is DateTime
            ? dateValue
            : null;

    return {
      ...map,
      'id': map['id'],
      'nom': map['nom'] ?? '',
      'prenom': map['prenom'] ?? '',
      'email': map['email'] ?? '',
      'identifiant': map['identifiant'] ?? '',
      'role': (map['role'] ?? '').toString().toUpperCase(),
      'statut': (map['statut'] ?? '').toString().toUpperCase(),
      'dateCreation': parsedDate ?? DateTime.now(),
    };
  }
}
