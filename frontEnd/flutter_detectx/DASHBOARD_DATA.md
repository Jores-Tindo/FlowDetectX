# Dashboard - Intégration des vraies données

## 📊 Données affichées

Le dashboard affiche maintenant les vraies données de la base de données en temps réel :

### 1️⃣ **KPIs Métier** (Haut du dashboard)
```
├─ Règles actives → Nombre de règles Drools en production
├─ Demandes en attente → Demandes de création/modification/suppression en attente du validateur  
├─ Alertes non lues → Alertes reçues depuis la dernière session
└─ Statut simulation → État de la simulation PaySim
```

**API utilisée:** `/api/dashboard/metier/stats`

### 2️⃣ **Performances du moteur Drools**
```
Métriques ML calculées:
├─ Précision (VP / (VP + FP)) → % d'alertes levées justes
├─ Rappel (VP / (VP + FN)) → % de fraudes détectées
├─ F1-Score → Équilibre P/R (0-1)
├─ Taux Faux Positifs → FP / (FP + VN) → Faux alertes

Compteurs bruts:
├─ Vrais Positifs → Fraudes correctement détectées
├─ Faux Positifs → Transactions normales mal alertées
├─ Faux Négatifs → Fraudes manquées
└─ Vrais Négatifs → Transactions normales bien ignorées
```

**API utilisée:** `/api/dashboard` (EvaluationsProvider)

### 3️⃣ **Statistiques 30 derniers jours**
```
├─ Total alertes → Toutes les alertes générées
├─ Alertes critiques → Seulement les CRITIQUE
├─ Alertes résolues → Celles traitées (RESOLUE) ou rejetées (REJETEE)
└─ Taux résolution → % alertes traitées / total
```

**API utilisée:** `/api/alertes/historique?jours=30`

### 4️⃣ **Alertes récentes**
```
Affiche les 4 dernières alertes avec:
├─ Nom de la règle
├─ Type d'alerte
├─ Montant
├─ Criticité (CRITIQUE/ELEVEE/NORMALE)
└─ Temps écoulé
```

**API utilisée:** `/api/alertes?limit=4&sort=-horodatage`

### 5️⃣ **Demandes récentes**
```
Affiche les 3 dernières demandes avec:
├─ Type (CREATION, MODIFICATION, SUPPRESSION)
├─ Nom de la règle
├─ Statut (EN_ATTENTE, APPROUVEE, REJETEE)
└─ Date de soumission
```

**API utilisée:** `/api/demandes?limit=3&sort=-soumisLe`

### 6️⃣ **Historique alertes**
```
Affiche les 5 dernières alertes (30 jours) avec :
├─ Détails complets de l'alerte
├─ Lien vers chaque alerte
└─ Possibilité d'ouvrir la liste complète
```

**API utilisée:** `/api/alertes/historique?jours=30`

## 🔄 Flux de chargement des données

```
initState()
    ↓
_chargerDonnees()
    ├─ DashboardProvider.chargerMetierStats()  ← KPIs
    ├─ DashboardProvider.chargerAlertes()      ← Alertes récentes (4)
    ├─ DashboardProvider.chargerDemandes()     ← Demandes récentes (3)
    ├─ HistoriqueProvider.chargerHistoriqueAlertes(30j)    ← Stats 30j
    ├─ HistoriqueProvider.chargerStatsParJour()           ← Tendances
    ├─ HistoriqueProvider.chargerTendancesAlertes()       ← Évolution
    └─ HistoriqueProvider.chargerAlertesByType()          ← Distribution
    
EvaluationsProvider.charger()  ← Performances du moteur (chargé dans PerformancesMoteurWidget)
```

## 📡 Points d'API requis

| Endpoint | Méthode | Auth | Description |
|----------|---------|------|-------------|
| `/api/dashboard/metier/stats` | GET | ✓ | KPIs métier |
| `/api/dashboard` | GET | ✓ | Performances ML |
| `/api/alertes?limit=4` | GET | ✓ | Alertes récentes |
| `/api/demandes?limit=3` | GET | ✓ | Demandes récentes |
| `/api/alertes/historique?jours=30` | GET | ✓ | Historique 30j |
| `/api/analytics/statistiques/par-jour` | GET | ✓ | Tendances |
| `/api/analytics/alertes/par-type` | GET | ✓ | Distribution |

## 🔧 Configuration du backend

Assurez-vous que votre API retourne les bonnes structures :

### `/api/dashboard/metier/stats`
```json
{
  "reglesActives": 12,
  "reglesEnAttente": 2,
  "alertesNonLues": 5
}
```

### `/api/dashboard`
```json
{
  "precision": 0.92,
  "rappel": 0.88,
  "f1Score": 0.90,
  "tauxFauxPositifs": 0.05,
  "vraisPositifs": 450,
  "fauxPositifs": 25,
  "fauxNegatifs": 60,
  "vraisNegatifs": 9465,
  "totalTransactions": 10000,
  "transactionsSuspectes": 535
}
```

### `/api/alertes/historique?jours=30`
```json
[
  {
    "id": "...",
    "regleNom": "Montant anormal",
    "type": "MONTANT",
    "montant": 50000,
    "criticite": "ELEVEE",
    "horodatage": "2026-01-06T14:30:00Z"
  }
]
```

## 🎯 Prochains améliorations possibles

- [ ] Graphiques tendances (Chart.js ou fl_chart)
- [ ] Export données (CSV/PDF)
- [ ] Filtrage par date/criticité
- [ ] Alertes en temps réel (WebSocket)
- [ ] Détail des évaluations (confusion matrix)
- [ ] Comparaison périodes
