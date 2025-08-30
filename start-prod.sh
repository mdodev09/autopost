#!/bin/bash

echo "🚀 Démarrage d'AutoPost en mode production..."

# Vérifier que MongoDB est en cours d'exécution
if ! systemctl is-active --quiet mongod; then
    echo "⚠️  Démarrage de MongoDB..."
    systemctl start mongod
fi

# Build de l'application
npm run build

# Démarrer avec PM2
pm2 start ecosystem.config.js --env production

echo "✅ Application démarrée avec PM2"
echo "📊 Utilisez 'pm2 status' pour voir l'état"
echo "📋 Utilisez 'pm2 logs' pour voir les logs"