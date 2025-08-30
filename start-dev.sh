#!/bin/bash

echo "🚀 Démarrage d'AutoPost en mode développement..."

# Vérifier MongoDB rapidement
if ! systemctl is-active --quiet mongod && ! systemctl is-active --quiet mongodb; then
    echo "⚠️  Démarrage de MongoDB..."
    systemctl start mongod 2>/dev/null || systemctl start mongodb 2>/dev/null
fi

echo "✅ Démarrage direct sans vérifications (pour éviter les blocages)..."

echo "📦 Backend..."
(cd server && npm run dev) &
BACKEND_PID=$!

echo "📦 Frontend..."  
(cd client && npm run dev) &
FRONTEND_PID=$!

echo "✅ Backend PID: $BACKEND_PID"
echo "✅ Frontend PID: $FRONTEND_PID"
echo "🌐 Backend: http://0.0.0.0:5000"
echo "🌐 Frontend: http://0.0.0.0:3000"
echo "🌍 Accessible depuis l'extérieur via l'IP du serveur"
echo "⏹️  Ctrl+C pour arrêter"

cleanup() {
    echo "🛑 Arrêt..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    pkill -f "npm run dev" 2>/dev/null
    pkill -f "vite" 2>/dev/null
    pkill -f "nodemon" 2>/dev/null
    exit 0
}

trap cleanup INT TERM
wait