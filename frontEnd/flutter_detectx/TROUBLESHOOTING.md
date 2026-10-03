# 🔧 Guide de dépannage - Dashboard pas à jour

## ❌ Problème: Dashboard affiche 0 partout

Les données ne se chargent pas de la base de données. Voici comment déboguer:

## 📋 Étape 1: Vérifier la connexion API

### ✅ La widget de debug affichera maintenant les erreurs

- Ouvrez le dashboard Métier
- Si vous voyez un encadré rouge/orange avec des erreurs → développez-le pour voir les détails
- Vérifiez les points suivants:

## 🔍 Checklist de dépannage

### 1. **URL de base de l'API**
```
Configuration: lib/config/api_config.dart
Actuellement: http://10.0.2.2:8080
```

**En émulation Android:**
- ✓ Utilisez `10.0.2.2:8080` (accès au localhost de la machine hôte)
- ✗ NE PAS utiliser `localhost:8080`

**En development local:**
- Modifiez `ApiConfig.currentEnv` de `emulation` à `development`
- Utilisez `http://localhost:8080`

### 2. **Vérifier que le backend démarre**

Depuis le terminal:
```bash
# Vérifier le port 8080
netstat -tuln | grep 8080

# Ou pinger l'API
curl http://localhost:8080/health
curl http://localhost:8080/api/dashboard/metier/stats
```

### 3. **Vérifier les endpoints API**

Les endpoints attendus sont:

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/api/dashboard/metier/stats` | GET | KPIs (règles, demandes, alertes) |
| `/api/dashboard` | GET | Performances du moteur ML |
| `/api/alertes?limit=4` | GET | Alertes récentes (4) |
| `/api/demandes?limit=3` | GET | Demandes récentes (3) |
| `/api/alertes/historique?jours=30` | GET | Historique alertes 30j |
| `/api/analytics/statistiques/par-jour` | GET | Stats par jour |
| `/api/analytics/alertes/tendances` | GET | Tendances |
| `/api/analytics/alertes/par-type` | GET | Distribution types |

**Comment vérifier:**

```bash
TOKEN="votre-jwt-token-ici"

# Test 1: KPIs
curl -H "Authorization: Bearer $TOKEN" \
     http://10.0.2.2:8080/api/dashboard/metier/stats | jq .

# Test 2: Alertes
curl -H "Authorization: Bearer $TOKEN" \
     "http://10.0.2.2:8080/api/alertes?limit=4" | jq .

# Test 3: Performances
curl -H "Authorization: Bearer $TOKEN" \
     http://10.0.2.2:8080/api/dashboard | jq .
```

### 4. **Structure JSON attendue**

**Réponse `/api/dashboard/metier/stats`:**
```json
{
  "reglesActives": 12,
  "reglesEnAttente": 2,
  "alertesNonLues": 5
}
```

**Réponse `/api/alertes?limit=4`:**
```json
[
  {
    "id": 1,
    "regleNom": "Montant anormal",
    "type": "MONTANT",
    "montant": 50000,
    "criticite": "ELEVEE",
    "horodatage": "2026-01-06T14:30:00Z"
  }
]
```

**Ou encapsulé:**
```json
{
  "data": [...]
}
```

### 5. **Vérifier les logs Dart**

Dans VS Code ou logcat:
```
[API GET] http://10.0.2.2:8080/api/dashboard/metier/stats
[Dashboard] Réponse status: 404  ← Erreur endpoint non trouvé
[Dashboard] Body: {"error": "Not found"}
```

Les logs utiles sont marqués par:
- `[API GET]` - requête lancée
- `[API POST]` - POST lancée
- `[Dashboard]` - réponse reçue
- `[Alertes]` - alertes chargées
- `⚠️` ou `✗` - erreurs

### 6. **CORS et authentification**

Assurez-vous que le backend accepte:
- Les requêtes avec header `Authorization: Bearer <token>`
- Les requêtes POST avec `Content-Type: application/json`

## 🚨 Erreurs courantes

### Erreur 404 "Endpoint not found"
```
[API GET] http://10.0.2.2:8080/api/dashboard/metier/stats
[Dashboard] Réponse status: 404
```
**Solution:** L'endpoint `/api/dashboard/metier/stats` n'existe pas sur votre backend
- Vérifiez le nom exact de l'endpoint
- Vérifiez que le backend implémente cette route

### Erreur 401 "Unauthorized"
```
[Dashboard] Réponse status: 401
```
**Solution:** Token d'authentification invalide
- Assurez-vous d'être connecté
- Vérifiez que le token est valide

### Timeout "Timeout after 10 seconds"
```
[API GET] TIMEOUT: http://10.0.2.2:8080/api/dashboard/metier/stats
```
**Solution:** Le serveur est trop lent ou injoignable
- Vérifiez que le backend démarre
- Vérifiez la connexion réseau
- Vérifiez l'URL (10.0.2.2 au lieu de localhost)

### Erreur "Connection refused"
```
[API GET] Exception: Connection refused
```
**Solution:** Le serveur backend n'écoute pas sur le port
- Vérifiez que le backend a démarré
- Vérifiez le port (par défaut 8080)

## ✅ Vérification finale

1. ✓ Backend démarre sans erreur
2. ✓ Port 8080 est accessible
3. ✓ Endpoints API implémentés
4. ✓ Authentification fonctionne
5. ✓ Format JSON correct
6. ✓ URL: http://10.0.2.2:8080 (émulation) ou http://localhost:8080 (dev)

## 📱 Tester depuis l'app Flutter

1. Ouvrir le dashboard Métier
2. Attendre ~2 secondes
3. Vérifier la widget de debug (en haut du dashboard)
4. Cliquer pour développer et voir les erreurs détaillées
5. Utiliser ces info pour corriger le backend

## 🔄 Recharger les données

Bouton "Actualiser" en haut à droite du dashboard pour recharger
