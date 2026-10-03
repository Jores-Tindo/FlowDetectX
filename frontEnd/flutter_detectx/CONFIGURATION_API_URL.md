# Configuration de l'URL API - Guide Complet

## 🎯 Le Problème Probable

Vous testez sur **Postman** et ça marche, mais sur Flutter ça ne marche pas.

### Cause Probable: **Mauvaise URL pour la plateforme**

- ✅ Postman sur votre PC = `http://localhost:8080`
- ❌ Flutter sur Emulator Android ≠ `http://localhost:8080` (ça vise l'émulateur, pas votre PC!)
- ✅ Flutter sur Emulator Android = `http://10.0.2.2:8080` (alias magique pour accéder au PC)

---

## 📋 Détection: Sur Quelle Plateforme Testez-vous?

### ✅ Android Emulator (Pixel, Nexus, etc.)
```
Signes:
- Lancé depuis Android Studio
- Ou: flutter run (sur Windows/Mac avec Android Emulator)
- Écran ressemble à un téléphone Android
```

**Fichier à modifier**: `lib/config/api_config.dart`

```dart
const String API_BASE_URL = 'http://10.0.2.2:8080';
//                                ^^^^^^^^^ 
//                 Ceci est l'alias magique pour localhost du PC
```

---

### ✅ iPhone Simulator
```
Signes:
- Lancé depuis Xcode
- Ou: flutter run (sur Mac avec Xcode)
- Écran ressemble à un iPhone
```

**Fichier à modifier**: `lib/config/api_config.dart`

```dart
const String API_BASE_URL = 'http://localhost:8080';
//                           ^^^^^^^^^^
//            Peut utiliser localhost directement
```

---

### ✅ Flutter Web
```
Signes:
- flutter run -d chrome
- flutter run -d firefox
- flutter run -d edge
- URL dans navigateur: http://localhost:port
```

**Fichier à modifier**: `lib/config/api_config.dart`

```dart
const String API_BASE_URL = 'http://localhost:8080';
//                           ^^^^^^^^^^
//            Utilise le même PC que le navigateur
```

---

### ✅ Vrai Téléphone Android (USB)
```
Signes:
- Téléphone physique branché en USB
- flutter devices montre votre téléphone
- Vous pouvez tenir le téléphone dans la main!
```

**Fichier à modifier**: `lib/config/api_config.dart`

```dart
const String API_BASE_URL = 'http://192.168.X.X:8080';
//                                     ^^^^^^^^^^^
//         Remplacez X.X par l'IP de votre PC sur le réseau
```

**Comment trouver votre IP PC?**

Windows (Command Prompt):
```cmd
ipconfig
```
Cherchez "IPv4 Address" = `192.168.X.X`

Mac/Linux (Terminal):
```bash
ifconfig
```
Cherchez "inet" sous votre connexion WiFi = `192.168.X.X`

---

## 🔧 Étapes de Configuration Correcte

### 1. Identifiez votre plateforme
```bash
flutter devices
```

Affichera quelque chose comme:
```
1 connected device

SM-G973F                      • 354D8FFAXXX • android-arm64   • Android 10
Chrome                         •             • web-javascript • Google Chrome
Windows                        •             • windows        • Microsoft Windows
```

### 2. Modifiez `lib/config/api_config.dart`

**Avant** (ne fonctionne que pour Android Emulator):
```dart
const String API_BASE_URL = 'http://10.0.2.2:8080';
```

**Après** (adapté à votre plateforme):

Pour Android Emulator uniquement:
```dart
const String API_BASE_URL = 'http://10.0.2.2:8080';
```

Pour Web uniquement:
```dart
const String API_BASE_URL = 'http://localhost:8080';
```

Pour vrai téléphone Android:
```dart
const String API_BASE_URL = 'http://192.168.1.100:8080';  // Remplacez 100 par votre IP
```

**Meilleure solution: Auto-détection par plateforme**

```dart
import 'dart:io' show Platform;

class ApiConfig {
  static String getBaseUrl() {
    if (Platform.isAndroid) {
      // Émulateur Android → localhost du PC
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS) {
      // Simulateur iPhone → localhost du Mac
      return 'http://localhost:8080';
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Web ou Desktop → localhost
      return 'http://localhost:8080';
    }
    return 'http://localhost:8080';
  }

  static String get baseUrl => getBaseUrl();
}
```

### 3. Testez
```bash
flutter run
```

### 4. Observez les logs
```
[API POST PUBLIC] http://10.0.2.2:8080/api/auth/login
[API POST PUBLIC] Status: 200
```

Si vous voyez `Status: 200` → ✅ **Ça marche!**

---

## 🚨 Problèmes Courants et Solutions

### ❌ "Connection refused" ou "Serveur injoignable"

**Android Emulator:**
```
❌ http://localhost:8080       (Cherche sur l'émulateur, pas votre PC!)
✅ http://10.0.2.2:8080        (Cherche sur votre PC)
```

**Vrai téléphone Android:**
```
❌ http://localhost:8080       (Cherche sur le téléphone!)
❌ http://10.0.2.2:8080        (Ne marche que sur l'émulateur)
✅ http://192.168.X.X:8080     (Cherche sur votre PC sur le réseau)
```

### ❌ "Connection timed out"

Le serveur n'écoute pas sur la bonne interface:

**Vérifiez que le serveur écoute sur:**
```
0.0.0.0:8080  (toutes les interfaces)
```

**Pas sur:**
```
127.0.0.1:8080  (localhost uniquement)
```

---

## ✅ Vérification Rapide

Avant de modifier le code, testez avec cURL:

**Si vous testez sur Android Emulator:**
```bash
curl -v http://10.0.2.2:8080/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"identifiant":"test","motDePasse":"test"}'
```

**Si vous testez sur Web/Windows/Mac:**
```bash
curl -v http://localhost:8080/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"identifiant":"test","motDePasse":"test"}'
```

**Si vous testez sur vrai téléphone:**
```bash
# D'abord trouvez votre IP
ipconfig  (Windows)
# ou
ifconfig  (Mac/Linux)

# Puis testez
curl -v http://192.168.X.X:8080/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"identifiant":"test","motDePasse":"test"}'
```

---

## 📝 Résumé Rapide

| Plateforme | URL | Comment Savoir |
|-----------|-----|-----------------|
| Android Emulator | `http://10.0.2.2:8080` | Flutter sur PC, Écran Android |
| iPhone Simulator | `http://localhost:8080` | Flutter sur Mac/Xcode, Écran iPhone |
| Web (Chrome) | `http://localhost:8080` | `flutter run -d chrome` |
| Vrai Téléphone Android | `http://192.168.X.X:8080` | Téléphone dans la main! |
| Desktop (Windows) | `http://localhost:8080` | `flutter run -d windows` |

---

## 🎯 Prochaine Étape

1. Identifiez votre plateforme
2. Modifiez `lib/config/api_config.dart` avec la bonne URL
3. Relancez `flutter run`
4. Vérifiez les logs
5. Testez la connexion

Si ça marche toujours pas, partez les logs Flutter!
