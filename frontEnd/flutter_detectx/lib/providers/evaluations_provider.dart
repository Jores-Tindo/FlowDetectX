import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

/// Gère les métriques de performance du moteur Drools.
/// Branché sur : GET /api/dashboard
class EvaluationsProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();
  double _precision = 0;
  double _rappel = 0;
  double _f1Score = 0;
  double _tauxFauxPositifs = 0;
  int _vraisPositifs = 0;
  int _fauxPositifs = 0;
  int _fauxNegatifs = 0;
  int _vraisNegatifs = 0;
  int _totalTransactions = 0;
  int _transactionsSuspectes = 0;
  int _alertes = 0;
  int _totalUtilisateurs = 0;
  int _comptesSuspendus = 0;
  int _journauxAujourdhui = 0;
  bool _isLoading = false;
  String? _erreur;
  DateTime? _derniereMAJ;

  double get precision => _precision;
  double get rappel => _rappel;
  double get f1Score => _f1Score;
  double get tauxFauxPositifs => _tauxFauxPositifs;
  int get vraisPositifs => _vraisPositifs;
  int get fauxPositifs => _fauxPositifs;
  int get fauxNegatifs => _fauxNegatifs;
  int get vraisNegatifs => _vraisNegatifs;
  int get totalTransactions => _totalTransactions;
  int get transactionsSuspectes => _transactionsSuspectes;
  int get alertesGeneres => _alertes;
  int get totalUtilisateurs => _totalUtilisateurs;
  int get comptesSuspendus => _comptesSuspendus;
  int get journauxAujourdhui => _journauxAujourdhui;
  bool get isLoading => _isLoading;
  String? get erreur => _erreur;
  DateTime? get derniereMAJ => _derniereMAJ;

  Future<void> charger(String token) async {
    _isLoading = true;
    _erreur = null;
    notifyListeners();

    try {
      final response = await _service.charger(token);

      if (response.statusCode == 200) {
        final body = response.body;
        final data = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
        _precision = _readDouble(
            data, ['precision', 'dernierePrecision', 'scorePrecision']);
        _rappel = _readDouble(data, ['rappel', 'dernierRappel', 'scoreRappel']);
        _f1Score = _readDouble(data, ['f1Score', 'scoreF1', 'f1']);
        _tauxFauxPositifs =
            _readDouble(data, ['tauxFauxPositifs', 'falsePositiveRate']);
        _vraisPositifs = _readInt(data, ['vraisPositifs', 'truePositives']);
        _fauxPositifs = _readInt(data, ['fauxPositifs', 'falsePositives']);
        _fauxNegatifs = _readInt(data, ['fauxNegatifs', 'falseNegatives']);
        _vraisNegatifs = _readInt(data, ['vraisNegatifs', 'trueNegatives']);
        _totalTransactions = _readInt(data,
            ['totalTransactions', 'transactionsTotal', 'totalTransaction']);
        _transactionsSuspectes =
            _readInt(data, ['transactionsSuspectes', 'suspectTransactions']);
        _alertes =
            _readInt(data, ['alertes', 'alertesGeneres', 'totalAlertes']);
        _totalUtilisateurs =
            _readInt(data, ['totalUtilisateurs', 'usersTotal']);
        _comptesSuspendus =
            _readInt(data, ['comptesSuspendus', 'suspendedAccounts']);
        _journauxAujourdhui =
            _readInt(data, ['journauxAujourdhui', 'todayLogs']);
        _derniereMAJ = DateTime.now();
      } else {
        _erreur =
            'Erreur de chargement des évaluations (${response.statusCode}).';
      }
    } catch (e) {
      _erreur = 'Impossible de charger les évaluations.';
      debugPrint('[EvaluationsProvider] Erreur: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void mettreAJour({
    required double precision,
    required double rappel,
    required double f1Score,
    required double tauxFauxPositifs,
    int totalTransactions = 0,
    int transactionsSuspectes = 0,
    int alertes = 0,
    int totalUtilisateurs = 0,
    int comptesSuspendus = 0,
    int journauxAujourdhui = 0,
  }) {
    _precision = precision;
    _rappel = rappel;
    _f1Score = f1Score;
    _tauxFauxPositifs = tauxFauxPositifs;
    _vraisPositifs = 0;
    _fauxPositifs = 0;
    _fauxNegatifs = 0;
    _vraisNegatifs = 0;
    _totalTransactions = totalTransactions;
    _transactionsSuspectes = transactionsSuspectes;
    _alertes = alertes;
    _totalUtilisateurs = totalUtilisateurs;
    _comptesSuspendus = comptesSuspendus;
    _journauxAujourdhui = journauxAujourdhui;
    _derniereMAJ = DateTime.now();
    notifyListeners();
  }

  double _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  int _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
