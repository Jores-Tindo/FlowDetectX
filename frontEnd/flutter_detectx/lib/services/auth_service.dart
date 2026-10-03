import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(
      String identifiant, String motDePasse) async {
    try {
      debugPrint(
          '[AUTH] Tentative de connexion avec identifiant: $identifiant');
      final response = await ApiService.postPublic('/api/auth/login', {
        'identifiant': identifiant,
        'motDePasse': motDePasse,
      });

      debugPrint('[AUTH] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.body.isEmpty ? {} : jsonDecode(response.body);
        debugPrint('[AUTH] ✅ Connexion réussie');
        return {
          'success': true,
          'data': data,
        };
      }

      if (response.statusCode == 408) {
        debugPrint('[AUTH] ❌ Timeout - Serveur injoignable');
        return {
          'success': false,
          'message':
              'Timeout - Le serveur met trop de temps à répondre. Vérifiez que le serveur est en ligne.',
        };
      }

      if (response.statusCode >= 500) {
        debugPrint('[AUTH] ❌ Erreur serveur ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Erreur serveur (${response.statusCode}). Réessayez plus tard.',
        };
      }

      final data = response.body.isEmpty ? {} : jsonDecode(response.body);
      final message = data is Map<String, dynamic>
          ? (data['message'] ?? 'Identifiant ou mot de passe incorrect.')
          : 'Identifiant ou mot de passe incorrect.';

      debugPrint('[AUTH] ❌ Erreur login: $message');
      return {
        'success': false,
        'message': message,
      };
    } catch (e, stackTrace) {
      debugPrint('[AUTH] ❌ Exception lors du login: $e');
      debugPrint('[AUTH] StackTrace: $stackTrace');
      return {
        'success': false,
        'message':
            'Erreur de connexion: $e. Vérifiez votre réseau et que l\'adresse du serveur est correcte.',
      };
    }
  }

  Future<Map<String, dynamic>> motDePasseOublie(String email) async {
    final response =
        await ApiService.postPublic('/api/auth/mot-de-passe-oublie', {
      'email': email,
    });

    if (response.statusCode == 200) {
      return {'success': true};
    }

    final data = response.body.isEmpty ? {} : jsonDecode(response.body);
    return {
      'success': false,
      'message': data is Map<String, dynamic>
          ? (data['message'] ??
              'Impossible d\'envoyer le lien de réinitialisation.')
          : 'Impossible d\'envoyer le lien de réinitialisation.',
    };
  }

  Future<Map<String, dynamic>> modifierProfil(
    String token, {
    required String nom,
    required String prenom,
    required String email,
  }) async {
    try {
      final response = await ApiService.post(token, '/api/auth/profil', {
        'nom': nom,
        'prenom': prenom,
        'email': email,
      });

      if (response.statusCode == 200) {
        final data = response.body.isEmpty ? {} : jsonDecode(response.body);
        return {'success': true, 'data': data};
      }

      final data = response.body.isEmpty ? {} : jsonDecode(response.body);
      return {
        'success': false,
        'message': data is Map<String, dynamic>
            ? (data['message'] ?? 'Impossible de mettre à jour le profil.')
            : 'Impossible de mettre à jour le profil.',
      };
    } catch (e) {
      debugPrint('[AUTH] ❌ Exception modifierProfil: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  Future<Map<String, dynamic>> changerMotDePasse(
    String token, {
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
    required String confirmationMotDePasse,
  }) async {
    try {
      final response =
          await ApiService.post(token, '/api/auth/changer-mot-de-passe', {
        'ancienMotDePasse': ancienMotDePasse,
        'nouveauMotDePasse': nouveauMotDePasse,
        'confirmationMotDePasse': confirmationMotDePasse,
      });

      if (response.statusCode == 200) {
        return {'success': true};
      }

      final data = response.body.isEmpty ? {} : jsonDecode(response.body);
      return {
        'success': false,
        'message': data is Map<String, dynamic>
            ? (data['message'] ?? 'Impossible de changer le mot de passe.')
            : 'Impossible de changer le mot de passe.',
      };
    } catch (e) {
      debugPrint('[AUTH] ❌ Exception changerMotDePasse: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }
}
