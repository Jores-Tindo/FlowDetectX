import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/alertes_service.dart';

class AlertesProvider extends ChangeNotifier {
  final AlertesService _service = AlertesService();
  final List<Map<String, dynamic>> _alertes = [];
  int _nbNonLues = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get alertes => List.unmodifiable(_alertes);
  int get nbNonLues => _nbNonLues;
  bool get isLoading => _isLoading;

  Future<void> charger(String token, {int? simulationId}) async {
    if (token.isEmpty) {
      _alertes.clear();
      _nbNonLues = 0;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await _service.charger(token, simulationId: simulationId);

      if (response.statusCode == 200) {
        var decoded = response.body.isEmpty ? [] : jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          decoded = decoded['data'] ?? [];
        }
        if (decoded is List) {
          _alertes.clear();
          _alertes
              .addAll(decoded.map((a) => Map<String, dynamic>.from(a as Map)));
          _nbNonLues = _alertes.length;
        } else {
          _alertes.clear();
          _nbNonLues = 0;
          debugPrint(
              '[AlertesProvider] Format inattendu: ${decoded.runtimeType}');
        }
      } else {
        _alertes.clear();
        _nbNonLues = 0;
      }
    } catch (e) {
      debugPrint('[AlertesProvider] Erreur: $e');
      _alertes.clear();
      _nbNonLues = 0;
    }

    _isLoading = false;
    notifyListeners();
  }

  void vider() {
    _alertes.clear();
    _nbNonLues = 0;
    notifyListeners();
  }

  void ajouterAlerte(Map<String, dynamic> alerte) {
    _alertes.insert(0, {...alerte, 'lu': false});
    _nbNonLues++;
    notifyListeners();
  }

  void marquerToutesLues() {
    for (final a in _alertes) {
      a['lu'] = true;
    }
    _nbNonLues = 0;
    notifyListeners();
  }

  List<Map<String, dynamic>> filtrer({
    String criticite = 'TOUS',
    String recherche = '',
  }) {
    return _alertes.where((a) {
      final matchCriticite = criticite == 'TOUS' || a['criticite'] == criticite;
      final matchRecherche = recherche.isEmpty ||
          a['regleNom']
              .toString()
              .toLowerCase()
              .contains(recherche.toLowerCase());
      return matchCriticite && matchRecherche;
    }).toList();
  }
}
