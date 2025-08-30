#!/bin/bash

echo "🚀 Démarrage d'AutoPost en mode développement..."

# Vérifier que MongoDB est en cours d'exécution
if ! systemctl is-active --quiet mongod; then
    echo "⚠️  Démarrage de MongoDB..."
    systemctl start mongod
fi

# Vérifier si concurrently est installé
if ! command -v concurrently &> /dev/null && ! npx concurrently --version &> /dev/null 2>&1; then
    echo "⚠️  Installation de concurrently manquante, installation en cours..."
    npm install
fi

# Démarrer l'application avec concurrently si disponible, sinon manuellement
if command -v concurrently &> /dev/null || npx concurrently --version &> /dev/null 2>&1; then
    npm run dev
else
    echo "Démarrage du backend..."
    (cd server && npm run dev) &
    BACKEND_PID=$!

    echo "Démarrage du frontend..."
    (cd client && npm run dev) &
    FRONTEND_PID=$!

    echo "Backend PID: $BACKEND_PID"
    echo "Frontend PID: $FRONTEND_PID"
    echo "Appuyez sur Ctrl+C pour arrêter les deux services"

    # Attendre que l'utilisateur appuie sur Ctrl+C
    trap 'kill $BACKEND_PID $FRONTEND_PID' INT
    wait
fi