#!/bin/bash

echo "🔧 Correction des dépendances manquantes..."

# Arrêter les processus en cours
echo "🛑 Arrêt des processus en cours..."
pkill -f "npm run dev" 2>/dev/null
pkill -f "vite" 2>/dev/null
pkill -f "nodemon" 2>/dev/null

# Installer les dépendances serveur
echo "📦 Installation des dépendances serveur..."
cd server
npm install
if ! npm list nodemon >/dev/null 2>&1; then
    echo "📦 Installation de nodemon..."
    npm install nodemon --save-dev
fi
if ! npm list typescript >/dev/null 2>&1; then
    echo "📦 Installation de typescript..."
    npm install typescript --save-dev
fi
cd ..

# Installer les dépendances client
echo "📦 Installation des dépendances client..."
cd client
npm install
if ! npm list vite >/dev/null 2>&1; then
    echo "📦 Installation de vite..."
    npm install vite --save-dev
fi
cd ..

# Installer les dépendances racine
echo "📦 Installation des dépendances racine..."
npm install

echo "✅ Dépendances installées !"
echo "🚀 Vous pouvez maintenant relancer : ./start-dev.sh"
