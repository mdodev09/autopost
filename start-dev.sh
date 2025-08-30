#!/bin/bash

echo "🚀 Démarrage d'AutoPost en mode développement..."

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fonction de vérification
check_dependency() {
    local dep_name="$1"
    local check_cmd="$2"
    local install_cmd="$3"
    
    if ! eval "$check_cmd" &>/dev/null; then
        echo -e "${YELLOW}⚠️  $dep_name manquant, installation en cours...${NC}"
        eval "$install_cmd"
        if ! eval "$check_cmd" &>/dev/null; then
            echo -e "${RED}❌ Échec de l'installation de $dep_name${NC}"
            return 1
        fi
        echo -e "${GREEN}✅ $dep_name installé avec succès${NC}"
    fi
    return 0
}

# Vérifier que MongoDB est en cours d'exécution
if ! systemctl is-active --quiet mongod && ! systemctl is-active --quiet mongodb; then
    echo "⚠️  Démarrage de MongoDB..."
    if [[ $EUID -eq 0 ]]; then
        systemctl start mongod 2>/dev/null || systemctl start mongodb 2>/dev/null
    else
        sudo systemctl start mongod 2>/dev/null || sudo systemctl start mongodb 2>/dev/null
    fi
fi

# Vérifications des dépendances
BASE_DIR=$(pwd)

# Vérifier concurrently
check_dependency "concurrently" "npx concurrently --version" "npm install"

# Vérifier nodemon pour le serveur
cd "$BASE_DIR/server"
check_dependency "nodemon" "npx nodemon --version" "npm install"

# Vérifier les dépendances du client
cd "$BASE_DIR/client"
if [[ ! -d "node_modules" ]]; then
    echo -e "${YELLOW}⚠️  Dépendances client manquantes, installation...${NC}"
    npm install
fi

# Retourner à la racine
cd "$BASE_DIR"

# Démarrer l'application avec concurrently si disponible, sinon manuellement
if npx concurrently --version &>/dev/null; then
    echo -e "${GREEN}🚀 Démarrage avec concurrently...${NC}"
    npm run dev
else
    echo -e "${YELLOW}🚀 Démarrage manuel (concurrently non disponible)...${NC}"
    
    echo "Démarrage du backend..."
    (cd server && npm run dev) &
    BACKEND_PID=$!

    echo "Démarrage du frontend..."
    (cd client && npm run dev) &
    FRONTEND_PID=$!

    echo -e "${GREEN}Backend PID: $BACKEND_PID${NC}"
    echo -e "${GREEN}Frontend PID: $FRONTEND_PID${NC}"
    echo -e "${YELLOW}Appuyez sur Ctrl+C pour arrêter les deux services${NC}"

    # Fonction de nettoyage
    cleanup() {
        echo -e "\n${YELLOW}Arrêt des services...${NC}"
        kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
        exit 0
    }

    # Attendre que l'utilisateur appuie sur Ctrl+C
    trap cleanup INT TERM
    wait
fi