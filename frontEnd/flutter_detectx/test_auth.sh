#!/bin/bash

# Script de Test d'Authentification API
# Usage: ./test_auth.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Test d'Authentification FlowDetectX API      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Configuration
API_URL="${1:-http://10.0.2.2:8080}"
IDENTIFIANT="${2:-admin}"
PASSWORD="${3:-admin123}"

echo -e "${YELLOW}Configuration:${NC}"
echo "  URL API: $API_URL"
echo "  Identifiant: $IDENTIFIANT"
echo "  Mot de passe: ***"
echo ""

# Test 1: Vérifier la connectivité au serveur
echo -e "${BLUE}[1/4] Vérification de la connectivité au serveur...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/auth/login" \
  -X OPTIONS \
  -H "Content-Type: application/json" 2>/dev/null)

if [ -z "$HTTP_CODE" ]; then
  echo -e "${RED}❌ Impossible de se connecter au serveur${NC}"
  echo "   Vérifiez:"
  echo "   - L'URL API est correcte: $API_URL"
  echo "   - Le serveur est en ligne"
  echo "   - Le port 8080 est accessible"
  exit 1
fi
echo -e "${GREEN}✅ Connectivité OK${NC}"
echo ""

# Test 2: Vérifier la réponse du serveur
echo -e "${BLUE}[2/4] Test de la réponse du serveur (OPTIONS)...${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/api/auth/login" \
  -X OPTIONS \
  -H "Content-Type: application/json" 2>/dev/null)

STATUS_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo "  Code HTTP: $STATUS_CODE"
if [ "$STATUS_CODE" = "200" ] || [ "$STATUS_CODE" = "405" ] || [ "$STATUS_CODE" = "204" ]; then
  echo -e "${GREEN}✅ Serveur répond${NC}"
else
  echo -e "${RED}⚠️  Réponse inattendue (HTTP $STATUS_CODE)${NC}"
fi
echo ""

# Test 3: Tentative de connexion
echo -e "${BLUE}[3/4] Tentative de connexion...${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/api/auth/login" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{\"identifiant\":\"$IDENTIFIANT\",\"motDePasse\":\"$PASSWORD\"}" 2>/dev/null)

STATUS_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo "  Code HTTP: $STATUS_CODE"
echo "  Réponse: $BODY"
echo ""

# Test 4: Analyse du résultat
echo -e "${BLUE}[4/4] Analyse du résultat...${NC}"
if [ "$STATUS_CODE" = "200" ]; then
  echo -e "${GREEN}✅ SUCCÈS - Connexion réussie!${NC}"
  echo "  Les identifiants sont corrects"
  TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4 | head -1)
  if [ ! -z "$TOKEN" ]; then
    echo "  Token reçu: ${TOKEN:0:30}..."
  fi
elif [ "$STATUS_CODE" = "401" ] || [ "$STATUS_CODE" = "403" ]; then
  echo -e "${YELLOW}⚠️  Identifiants incorrects${NC}"
  echo "  Vérifiez vos identifiants et réessayez"
  echo "  Command: ./test_auth.sh $API_URL votre_id votre_pwd"
elif [ "$STATUS_CODE" = "408" ] || [ "$STATUS_CODE" = "504" ]; then
  echo -e "${RED}❌ Timeout - Serveur trop lent${NC}"
  echo "  - Le serveur met trop de temps à répondre"
  echo "  - Vérifiez la charge serveur"
  echo "  - Vérifiez la bande passante réseau"
elif [ "$STATUS_CODE" = "500" ]; then
  echo -e "${RED}❌ Erreur serveur (500)${NC}"
  echo "  - Une erreur s'est produite sur le serveur"
  echo "  - Vérifiez les logs du serveur"
else
  echo -e "${YELLOW}⚠️  Réponse inattendue (HTTP $STATUS_CODE)${NC}"
  echo "  Réponse reçue: $BODY"
fi
echo ""

# Résumé
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Résumé du Test                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo "Prochaines étapes:"
echo "1. Si vous avez une erreur, vérifiez:"
echo "   - Que le serveur backend est démarré"
echo "   - L'URL API: $API_URL"
echo "   - Les identifiants"
echo ""
echo "2. Pour tester avec une autre URL:"
echo "   ./test_auth.sh http://192.168.X.X:8080 votre_id votre_pwd"
echo ""
echo "3. Vérifiez aussi:"
echo "   - Les logs du serveur"
echo "   - Les logs Flutter: flutter run"
echo ""
