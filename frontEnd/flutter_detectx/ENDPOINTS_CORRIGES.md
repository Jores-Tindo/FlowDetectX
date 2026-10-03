# ✅ Endpoints Corrigés

## Vue d'ensemble
Le code Flutter utilisait des endpoints qui n'existaient pas dans le backend.
Tous les services ont été mis à jour pour utiliser uniquement les endpoints disponibles.

## Endpoints Disponibles (Backend Réel)

### 🔐 Authentification (`/api/auth`)
```
POST   /api/auth/login
POST   /api/auth/activation
POST   /api/auth/mot-de-passe-oublie
POST   /api/auth/reinitialisation
POST   /api/auth/creer-compte
POST   /api/auth/renvoyer-invitation/{id}
```

### 📊 Dashboard (`/api/dashboard`)
```
GET    /api/dashboard
       Réponse: {
         totalReglesActives,
         totalReglesEnAttente,
         totalDemandesEnAttente,
         totalSimulations,
         totalAlertes,
         dernierePrecision,
         dernierRappel,
         dernierF1
       }
```

### 🚨 Alertes (`/api/alertes`)
```
GET    /api/alertes                    (toutes les alertes)
GET    /api/alertes?criticite=CRITIQUE (filtrer par criticité)
GET    /api/alertes/{id}               (une alerte spécifique)
```

### ⚙️ Règles (`/api/regles`)
```
GET    /api/regles
GET    /api/regles/{id}
GET    /api/regles/{id}/versions
POST   /api/regles/creer
POST   /api/regles/{id}/modifier
POST   /api/regles/{id}/supprimer
POST   /api/regles/{id}/activer
POST   /api/regles/{id}/desactiver
```

### 📋 Journal (`/api/journal`)
```
GET    /api/journal
GET    /api/journal/utilisateur/{id}
```

### 👤 Utilisateurs (`/api/utilisateurs`)
```
GET    /api/utilisateurs
GET    /api/utilisateurs?role=ADMIN    (filtrer par rôle)
GET    /api/utilisateurs/{id}
PUT    /api/utilisateurs/{id}/suspendre
PUT    /api/utilisateurs/{id}/reactiver
```

### 📝 Demandes (`/api/demandes`)
```
GET    /api/demandes
GET    /api/demandes/en-attente
GET    /api/demandes/mes-demandes
POST   /api/demandes/{id}/approuver
POST   /api/demandes/{id}/rejeter
```

### 🎬 Simulation (`/api/simulation`)
```
POST   /api/simulation/demarrer
GET    /api/simulation/stream/{id}     (Server-Sent Events)
POST   /api/simulation/{id}/arreter
GET    /api/simulation/mes-simulations
GET    /api/simulation/{id}
GET    /api/simulation/{id}/alertes
```

## ❌ Endpoints qui N'EXISTENT PAS

Supprimés du code:
```
❌ /api/dashboard/stats              → Utiliser /api/dashboard
❌ /api/dashboard/metier/stats       → Utiliser /api/dashboard
❌ /api/journaux                     → Utiliser /api/journal (note: pas de 'x')
❌ /api/alertes/historique           → Utiliser /api/alertes
❌ /api/dashboard/statistiques-complet
❌ /api/alertes/export
❌ /api/analytics/*                  (tout ce répertoire n'existe pas)
```

## 📝 Changements Effectués

### 1. `lib/services/dashboard_service.dart`
- ✅ Changé `getAdminStats()` → utilise `/api/dashboard`
- ✅ Changé `getMetierStats()` → utilise `/api/dashboard`
- ✅ Supprimé les endpoints `/api/analytics/*`
- ✅ Ajouté helper pour `/api/journal` (note: pas `/api/journaux`)
- ✅ Ajouté `getRegles()`, `getUtilisateurs()`, `getMesSimulations()`

### 2. `lib/services/historique_service.dart`
- ✅ Changé `getHistoriqueAlertes()` → utilise `/api/alertes`
- ✅ Supprimé `getStatistiquesParJour()` (pas d'endpoint)
- ✅ Supprimé `getTendancesAlertes()` (pas d'endpoint)
- ✅ Supprimé `getAlertesByType()` (pas d'endpoint)
- ✅ Supprimé `exportAlertes()` (pas d'endpoint)
- ✅ Ajouté filtrage par criticité

### 3. `lib/providers/dashboard_provider.dart`
- ✅ Changé `chargerMetierStats()` → appelle `/api/dashboard`
- ✅ Changé `chargerAdminStats()` → alias pour `chargerMetierStats()`
- ✅ Mise à jour du mapping des réponses

### 4. `lib/providers/historique_provider.dart`
- ✅ Changé `chargerHistoriqueAlertes()` → appelle `/api/alertes`
- ✅ Changé `chargerStatsParJour()` → calcule côté frontend à partir des alertes
- ✅ Changé `chargerTendancesAlertes()` → calcule côté frontend
- ✅ Changé `chargerAlertesByType()` → groupe par criticité des alertes existantes

## 🔧 Calculs Frontend

Puisque le backend n'a pas d'endpoints analytics:

### Stats par jour
Groupée à partir de `/api/alertes`:
```dart
Map<String, int> statsByDate = {};
for (var alerte in alertes) {
  String date = alerte['horodatage'].split(' ')[0];
  statsByDate[date] = (statsByDate[date] ?? 0) + 1;
}
```

### Tendances
Calcul de la progression des alertes par jour

### Alertes par Type
Groupées par champ `criticite` depuis `/api/alertes`

## 📲 Résultats Attendus

Après ces changements, l'app devrait:
1. ✅ Se connecter sans erreur d'endpoint
2. ✅ Charger le dashboard avec `/api/dashboard`
3. ✅ Afficher les vraies données de la base de données
4. ✅ Pas de timeout 408 (endpoints existent maintenant)
5. ✅ Les logs montrer "Status: 200" au lieu de "TIMEOUT"

## 🧪 Test

Relancez l'app et vérifiez les logs:
```
[📊 Dashboard] Chargement stats dashboard...
[Dashboard] Réponse status: 200
[Dashboard] ✓ Règles actives: XX
```

Si vous voyez:
```
[API GET] Status: 200 - /api/dashboard
```

→ **C'est bon! La connexion marche!** ✅
