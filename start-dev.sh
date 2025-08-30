#!/bin/bash

echo "🚀 Démarrage d'AutoPost en mode développement..."

# Vérifier que MongoDB est en cours d'exécution
if ! systemctl is-active --quiet mongod; then
    echo "⚠️  Démarrage de MongoDB..."
    systemctl start mongod
fi

# Démarrer l'application
npm run dev