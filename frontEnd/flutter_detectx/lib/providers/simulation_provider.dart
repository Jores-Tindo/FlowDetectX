import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/simulation_service.dart';

class SimulationProvider extends ChangeNotifier {
  final SimulationService _service = SimulationService();
  bool _simulationActive = false;
  int _nbNouvellesAlertes = 0;
  int? _simulationId;
  Map<String, dynamic>? _simulationCourante;
  final List<Map<String, dynamic>> _alertes = [];
  http.Client? _sseClient;
  StreamSubscription? _sseSub;
  String? _erreur;

  String? get erreur => _erreur;
  bool get simulationActive => _simulationActive;
  int get nbNouvellesAlertes => _nbNouvellesAlertes;
  int? get simulationId => _simulationId;
  Map<String, dynamic>? get simulationCourante => _simulationCourante;
  List<Map<String, dynamic>> get alertes => List.unmodifiable(_alertes);

  Future<bool> demarrerSimulation(String token) async {
    _erreur = null;
    try {
      final response = await _service.demarrerSimulation(token);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = response.body.isNotEmpty
            ? (jsonDecode(response.body) as Map<String, dynamic>)
            : <String, dynamic>{};
        _simulationId = data['id'] is int ? data['id'] as int : null;
        _simulationCourante = data;
        _simulationActive = true;
        _alertes.clear();
        _nbNouvellesAlertes = 0;
        notifyListeners();

        if (_simulationId != null) {
          _connecterSSE(token, _simulationId!);
        }
        return true;
      }

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      _erreur = data['message'] ?? 'Impossible de démarrer la simulation.';
      notifyListeners();
    } catch (e) {
      _erreur = 'Erreur de connexion au serveur.';
      debugPrint('[SimulationProvider] Erreur démarrage: $e');
      notifyListeners();
    }
    return false;
  }

  void _connecterSSE(String token, int simulationId) {
    _sseClient = http.Client();
    final uri =
        Uri.parse('${ApiService.baseUrl}/api/simulation/stream/$simulationId');

    final request = http.Request('GET', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'text/event-stream';

    _sseClient!.send(request).then((response) {
      _sseSub = response.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('data:')) {
            final raw = line.substring(5).trim();
            if (raw == 'Simulation terminee') {
              _simulationActive = false;
              notifyListeners();
              return;
            }
            try {
              final alerte = jsonDecode(raw);
              _alertes.insert(0, Map<String, dynamic>.from(alerte));
              _nbNouvellesAlertes++;
              notifyListeners();
            } catch (_) {}
          }
        },
        onDone: () {
          _simulationActive = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('[SSE] Erreur: $e');
          _simulationActive = false;
          notifyListeners();
        },
      );
    });
  }

  Future<void> arreterSimulation(String token) async {
    if (_simulationId == null) return;
    try {
      final ok = await _service.arreterSimulation(token, _simulationId!);
      if (!ok) {
        _erreur = 'Impossible d\'arrêter la simulation depuis l\'API.';
        notifyListeners();
        return;
      }
    } catch (e) {
      _erreur = 'Erreur lors de l\'arrêt de la simulation.';
      debugPrint('[SimulationProvider] Erreur arrêt: $e');
      notifyListeners();
      return;
    }
    _sseSub?.cancel();
    _sseClient?.close();
    _simulationActive = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> listerSimulations(String token) async {
    try {
      final response = await _service.listerSimulations(token);
      if (response.statusCode == 200) {
        final List data =
            response.body.isEmpty ? [] : jsonDecode(response.body);
        return data.map((s) => Map<String, dynamic>.from(s)).toList();
      }
    } catch (e) {
      debugPrint('[SimulationProvider] Erreur liste: $e');
    }
    return [];
  }

  void marquerAlertesLues() {
    _nbNouvellesAlertes = 0;
    notifyListeners();
  }

  void viderAlertes() {
    _alertes.clear();
    _nbNouvellesAlertes = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    _sseClient?.close();
    super.dispose();
  }
}
