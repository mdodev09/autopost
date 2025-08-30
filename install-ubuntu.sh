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
        print_warning "Script exécuté en tant que root"
        print_info "Création d'un utilisateur non-root pour l'application..."
        
        # Créer un utilisateur pour l'application si il n'existe pas
        if ! id "autopost" &>/dev/null; then
            useradd -m -s /bin/bash autopost
            usermod -aG sudo autopost
            print_success "Utilisateur 'autopost' créé"
        else
            print_success "Utilisateur 'autopost' existe déjà"
        fi
        
        # Définir les variables pour l'utilisateur
        APP_USER="autopost"
        APP_HOME="/home/autopost"
        SUDO_CMD=""
    else
        # Vérifier si l'utilisateur peut utiliser sudo
        if ! sudo -n true 2>/dev/null; then
            print_info "Ce script nécessite des privilèges sudo. Vous serez invité à saisir votre mot de passe."
        fi
        
        APP_USER=$(whoami)
        APP_HOME=$HOME
        SUDO_CMD="sudo"
    fi
}

# Mise à jour du système
update_system() {
    print_header "Mise à jour du système Ubuntu 24.04"
    
    ${SUDO_CMD} apt update && ${SUDO_CMD} apt upgrade -y
    ${SUDO_CMD} apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
    
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
    ${SUDO_CMD} apt remove -y nodejs npm 2>/dev/null || true
    
    # Installer Node.js via NodeSource
    if [[ $EUID -eq 0 ]]; then
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    else
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
    fi
    ${SUDO_CMD} apt install -y nodejs
    
    # Vérifier l'installation
    NODE_INSTALLED_VERSION=$(node --version)
    NPM_INSTALLED_VERSION=$(npm --version)
    
    print_success "Node.js ${NODE_INSTALLED_VERSION} installé"
    print_success "npm ${NPM_INSTALLED_VERSION} installé"
    
    # Installer pm2 globalement pour la gestion des processus
    if [[ $EUID -eq 0 ]]; then
        npm install -g pm2
    else
        sudo npm install -g pm2
    fi
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
    if [[ $EUID -eq 0 ]]; then
        curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc | gpg -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg --dearmor
    else
        curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg --dearmor
    fi
    
    # Ajouter le repository MongoDB
    if [[ $EUID -eq 0 ]]; then
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/${MONGODB_VERSION} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list
    else
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/${MONGODB_VERSION} multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list
    fi
    
    # Installer MongoDB
    ${SUDO_CMD} apt update
    ${SUDO_CMD} apt install -y mongodb-org
    
    # Démarrer et activer MongoDB
    ${SUDO_CMD} systemctl start mongod
    ${SUDO_CMD} systemctl enable mongod
    
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
    
    ${SUDO_CMD} apt install -y git
    print_success "Git installé avec succès"
}

# Installation d'outils supplémentaires
install_additional_tools() {
    print_header "Installation d'outils supplémentaires"
    
    ${SUDO_CMD} apt install -y \
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
    ${SUDO_CMD} ufw --force reset
    
    # Règles par défaut
    ${SUDO_CMD} ufw default deny incoming
    ${SUDO_CMD} ufw default allow outgoing
    
    # Autoriser SSH
    ${SUDO_CMD} ufw allow ssh
    
    # Autoriser les ports de l'application
    ${SUDO_CMD} ufw allow 3000/tcp  # Frontend React
    ${SUDO_CMD} ufw allow 5000/tcp  # Backend Express
    ${SUDO_CMD} ufw allow 80/tcp    # HTTP
    ${SUDO_CMD} ufw allow 443/tcp   # HTTPS
    
    # Activer UFW
    ${SUDO_CMD} ufw --force enable
    
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
    
    ${SUDO_CMD} apt install -y nginx
    ${SUDO_CMD} systemctl start nginx
    ${SUDO_CMD} systemctl enable nginx
    
    # Configuration basique de Nginx pour le reverse proxy
    if [[ $EUID -eq 0 ]]; then
        tee /etc/nginx/sites-available/${PROJECT_NAME} > /dev/null <<EOF
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
    else
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
    fi
    
    # Activer le site
    ${SUDO_CMD} ln -sf /etc/nginx/sites-available/${PROJECT_NAME} /etc/nginx/sites-enabled/
    ${SUDO_CMD} rm -f /etc/nginx/sites-enabled/default
    
    # Tester la configuration
    ${SUDO_CMD} nginx -t
    ${SUDO_CMD} systemctl reload nginx
    
    print_success "Nginx installé et configuré"
}

# Clonage et configuration du projet
setup_project() {
    print_header "Configuration du projet AutoPost"
    
    # Se déplacer dans le répertoire home de l'utilisateur approprié
    if [[ $EUID -eq 0 ]]; then
        cd "$APP_HOME"
        PROJECT_DIR="$APP_HOME/$PROJECT_NAME"
    else
        PROJECT_DIR="$PWD"
        if [[ $(basename "$PWD") != "$PROJECT_NAME" ]]; then
            PROJECT_DIR="$PWD/$PROJECT_NAME"
        fi
    fi
    
    # Demander l'URL du repository
    echo -e "${YELLOW}Si vous n'avez pas encore de repository Git, vous pouvez ignorer cette étape${NC}"
    read -p "URL du repository Git (optionnel): " REPO_URL
    
    if [[ -n "$REPO_URL" ]]; then
        # Cloner le repository
        if [[ -d "$PROJECT_DIR" ]]; then
            print_warning "Le dossier $PROJECT_DIR existe déjà"
            read -p "Voulez-vous le supprimer et cloner à nouveau ? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$PROJECT_DIR"
            else
                print_info "Utilisation du dossier existant"
                cd "$PROJECT_DIR"
            fi
        fi
        
        if [[ ! -d "$PROJECT_DIR" ]]; then
            if [[ $EUID -eq 0 ]]; then
                sudo -u "$APP_USER" git clone "$REPO_URL" "$PROJECT_DIR"
                chown -R "$APP_USER:$APP_USER" "$PROJECT_DIR"
            else
                git clone "$REPO_URL" "$PROJECT_DIR"
            fi
            cd "$PROJECT_DIR"
        fi
    else
        print_info "Utilisation du projet dans le dossier courant"
        if [[ ! -f "package.json" ]]; then
            print_error "Aucun fichier package.json trouvé dans le dossier courant"
            print_error "Veuillez vous assurer d'être dans le bon dossier ou fournir une URL de repository"
            exit 1
        fi
    fi
    
    # Installer toutes les dépendances
    print_info "Installation des dépendances du projet..."
    if [[ $EUID -eq 0 ]]; then
        sudo -u "$APP_USER" npm run install:all
        chown -R "$APP_USER:$APP_USER" .
    else
        npm run install:all
    fi
    
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
            if [[ $EUID -eq 0 ]]; then
                sudo -u "$APP_USER" tee .env > /dev/null <<EOF
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
            else
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
            fi
            print_info "Fichier .env créé avec une configuration par défaut"
        fi
    else
        print_success "Le fichier .env existe déjà"
    fi
    
    # Définir les permissions appropriées
    if [[ $EUID -eq 0 ]]; then
        chown "$APP_USER:$APP_USER" .env
        chmod 600 .env
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
    if [[ \$EUID -eq 0 ]]; then
        systemctl start mongod
    else
        sudo systemctl start mongod
    fi
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
    if [[ \$EUID -eq 0 ]]; then
        systemctl start mongod
    else
        sudo systemctl start mongod
    fi
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
    
    # Rendre les scripts exécutables et définir les permissions
    chmod +x start-dev.sh start-prod.sh
    if [[ $EUID -eq 0 ]]; then
        chown "$APP_USER:$APP_USER" start-dev.sh start-prod.sh ecosystem.config.js
    fi
    
    # Créer le dossier logs
    mkdir -p logs
    if [[ $EUID -eq 0 ]]; then
        chown "$APP_USER:$APP_USER" logs
    fi
    
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
    
    if [[ $EUID -eq 0 ]]; then
        tee "$SERVICE_FILE" > /dev/null <<EOF
    else
        sudo tee "$SERVICE_FILE" > /dev/null <<EOF
    fi
[Unit]
Description=AutoPost LinkedIn Application
After=network.target mongod.service
Wants=mongod.service

[Service]
Type=forking
User=${APP_USER}
WorkingDirectory=${PROJECT_PATH}
ExecStart=${PROJECT_PATH}/start-prod.sh
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
    
    # Recharger systemd et activer le service
    ${SUDO_CMD} systemctl daemon-reload
    ${SUDO_CMD} systemctl enable "${PROJECT_NAME}.service"
    
    print_success "Service systemd créé et activé"
    if [[ $EUID -eq 0 ]]; then
        print_info "Utilisez 'systemctl start ${PROJECT_NAME}' pour démarrer le service"
    else
        print_info "Utilisez 'sudo systemctl start ${PROJECT_NAME}' pour démarrer le service"
    fi
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
    if [[ $EUID -eq 0 ]]; then
        echo -e "• MongoDB : ${BLUE}systemctl status mongod${NC}"
        echo -e "• Firewall : ${BLUE}ufw status${NC}"
        if command -v nginx &> /dev/null; then
            echo -e "• Nginx : ${BLUE}systemctl status nginx${NC}"
        fi
    else
        echo -e "• MongoDB : ${BLUE}sudo systemctl status mongod${NC}"
        echo -e "• Firewall : ${BLUE}sudo ufw status${NC}"
        if command -v nginx &> /dev/null; then
            echo -e "• Nginx : ${BLUE}sudo systemctl status nginx${NC}"
        fi
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
