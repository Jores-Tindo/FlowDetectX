# 🚨 Correction du timeout API

## Le problème
Le dashboard affiche **Timeout (408)** → le serveur backend n'est pas accessible

## Les erreurs visibles:
```
Dashboard: Error API (408): Timeout
Évaluations: Erreur de chargement des évaluations.
```

## Solutions

### ✅ Étape 1: Vérifier que le backend démarre

```bash
# Vérifier si le backend tourne
netstat -tuln | grep 8080

# Ou avec lsof
lsof -i :8080

# Ou tester directement
curl http://localhost:8080/health
```

Si rien ne répond → **le backend n'est pas lancé !**

### ✅ Étape 2: Trouver la bonne URL

L'application essaie: `http://10.0.2.2:8080` (pour l'émulation Android)

**Mais votre backend tourne peut-être sur:**
- `http://localhost:8080` (machine locale)
- `http://127.0.0.1:8080` (localhost)
- Une autre machine/port
- Un serveur distant

**Pour changer l'URL, modifiez:**

**Fichier:** `lib/config/api_config.dart`

```dart
class ApiConfig {
  // Changez cette ligne:
  static const Environment currentEnv = Environment.emulation;
  
  // À:
  static const Environment currentEnv = Environment.development;
  
  // OU spécifiez l'URL directement:
  static String getBaseUrl() {
    return 'http://VOTRE_URL:8080';
  }
}
```

### ✅ Étape 3: Tester la connexion

```bash
# Rendre le script exécutable
chmod +x test_api.sh

# Tester localhost
./test_api.sh localhost 8080

# Tester 10.0.2.2 (émulation)
./test_api.sh 10.0.2.2 8080

# Tester une autre machine
./test_api.sh 192.168.1.100 8080
```

Le script vous indiquera si:
- ✓ Le serveur répond
- ✗ Le serveur est injoignable

### ✅ Étape 4: Tester les endpoints

Une fois que le serveur répond:

```bash
# Avec token (remplacez TOKEN par votre JWT)
TOKEN="votre-jwt-token" ./test_api.sh
```

### ✅ Étape 5: Relancer l'app Flutter

Après avoir corrigé l'URL:
1. Arrêtez l'app (`Ctrl+C`)
2. Relancez-la
3. Cliquez sur "Actualiser" dans le dashboard

## 📊 Résultat attendu

Une fois la connexion établie:
- ✓ Règles actives: **12** (au lieu de 0)
- ✓ Demandes en attente: **2**
- ✓ Alertes non lues: **5**
- ✓ Les alertes récentes s'affichent
- ✓ Les performances du moteur sont visibles

## 🔍 Pour déboguer

Regardez les logs dans le terminal:

```
[API GET] http://10.0.2.2:8080/api/dashboard/metier/stats
[Dashboard] Réponse status: 200    ← OK
[Dashboard] ✓ Règles actives: 12
```

ou

```
[API GET] http://10.0.2.2:8080/api/dashboard/metier/stats
[API GET] ⏱️ TIMEOUT (30s): http://10.0.2.2:8080/api/dashboard/metier/stats
[Dashboard] Réponse status: 408    ← TIMEOUT
[Dashboard] Error API (408): Timeout
```

## ❓ Quelle URL utiliser?

| Situation | URL | Émulation |
|-----------|-----|-----------|
| Backend sur ma machine | http://localhost:8080 | http://10.0.2.2:8080 |
| Backend sur autre PC (LAN) | http://192.168.1.100:8080 | http://192.168.1.100:8080 |
| Backend distant (cloud) | https://api.votredomaine.com | https://api.votredomaine.com |

## ⚠️ Port incorrect?

Si le backend tourne sur un autre port (ex: 3000):

```dart
// Modifiez la config:
return 'http://10.0.2.2:3000';  // au lieu de 8080
```

## 📞 Besoin d'aide?

1. Vérifiez que le backend **démarre sans erreur**
2. Testez la connexion avec `./test_api.sh`
3. Consultez les **logs du terminal** (pas l'interface)
4. Changez l'URL si nécessaire
5. Relancez l'app
