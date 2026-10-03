#!/bin/bash

# Script pour tester la connexion à l'API backend

echo "🔍 Test de connexion API"
echo "======================="

# Configuration
API_HOST="${1:-10.0.2.2}"
API_PORT="${2:-8080}"
BASE_URL="http://$API_HOST:$API_PORT"

echo "📡 Base URL: $BASE_URL"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Vérifier si le serveur répond
echo -e "${YELLOW}1️⃣  Test ping du serveur...${NC}"
if curl -s -m 5 "$BASE_URL/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Serveur accessible${NC}"
else
    echo -e "${RED}✗ Serveur n'est pas accessible${NC}"
    echo "   Essayez:"
    echo "   - Linux: ./test_api.sh localhost 8080"
    echo "   - Émulation Android: ./test_api.sh 10.0.2.2 8080"
    echo ""
    echo "   Ou testez le port:"
    echo "   - netstat -tuln | grep 8080"
    echo "   - lsof -i :8080"
    exit 1
fi

# Test 2: Test sans authentification (endpoints publics)
echo -e "\n${YELLOW}2️⃣  Test endpoints publics...${NC}"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/health")
echo "GET /api/health → $RESPONSE"

# Fonction pour tester un endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local token=$3
    
    if [ -z "$token" ]; then
        RESPONSE=$(curl -s -X $method "$BASE_URL$endpoint" -H "Content-Type: application/json")
    else
        RESPONSE=$(curl -s -X $method "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token")
    fi
    
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
}

# Test 3: Endpoints authentifiés
echo -e "\n${YELLOW}3️⃣  Endpoints authentifiés (nécessite un token valide)${NC}"

echo "ℹ️  Pour tester les endpoints, vous avez besoin d'un token JWT valide."
echo "   Connectez-vous d'abord à l'app Flutter pour obtenir un token."
echo ""
echo "   Puis lancez:"
echo "   TOKEN='votre-jwt-token' ./test_api.sh"
echo ""

if [ -z "$TOKEN" ]; then
    echo -e "${YELLOW}Token non fourni, test skippé${NC}"
else
    echo "🔑 Token: ${TOKEN:0:20}..."
    echo ""
    
    echo -e "${YELLOW}GET /api/dashboard/metier/stats${NC}"
    test_endpoint "GET" "/api/dashboard/metier/stats" "$TOKEN"
    echo ""
    
    echo -e "${YELLOW}GET /api/alertes?limit=4${NC}"
    test_endpoint "GET" "/api/alertes?limit=4" "$TOKEN"
    echo ""
    
    echo -e "${YELLOW}GET /api/demandes?limit=3${NC}"
    test_endpoint "GET" "/api/demandes?limit=3" "$TOKEN"
    echo ""
    
    echo -e "${YELLOW}GET /api/dashboard${NC}"
    test_endpoint "GET" "/api/dashboard" "$TOKEN"
fi

echo -e "\n${GREEN}✓ Tests terminés${NC}"
