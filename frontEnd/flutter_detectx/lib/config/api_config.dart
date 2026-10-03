// Configuration de l'API
// Changez cette URL selon votre environnement

import 'dart:io' show Platform;

/// URL de base de l'API backend
///
/// Environnements:
/// - Émulation Android: http://10.0.2.2:8080 (accède à localhost de la machine hôte)
/// - Web: http://localhost:8080
/// - Linux/Windows/Mac Desktop: http://localhost:8080
/// - Production: https://api.votredomaine.com
const String API_BASE_URL = 'http://10.0.2.2:8080';

/// Port du serveur backend
const int API_PORT = 8080;

/// Délai d'expiration des requêtes (secondes)
const int API_TIMEOUT = 30;

/// Activer les logs détaillés des API
const bool API_DEBUG = true;

/// Options d'environnement
enum Environment {
  development, // Localhost (machine hôte) - Web, Desktop, iPhone Simulator
  emulation, // Émulateur Android uniquement
  production, // Production
}

/// Configuration par environnement
class ApiConfig {
  // Auto-détecte la plateforme pour choisir l'env
  static Environment _detectEnvironment() {
    if (Platform.isAndroid) {
      // Sur vrai téléphone Android, utiliser localhost:8080
      // (pas 10.0.2.2 qui fonctionne que sur l'émulateur)
      return Environment.development;
    } else if (Platform.isLinux ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isIOS) {
      // Linux Desktop, Windows, Mac, iPhone = utiliser localhost
      return Environment.development;
    }
    // Par défaut: development
    return Environment.development;
  }

  static String getBaseUrl() {
    final env = _detectEnvironment();
    switch (env) {
      case Environment.emulation:
        // Émulateur Android UNIQUEMENT
        return 'http://10.0.2.2:8080';
      case Environment.development:
        // Linux, Windows, Mac, Web, iPhone Simulator, vrai Android
        return 'http://localhost:8080';
      case Environment.production:
        return 'https://api.votredomaine.com';
    }
  }

  static String get baseUrl => getBaseUrl();

  /// Permet de forcer une URL spécifique si nécessaire
  static String getBaseUrlForPlatform(String? customUrl) {
    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }
    return getBaseUrl();
  }
}
