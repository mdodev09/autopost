#!/bin/bash

echo "🌐 Informations du serveur AutoPost LinkedIn"
echo "=============================================="

# Obtenir l'IP externe
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "Non disponible")

# Obtenir l'IP locale
LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "Non disponible")

echo ""
echo "📍 IPs du serveur :"
echo "   Local: $LOCAL_IP"
echo "   Externe: $EXTERNAL_IP"
echo ""
echo "🌐 URLs d'accès :"
echo "   Frontend: http://$LOCAL_IP:3000"
echo "   Backend API: http://$LOCAL_IP:5000/api"
echo ""
if [[ "$EXTERNAL_IP" != "Non disponible" ]]; then
    echo "🌍 URLs externes (si le port forwarding est configuré) :"
    echo "   Frontend: http://$EXTERNAL_IP:3000"
    echo "   Backend API: http://$EXTERNAL_IP:5000/api"
    echo ""
fi
echo "🔧 Ports utilisés :"
echo "   3000 - Frontend (React/Vite)"
echo "   5000 - Backend (Express/API)"
echo ""
echo "📋 Commandes utiles :"
echo "   ./start-dev-fixed.sh    - Démarrer l'application"
echo "   pm2 status             - Voir le statut PM2"
echo "   pm2 logs               - Voir les logs"
echo "   ufw status             - Vérifier le firewall"
