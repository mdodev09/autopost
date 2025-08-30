#!/bin/bash

# =============================================================================
# Script d'installation automatisé pour AutoPost LinkedIn sur Ubuntu 24.04
# =============================================================================

set -e  # Arrêter le script en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
PROJECT_NAME="autopost-linkedin"
NODE_VERSION="20"
MONGODB_VERSION="7.0"
NGINX_DOMAIN=""

# Fonctions utilitaires
print_header() {
    echo -e "\n${BLUE}==============================================================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}==============================================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Vérification des privilèges
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Ce script ne doit pas être exécuté en tant que root"
        print_info "Utilisez: ./install-ubuntu.sh"
        exit 1
    fi

    # Vérifier si l'utilisateur peut utiliser sudo
    if ! sudo -n true 2>/dev/null; then
        print_info "Ce script nécessite des privilèges sudo. Vous serez invité à saisir votre mot de passe."
    fi
}

# Mise à jour du système
update_system() {
    print_header "Mise à jour du système Ubuntu 24.04"
    
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
    
    print_success "Système mis à jour avec succès"
}

# Installation de Node.js via NodeSource
install_nodejs() {
    print_header "Installation de Node.js ${NODE_VERSION}"
    
    # Vérifier si Node.js est déjà installé
    if command -v node &> /dev/null; then
        CURRENT_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
        if [[ "$CURRENT_VERSION" -ge "$NODE_VERSION" ]]; then
            print_success "Node.js ${CURRENT_VERSION} est déjà installé"
            return
        fi
    fi
    
    # Supprimer les anciennes versions
    sudo apt remove -y nodejs npm 2>/dev/null || true
    
    # Installer Node.js via NodeSource
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
    sudo apt install -y nodejs
    
    # Vérifier l'installation
    NODE_INSTALLED_VERSION=$(node --version)
    NPM_INSTALLED_VERSION=$(npm --version)
    
    print_success "Node.js ${NODE_INSTALLED_VERSION} installé"
    print_success "npm ${NPM_INSTALLED_VERSION} installé"
    
    # Installer pm2 globalement pour la gestion des processus
    sudo npm install -g pm2
    print_success "PM2 installé globalement"
}

# Installation de MongoDB
install_mongodb() {
    print_header "Installation de MongoDB ${MONGODB_VERSION}"
    
    # Vérifier si MongoDB est déjà installé
    if systemctl is-active --quiet mongod 2>/dev/null; then
        print_success "MongoDB est déjà installé et en cours d'exécution"
        return
    fi
    
    # Ajouter la clé GPG de MongoDB
    curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg --dearmor
    
    # Ajouter le repository MongoDB
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/${MONGODB_VERSION} multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list
    
    # Installer MongoDB
    sudo apt update
    sudo apt install -y mongodb-org
    
    # Démarrer et activer MongoDB
    sudo systemctl start mongod
    sudo systemctl enable mongod
    
    # Vérifier l'installation
    if systemctl is-active --quiet mongod; then
        print_success "MongoDB installé et démarré avec succès"
    else
        print_error "Échec du démarrage de MongoDB"
        exit 1
    fi
}

# Installation de Git (si pas déjà installé)
install_git() {
    print_header "Installation de Git"
    
    if command -v git &> /dev/null; then
        print_success "Git est déjà installé ($(git --version))"
        return
    fi
    
    sudo apt install -y git
    print_success "Git installé avec succès"
}

# Installation d'outils supplémentaires
install_additional_tools() {
    print_header "Installation d'outils supplémentaires"
    
    sudo apt install -y \
        build-essential \
        python3-pip \
        ufw \
        fail2ban \
        htop \
        tree \
        unzip \
        vim \
        nano
    
    print_success "Outils supplémentaires installés"
}

# Configuration du firewall
configure_firewall() {
    print_header "Configuration du firewall (UFW)"
    
    # Réinitialiser UFW
    sudo ufw --force reset
    
    # Règles par défaut
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Autoriser SSH
    sudo ufw allow ssh
    
    # Autoriser les ports de l'application
    sudo ufw allow 3000/tcp  # Frontend React
    sudo ufw allow 5000/tcp  # Backend Express
    sudo ufw allow 80/tcp    # HTTP
    sudo ufw allow 443/tcp   # HTTPS
    
    # Activer UFW
    sudo ufw --force enable
    
    print_success "Firewall configuré et activé"
}

# Installation de Nginx (optionnel)
install_nginx() {
    print_header "Installation de Nginx"
    
    read -p "Voulez-vous installer Nginx comme reverse proxy ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation de Nginx ignorée"
        return
    fi
    
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    # Configuration basique de Nginx pour le reverse proxy
    sudo tee /etc/nginx/sites-available/${PROJECT_NAME} > /dev/null <<EOF
server {
    listen 80;
    server_name localhost;

    # Frontend React
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
    
    # Activer le site
    sudo ln -sf /etc/nginx/sites-available/${PROJECT_NAME} /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Tester la configuration
    sudo nginx -t
    sudo systemctl reload nginx
    
    print_success "Nginx installé et configuré"
}

# Clonage et configuration du projet
setup_project() {
    print_header "Configuration du projet AutoPost"
    
    # Demander l'URL du repository
    echo -e "${YELLOW}Si vous n'avez pas encore de repository Git, vous pouvez ignorer cette étape${NC}"
    read -p "URL du repository Git (optionnel): " REPO_URL
    
    if [[ -n "$REPO_URL" ]]; then
        # Cloner le repository
        if [[ -d "$PROJECT_NAME" ]]; then
            print_warning "Le dossier $PROJECT_NAME existe déjà"
            read -p "Voulez-vous le supprimer et cloner à nouveau ? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$PROJECT_NAME"
            else
                print_info "Utilisation du dossier existant"
                cd "$PROJECT_NAME"
            fi
        fi
        
        if [[ ! -d "$PROJECT_NAME" ]]; then
            git clone "$REPO_URL" "$PROJECT_NAME"
            cd "$PROJECT_NAME"
        fi
    else
        print_info "Création d'un nouveau projet dans le dossier courant"
        if [[ ! -f "package.json" ]]; then
            print_error "Aucun fichier package.json trouvé dans le dossier courant"
            print_error "Veuillez vous assurer d'être dans le bon dossier ou fournir une URL de repository"
            exit 1
        fi
    fi
    
    # Installer toutes les dépendances
    print_info "Installation des dépendances du projet..."
    npm run install:all
    
    print_success "Dépendances installées avec succès"
}

# Configuration des variables d'environnement
configure_environment() {
    print_header "Configuration des variables d'environnement"
    
    cd server
    
    if [[ ! -f ".env" ]]; then
        if [[ -f "env.example" ]]; then
            cp env.example .env
            print_info "Fichier .env créé à partir de env.example"
        else
            # Créer un fichier .env basique
            cat > .env <<EOF
# Configuration Base de données
MONGODB_URI=mongodb://localhost:27017/autopost

# Configuration JWT
JWT_SECRET=$(openssl rand -hex 32)
JWT_EXPIRE=7d

# Configuration OpenAI
OPENAI_API_KEY=votre_cle_api_openai

# Configuration LinkedIn OAuth
LINKEDIN_CLIENT_ID=votre_client_id_linkedin
LINKEDIN_CLIENT_SECRET=votre_client_secret_linkedin
LINKEDIN_REDIRECT_URI=http://localhost:5000/api/auth/linkedin/callback

# Configuration serveur
NODE_ENV=development
PORT=5000
FRONTEND_URL=http://localhost:3000
EOF
            print_info "Fichier .env créé avec une configuration par défaut"
        fi
    else
        print_success "Le fichier .env existe déjà"
    fi
    
    print_warning "N'oubliez pas de configurer vos clés API dans le fichier server/.env :"
    echo -e "  ${YELLOW}- OPENAI_API_KEY${NC}"
    echo -e "  ${YELLOW}- LINKEDIN_CLIENT_ID${NC}"
    echo -e "  ${YELLOW}- LINKEDIN_CLIENT_SECRET${NC}"
    
    cd ..
}

# Création du script de démarrage
create_startup_script() {
    print_header "Création du script de démarrage"
    
    # Script pour le développement
    cat > start-dev.sh <<EOF
#!/bin/bash

echo "🚀 Démarrage d'AutoPost en mode développement..."

# Vérifier que MongoDB est en cours d'exécution
if ! systemctl is-active --quiet mongod; then
    echo "⚠️  Démarrage de MongoDB..."
    sudo systemctl start mongod
fi

# Démarrer l'application
npm run dev
EOF
    
    # Script pour la production
    cat > start-prod.sh <<EOF
#!/bin/bash

echo "🚀 Démarrage d'AutoPost en mode production..."

# Vérifier que MongoDB est en cours d'exécution
if ! systemctl is-active --quiet mongod; then
    echo "⚠️  Démarrage de MongoDB..."
    sudo systemctl start mongod
fi

# Build de l'application
npm run build

# Démarrer avec PM2
pm2 start ecosystem.config.js --env production

echo "✅ Application démarrée avec PM2"
echo "📊 Utilisez 'pm2 status' pour voir l'état"
echo "📋 Utilisez 'pm2 logs' pour voir les logs"
EOF
    
    # Configuration PM2
    cat > ecosystem.config.js <<EOF
module.exports = {
  apps: [
    {
      name: '${PROJECT_NAME}-server',
      script: './server/dist/server.js',
      cwd: '.',
      env: {
        NODE_ENV: 'production',
        PORT: 5000
      },
      instances: 1,
      exec_mode: 'cluster',
      max_memory_restart: '1G',
      error_file: './logs/server-error.log',
      out_file: './logs/server-out.log',
      log_file: './logs/server-combined.log',
      time: true
    }
  ]
};
EOF
    
    # Rendre les scripts exécutables
    chmod +x start-dev.sh start-prod.sh
    
    # Créer le dossier logs
    mkdir -p logs
    
    print_success "Scripts de démarrage créés"
}

# Configuration du service systemd (optionnel)
create_systemd_service() {
    print_header "Création du service systemd"
    
    read -p "Voulez-vous créer un service systemd pour démarrer automatiquement l'application ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Création du service systemd ignorée"
        return
    fi
    
    SERVICE_FILE="/etc/systemd/system/${PROJECT_NAME}.service"
    PROJECT_PATH=$(pwd)
    USER=$(whoami)
    
    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=AutoPost LinkedIn Application
After=network.target mongod.service
Wants=mongod.service

[Service]
Type=forking
User=${USER}
WorkingDirectory=${PROJECT_PATH}
ExecStart=${PROJECT_PATH}/start-prod.sh
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
    
    # Recharger systemd et activer le service
    sudo systemctl daemon-reload
    sudo systemctl enable "${PROJECT_NAME}.service"
    
    print_success "Service systemd créé et activé"
    print_info "Utilisez 'sudo systemctl start ${PROJECT_NAME}' pour démarrer le service"
}

# Vérification finale
final_checks() {
    print_header "Vérifications finales"
    
    # Vérifier Node.js
    if command -v node &> /dev/null; then
        print_success "Node.js: $(node --version)"
    else
        print_error "Node.js non trouvé"
    fi
    
    # Vérifier npm
    if command -v npm &> /dev/null; then
        print_success "npm: $(npm --version)"
    else
        print_error "npm non trouvé"
    fi
    
    # Vérifier MongoDB
    if systemctl is-active --quiet mongod; then
        print_success "MongoDB: En cours d'exécution"
    else
        print_warning "MongoDB: Arrêté"
    fi
    
    # Vérifier PM2
    if command -v pm2 &> /dev/null; then
        print_success "PM2: $(pm2 --version)"
    else
        print_error "PM2 non trouvé"
    fi
    
    # Vérifier le projet
    if [[ -f "package.json" ]]; then
        print_success "Projet: package.json trouvé"
    else
        print_error "Projet: package.json non trouvé"
    fi
    
    if [[ -f "server/.env" ]]; then
        print_success "Configuration: server/.env trouvé"
    else
        print_warning "Configuration: server/.env non trouvé"
    fi
}

# Affichage des instructions finales
show_final_instructions() {
    print_header "Installation terminée ! 🎉"
    
    echo -e "${GREEN}Votre environnement AutoPost LinkedIn est maintenant prêt !${NC}\n"
    
    echo -e "${YELLOW}📋 Prochaines étapes :${NC}"
    echo -e "1. Configurez vos clés API dans ${BLUE}server/.env${NC}"
    echo -e "2. Démarrez l'application en mode développement :"
    echo -e "   ${BLUE}./start-dev.sh${NC}"
    echo -e "3. Ouvrez votre navigateur sur ${BLUE}http://localhost:3000${NC}"
    
    echo -e "\n${YELLOW}🛠️  Scripts disponibles :${NC}"
    echo -e "• ${BLUE}./start-dev.sh${NC}    - Mode développement"
    echo -e "• ${BLUE}./start-prod.sh${NC}   - Mode production avec PM2"
    echo -e "• ${BLUE}npm run dev${NC}       - Développement (frontend + backend)"
    echo -e "• ${BLUE}npm run build${NC}     - Build pour la production"
    
    echo -e "\n${YELLOW}🔧 Services :${NC}"
    echo -e "• MongoDB : ${BLUE}sudo systemctl status mongod${NC}"
    echo -e "• Firewall : ${BLUE}sudo ufw status${NC}"
    if command -v nginx &> /dev/null; then
        echo -e "• Nginx : ${BLUE}sudo systemctl status nginx${NC}"
    fi
    
    echo -e "\n${YELLOW}📖 Documentation :${NC}"
    echo -e "• README.md pour plus d'informations"
    echo -e "• API disponible sur ${BLUE}http://localhost:5000/api${NC}"
    
    echo -e "\n${YELLOW}🆘 Support :${NC}"
    echo -e "• Logs PM2 : ${BLUE}pm2 logs${NC}"
    echo -e "• Statut PM2 : ${BLUE}pm2 status${NC}"
    echo -e "• Redémarrer PM2 : ${BLUE}pm2 restart all${NC}"
    
    print_success "Bonne utilisation d'AutoPost LinkedIn ! 🚀"
}

# Fonction principale
main() {
    print_header "🚀 Installation d'AutoPost LinkedIn sur Ubuntu 24.04"
    
    # Vérifications préliminaires
    check_sudo
    
    # Installation des composants
    update_system
    install_git
    install_nodejs
    install_mongodb
    install_additional_tools
    configure_firewall
    install_nginx
    
    # Configuration du projet
    setup_project
    configure_environment
    create_startup_script
    create_systemd_service
    
    # Vérifications et instructions finales
    final_checks
    show_final_instructions
}

# Gestion des erreurs
trap 'print_error "Une erreur est survenue. Installation interrompue."; exit 1' ERR

# Exécution du script
main "$@"
