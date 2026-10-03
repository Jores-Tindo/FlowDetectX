import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/journaux_service.dart';

/// Gère les journaux d'activité système pour l'Admin.
/// Branché sur : GET /api/journal?page=0&size=100
class JournauxProvider extends ChangeNotifier {
  final JournauxService _service = JournauxService();
  List<Map<String, dynamic>> _journaux = [];
  bool _isLoading = false;
  String? _erreur;

  List<Map<String, dynamic>> get journaux => List.unmodifiable(_journaux);
  bool get isLoading => _isLoading;
  String? get erreur => _erreur;

  int get totalAujourdhui {
    final today = DateTime.now();
    return _journaux.where((j) {
      final h = j['horodatage'] as DateTime?;
      return h != null &&
          h.year == today.year &&
          h.month == today.month &&
          h.day == today.day;
    }).length;
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
        _journaux = data.map((j) => _mapperJournal(j)).toList();
      } else {
        _erreur = 'Erreur de chargement des journaux.';
      }
    } catch (e) {
      _erreur = 'Impossible de charger les journaux.';
      debugPrint('[JournauxProvider] Erreur: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void enregistrer({
    required String action,
    required String details,
    required String utilisateur,
    required String type,
  }) {
    _journaux.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'action': action,
      'details': details,
      'utilisateur': utilisateur,
      'horodatage': DateTime.now(),
      'type': type,
    });
    notifyListeners();
  }

  List<Map<String, dynamic>> filtrer({
    String action = 'TOUS',
    String recherche = '',
    DateTimeRange? periode,
  }) {
    return _journaux.where((j) {
      final matchAction = action == 'TOUS' || j['action'] == action;
      final q = recherche.toLowerCase();
      final matchRecherche = q.isEmpty ||
          j['details'].toString().toLowerCase().contains(q) ||
          j['utilisateur'].toString().toLowerCase().contains(q) ||
          j['action'].toString().toLowerCase().contains(q);
      final h = j['horodatage'] as DateTime?;
      final matchPeriode = periode == null ||
          (h != null &&
              h.isAfter(periode.start) &&
              h.isBefore(periode.end.add(const Duration(days: 1))));
      return matchAction && matchRecherche && matchPeriode;
    }).toList();
  }

  Map<String, dynamic> _mapperJournal(dynamic journal) {
    final map = Map<String, dynamic>.from(journal as Map<dynamic, dynamic>);
    final dateValue = map['horodatage'];
    final parsedDate = dateValue is String
        ? DateTime.tryParse(dateValue)
        : dateValue is DateTime
            ? dateValue
            : null;

    return {
      ...map,
      'id': map['id'] ?? 0,
      'action': map['action'] ?? 'INCONNU',
      'details': map['details'] ?? '',
      // CORRIGÉ : le back renvoie desormais 'utilisateurRole'
      // (JournalActiviteResponse), pas 'utilisateur'. L'ancienne cle
      // n'a jamais existe dans la reponse JSON, d'ou le fallback
      // 'Systeme' qui s'appliquait tout le temps.
      'utilisateur': map['utilisateurRole'] ?? 'Système',
      'horodatage': parsedDate ?? DateTime.now(),
      'type': map['type'] ?? 'info',
    };
  }
}
