#!/bin/bash

echo "🔄 Mise à jour des scripts avec les corrections..."

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Créer le nouveau script de développement
cat > start-dev.sh <<'EOF'
#!/bin/bash

echo "🚀 Démarrage d'AutoPost en mode développement..."

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Vérifier que MongoDB est en cours d'exécution
if ! systemctl is-active --quiet mongod && ! systemctl is-active --quiet mongodb; then
    echo "⚠️  Démarrage de MongoDB..."
    if [[ $EUID -eq 0 ]]; then
        systemctl start mongod 2>/dev/null || systemctl start mongodb 2>/dev/null
    else
        sudo systemctl start mongod 2>/dev/null || sudo systemctl start mongodb 2>/dev/null
    fi
fi

# Vérifications des dépendances sans blocage
BASE_DIR=$(pwd)

# Vérifier concurrently (vérification basée sur fichier)
if [[ ! -f "node_modules/.bin/concurrently" ]] && [[ ! -d "node_modules/concurrently" ]]; then
    echo -e "${YELLOW}⚠️  Concurrently manquant, installation...${NC}"
    npm install --no-optional 2>/dev/null || true
fi

# Vérifier les dépendances du serveur
cd "$BASE_DIR/server"
if [[ ! -d "node_modules" ]]; then
    echo -e "${YELLOW}⚠️  Dépendances serveur manquantes, installation...${NC}"
    npm install --no-optional 2>/dev/null || true
fi

# Vérifier les dépendances du client
cd "$BASE_DIR/client"
if [[ ! -d "node_modules" ]]; then
    echo -e "${YELLOW}⚠️  Dépendances client manquantes, installation...${NC}"
    npm install --no-optional 2>/dev/null || true
fi

# Retourner à la racine
cd "$BASE_DIR"

# Démarrer l'application - toujours utiliser le mode manuel pour éviter les blocages
echo -e "${GREEN}🚀 Démarrage de l'application...${NC}"

echo "Démarrage du backend..."
(cd server && npm run dev 2>/dev/null) &
BACKEND_PID=$!

echo "Démarrage du frontend..."
(cd client && npm run dev 2>/dev/null) &
FRONTEND_PID=$!

echo -e "${GREEN}Backend PID: $BACKEND_PID${NC}"
echo -e "${GREEN}Frontend PID: $FRONTEND_PID${NC}"
echo -e "${YELLOW}Appuyez sur Ctrl+C pour arrêter les deux services${NC}"
echo -e "${GREEN}🌐 Backend API: http://localhost:5000${NC}"
echo -e "${GREEN}🌐 Frontend: http://localhost:3000${NC}"

# Fonction de nettoyage améliorée
cleanup() {
    echo -e "\n${YELLOW}⏹️  Arrêt des services...${NC}"
    
    # Tuer les processus et leurs enfants
    if kill -0 $BACKEND_PID 2>/dev/null; then
        kill -TERM $BACKEND_PID 2>/dev/null || true
    fi
    
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        kill -TERM $FRONTEND_PID 2>/dev/null || true
    fi
    
    # Attendre un peu puis forcer si nécessaire
    sleep 2
    pkill -f "npm run dev" 2>/dev/null || true
    pkill -f "vite" 2>/dev/null || true
    pkill -f "nodemon" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Services arrêtés${NC}"
    exit 0
}

# Attendre que l'utilisateur appuie sur Ctrl+C
trap cleanup INT TERM EXIT
wait
EOF

# Rendre le script exécutable
chmod +x start-dev.sh

echo -e "${GREEN}✅ Script start-dev.sh mis à jour avec les corrections${NC}"

# Créer un script de test simple aussi
cat > start-dev-simple.sh <<'EOF'
#!/bin/bash

echo "🚀 Démarrage simple d'AutoPost..."

# Vérifier MongoDB
if ! systemctl is-active --quiet mongod && ! systemctl is-active --quiet mongodb; then
    echo "⚠️  Démarrage de MongoDB..."
    if [[ $EUID -eq 0 ]]; then
        systemctl start mongod 2>/dev/null || systemctl start mongodb 2>/dev/null
    else
        sudo systemctl start mongod 2>/dev/null || sudo systemctl start mongodb 2>/dev/null
    fi
fi

echo "Démarrage du backend..."
(cd server && npm run dev) &
BACKEND_PID=$!

echo "Démarrage du frontend..."
(cd client && npm run dev) &
FRONTEND_PID=$!

echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"
echo "Appuyez sur Ctrl+C pour arrêter"

cleanup() {
    echo "Arrêt des services..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
    pkill -f "npm run dev" 2>/dev/null || true
    exit 0
}

trap cleanup INT TERM
wait
EOF

chmod +x start-dev-simple.sh

echo -e "${GREEN}✅ Script start-dev-simple.sh créé${NC}"
echo -e "${YELLOW}🧪 Testez avec: ./start-dev.sh ou ./start-dev-simple.sh${NC}"
