# Guide de Débogage de l'Authentification

## Problèmes Identifiés et Fixes Appliqués

### ✅ Problèmes Corrigés

1. **`postPublic` sans timeout** ❌ → ✅ Ajout de timeout de 30s
2. **`postPublic` sans gestion d'erreur** ❌ → ✅ Ajout try-catch
3. **Logs insuffisants** ❌ → ✅ Logs détaillés avec debugPrint
4. **Messages d'erreur génériques** ❌ → ✅ Messages d'erreur spécifiques

---

## Vérification de la Connexion API

### Option 1: Vérifier dans les Logs

1. Ouvrez les **Logs Flutter** dans le terminal:
   ```bash
   flutter run
   ```
   ou dans VS Code: `Ctrl+Shift+J` pour ouvrir le Debug Console

2. Cherchez les logs `[API POST PUBLIC]` et `[AUTH]`:
   - Logs bleus = informations
   - Logs rouges = erreurs

3. Vérifiez:
   - `[API POST PUBLIC] $url` → URL est correcte?
   - `[API POST PUBLIC] Status: XXX` → Quel code HTTP?
   - `[API POST PUBLIC] Response: ...` → Quel contenu?

### Option 2: Tester l'API Directement

Si vous utilisez **Android Emulator**:

```bash
# Depuis l'émulateur, le serveur local est à 10.0.2.2
curl http://10.0.2.2:8080/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"identifiant":"test","motDePasse":"test123"}'
```

Si vous utilisez **Web**:

```bash
curl http://localhost:8080/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"identifiant":"test","motDePasse":"test123"}'
```

### Option 3: Vérifier avec Postman

Assurez-vous que dans Postman vous testez exactement la même URL:

```
POST http://10.0.2.2:8080/api/auth/login  (pour Android Emulator)
POST http://localhost:8080/api/auth/login  (pour Web)
```

Headers:
```
Content-Type: application/json
```

Body (raw JSON):
```json
{
  "identifiant": "votre_identifiant",
  "motDePasse": "votre_mot_de_passe"
}
```

---

## Configuration de l'URL API

### Fichier: `lib/config/api_config.dart`

L'URL actuelle est configurée pour **Android Emulator**:

```dart
const String API_BASE_URL = 'http://10.0.2.2:8080';
```

#### Changer selon votre plateforme:

**Android Emulator** (Pixel, Nexus, etc.):
```dart
return 'http://10.0.2.2:8080';
```

**iPhone Simulator**:
```dart
return 'http://localhost:8080';
```

**Web (Flutter Web)**:
```dart
return 'http://localhost:8080';
```

**Vrai Téléphone (même réseau)**:
```dart
return 'http://192.168.X.X:8080';  // Remplacez par l'IP de votre PC
```

---

## Messages d'Erreur Courants

### ❌ "Timeout - Serveur injoignable"
- Le serveur n'a pas répondu en 30 secondes
- **Solutions:**
  1. Vérifiez que le serveur est en ligne: `ping 10.0.2.2` (pour émulateur) ou `ping localhost`
  2. Vérifiez que le port 8080 est correct
  3. Vérifiez les pare-feu (Windows Firewall, etc.)

### ❌ "Erreur de connexion: SocketException"
- Le serveur n'est pas accessible
- **Solutions:**
  1. Vérifiez l'URL dans `api_config.dart`
  2. Assurez-vous que le serveur écoute sur le bon port
  3. Test avec `curl` pour isoler le problème

### ❌ "Identifiant ou mot de passe incorrect"
- Les identifiants sont mauvais OU
- Le serveur a rejeté la requête (HTTP 401/403)
- **Solutions:**
  1. Vérifiez les identifiants
  2. Vérifiez les logs du serveur pour voir pourquoi c'est rejeté

### ❌ "Erreur serveur (500)"
- Erreur dans le code du serveur
- **Solutions:**
  1. Vérifiez les logs du serveur (console/fichiers logs)
  2. Vérifiez que les endpoints existent

---

## Étapes de Dépannage Complètes

1. ✅ **Vérifiez le serveur**:
   ```bash
   curl -v http://10.0.2.2:8080/api/auth/login \
     -X POST \
     -H "Content-Type: application/json" \
     -d '{"identifiant":"test","motDePasse":"test"}'
   ```

2. ✅ **Testez dans Postman**:
   - Utilisez exactement la même URL que curl
   - Vérifiez que vous obtenez une réponse

3. ✅ **Testez dans Flutter**:
   - Ouvrez les logs: `flutter run`
   - Essayez de vous connecter
   - Regardez les logs `[API POST PUBLIC]` et `[AUTH]`

4. ✅ **Vérifiez la réponse du serveur**:
   - La réponse doit être du JSON valide
   - Elle doit contenir au minimum: `{"token": "...", "id": 1, "nom": "...", ...}`

5. ✅ **Vérifiez les en-têtes HTTP**:
   - Content-Type doit être `application/json`

---

## Fichiers Modifiés

Ajouté logs améliorés et gestion d'erreur dans:

- `lib/services/api_service.dart` - `postPublic()` ajouté timeout + logs + try-catch
- `lib/services/auth_service.dart` - Logs détaillés + messages d'erreur spécifiques
- `lib/providers/auth_provider.dart` - Logs + messages d'erreur améliorés

---

## Procédure de Test Finale

1. Assurez-vous que le serveur est **en ligne et en écoute**
2. Compilez l'app Flutter
3. Ouvrez les **Logs** (Flutter Console)
4. Essayez de vous **connecter**
5. Vérifiez les **logs détaillés** pour voir exactement où ça échoue
6. Comparez avec **Postman** pour isoler le problème

Si vous voyez toujours une erreur, **partagez les logs** de Flutter (les lignes commençant par `[API` ou `[AUTH]`).
