import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

enum RoleUtilisateur { admin, validateur, utilisateurMetier }

class AuthProvider extends ChangeNotifier {
  static const String _kToken = 'auth_token';
  static const String _kUserId = 'auth_user_id';
  static const String _kFirstName = 'auth_first_name';
  static const String _kLastName = 'auth_last_name';
  static const String _kEmail = 'auth_email';
  static const String _kIdentifiant = 'auth_identifiant';
  static const String _kRole = 'auth_role';

  final AuthService _service = AuthService();
  String? _token;
  int? _id;
  String? _nom;
  String? _prenom;
  String? _email;
  String? _identifiant;
  RoleUtilisateur? _role;
  bool _isLoading = false;
  String? _erreur;

  String? get token => _token;
  int? get id => _id;
  String? get nom => _nom;
  String? get prenom => _prenom;
  String? get email => _email;
  String? get identifiant => _identifiant;
  RoleUtilisateur? get role => _role;
  bool get isLoading => _isLoading;
  String? get erreur => _erreur;
  bool get isAuthentifie => _token != null && _token!.isNotEmpty;

  String get nomComplet => '${_prenom ?? ''} ${_nom ?? ''}'.trim();

  String get initiales {
    final p = _prenom?.isNotEmpty == true ? _prenom![0].toUpperCase() : '';
    final n = _nom?.isNotEmpty == true ? _nom![0].toUpperCase() : '';
    return '$p$n';
  }

  String get roleLabel {
    switch (_role) {
      case RoleUtilisateur.admin:
        return 'Administrateur';
      case RoleUtilisateur.validateur:
        return 'Validateur';
      case RoleUtilisateur.utilisateurMetier:
        return 'Utilisateur Métier';
      default:
        return '';
    }
  }

  String get routeInitiale {
    switch (_role) {
      case RoleUtilisateur.admin:
        return '/admin/dashboard';
      case RoleUtilisateur.validateur:
        return '/validateur/dashboard';
      case RoleUtilisateur.utilisateurMetier:
        return '/metier/dashboard';
      default:
        return '/login';
    }
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _id = prefs.getInt(_kUserId);
    _nom = prefs.getString(_kLastName);
    _prenom = prefs.getString(_kFirstName);
    _email = prefs.getString(_kEmail);
    _identifiant = prefs.getString(_kIdentifiant);
    _role = _parseRole(prefs.getString(_kRole));
    notifyListeners();
  }

  Future<bool> login(String identifiant, String motDePasse) async {
    _isLoading = true;
    _erreur = null;
    notifyListeners();

    try {
      final result = await _service.login(identifiant, motDePasse);
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        _token = data['token']?.toString();
        _id = data['id'] is int
            ? data['id'] as int
            : int.tryParse(data['id'].toString());
        _nom = data['nom']?.toString();
        _prenom = data['prenom']?.toString();
        _email = data['email']?.toString();
        _identifiant = data['identifiant']?.toString();
        _role = _parseRole(data['role']?.toString());

        await _persistSession();

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _erreur = result['message'] as String? ??
          'Identifiant ou mot de passe incorrect.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      print('[AUTH PROVIDER] ❌ Exception login: $e');
      print('[AUTH PROVIDER] StackTrace: $stackTrace');
      _erreur =
          'Erreur de connexion: $e\n\nVérifiez que:\n1. Le serveur est en ligne\n2. Votre URL API est correcte\n3. Votre connexion réseau est stable';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> mettreAJourProfil({
    required String nom,
    required String prenom,
    required String email,
    String? ancienMotDePasse,
    String? nouveauMotDePasse,
  }) async {
    if (_token == null) return false;

    _isLoading = true;
    _erreur = null;
    notifyListeners();

    try {
      final resultProfil = await _service.modifierProfil(
        _token!,
        nom: nom,
        prenom: prenom,
        email: email,
      );

      if (resultProfil['success'] != true) {
        _erreur = resultProfil['message'] as String? ??
            'Impossible de mettre à jour le profil.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (nouveauMotDePasse != null &&
          nouveauMotDePasse.isNotEmpty &&
          ancienMotDePasse != null) {
        final resultMdp = await _service.changerMotDePasse(
          _token!,
          ancienMotDePasse: ancienMotDePasse,
          nouveauMotDePasse: nouveauMotDePasse,
          confirmationMotDePasse: nouveauMotDePasse,
        );

        if (resultMdp['success'] != true) {
          _erreur = resultMdp['message'] as String? ??
              'Impossible de changer le mot de passe.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _nom = nom;
      _prenom = prenom;
      _email = email;
      await _persistSession();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _erreur = 'Impossible de mettre à jour le profil.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deconnecter() async {
    _token = null;
    _id = null;
    _nom = null;
    _prenom = null;
    _email = null;
    _identifiant = null;
    _role = null;
    _erreur = null;
    await _clearSession();
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, _token ?? '');
    await prefs.setInt(_kUserId, _id ?? 0);
    await prefs.setString(_kFirstName, _prenom ?? '');
    await prefs.setString(_kLastName, _nom ?? '');
    await prefs.setString(_kEmail, _email ?? '');
    await prefs.setString(_kIdentifiant, _identifiant ?? '');
    await prefs.setString(_kRole, _roleToValue(_role));
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kFirstName);
    await prefs.remove(_kLastName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kIdentifiant);
    await prefs.remove(_kRole);
  }

  RoleUtilisateur? _parseRole(String? value) {
    switch (value?.toUpperCase()) {
      case 'ADMINISTRATEUR':
        return RoleUtilisateur.admin;
      case 'VALIDATEUR':
        return RoleUtilisateur.validateur;
      case 'UTILISATEUR_METIER':
        return RoleUtilisateur.utilisateurMetier;
      default:
        return null;
    }
  }

  String _roleToValue(RoleUtilisateur? role) {
    switch (role) {
      case RoleUtilisateur.admin:
        return 'ADMINISTRATEUR';
      case RoleUtilisateur.validateur:
        return 'VALIDATEUR';
      case RoleUtilisateur.utilisateurMetier:
        return 'UTILISATEUR_METIER';
      default:
        return '';
    }
  }
}
