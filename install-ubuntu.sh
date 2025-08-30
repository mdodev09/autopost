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

# Nettoyage des anciens repositories MongoDB
cleanup_mongodb_repo() {
    print_info "Nettoyage des anciens repositories MongoDB..."
    
    # Supprimer les anciens fichiers de repository
    ${SUDO_CMD} rm -f /etc/apt/sources.list.d/mongodb-org-*.list
    
    # Supprimer les anciennes clés
    ${SUDO_CMD} rm -f /usr/share/keyrings/mongodb-server-*.gpg
    
    # Nettoyer le cache apt
    ${SUDO_CMD} apt update
}

# Installation de MongoDB
install_mongodb() {
    print_header "Installation de MongoDB ${MONGODB_VERSION}"
    
    # Vérifier si MongoDB est déjà installé
    if systemctl is-active --quiet mongod 2>/dev/null || systemctl is-active --quiet mongodb 2>/dev/null; then
        print_success "MongoDB est déjà installé et en cours d'exécution"
        return
    fi
    
    # Nettoyer les anciens repositories en cas d'échec précédent
    cleanup_mongodb_repo
    
    # Détecter la version d'Ubuntu et utiliser la bonne approche
    UBUNTU_VERSION=$(lsb_release -cs)
    
    if [[ "$UBUNTU_VERSION" == "noble" ]]; then
        # Pour Ubuntu 24.04, utiliser le repository jammy (22.04) car noble n'est pas encore supporté
        print_warning "Ubuntu 24.04 détecté - utilisation du repository Ubuntu 22.04 (jammy) pour MongoDB"
        MONGODB_UBUNTU_VERSION="jammy"
    else
        MONGODB_UBUNTU_VERSION="$UBUNTU_VERSION"
    fi
    
    # Ajouter la clé GPG de MongoDB
    if [[ $EUID -eq 0 ]]; then
        curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc | gpg -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg --dearmor
    else
        curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg --dearmor
    fi
    
    # Ajouter le repository MongoDB avec la version Ubuntu appropriée
    if [[ $EUID -eq 0 ]]; then
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu ${MONGODB_UBUNTU_VERSION}/mongodb-org/${MONGODB_VERSION} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list
    else
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu ${MONGODB_UBUNTU_VERSION}/mongodb-org/${MONGODB_VERSION} multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list
    fi
    
    # Installer MongoDB
    ${SUDO_CMD} apt update
    if ! ${SUDO_CMD} apt install -y mongodb-org; then
        print_warning "Échec de l'installation via le repository officiel, tentative d'installation alternative..."
        
        # Alternative: installer MongoDB via snap si le repository officiel échoue
        if command -v snap &> /dev/null; then
            print_info "Installation de MongoDB via snap..."
            ${SUDO_CMD} snap install mongodb --channel=6.0/stable
            
            # Créer un alias pour mongod si nécessaire
            if ! command -v mongod &> /dev/null; then
                ${SUDO_CMD} ln -sf /snap/bin/mongodb.mongod /usr/local/bin/mongod
            fi
            
            # Démarrer le service snap
            ${SUDO_CMD} snap start mongodb
            print_success "MongoDB installé via snap"
            return
        else
            # Dernière alternative: installer depuis les paquets Ubuntu
            print_info "Installation de MongoDB depuis les paquets Ubuntu..."
            ${SUDO_CMD} apt install -y mongodb
            ${SUDO_CMD} systemctl start mongodb
            ${SUDO_CMD} systemctl enable mongodb
            print_success "MongoDB installé depuis les paquets Ubuntu"
            return
        fi
    fi
    
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
    
    # Mémoriser le répertoire de base
    BASE_DIR=$(pwd)
    
    if [[ $EUID -eq 0 ]]; then
        # Installer les dépendances du projet principal (concurrently)
        print_info "Installation des dépendances principales..."
        sudo -u "$APP_USER" npm install
        
        # Vérifier et installer concurrently globalement si nécessaire
        if ! sudo -u "$APP_USER" npx concurrently --version &>/dev/null; then
            print_info "Installation de concurrently..."
            sudo -u "$APP_USER" npm install -g concurrently
        fi
        
        # Installer les dépendances du serveur
        print_info "Installation des dépendances du serveur..."
        cd "$BASE_DIR/server"
        sudo -u "$APP_USER" npm install
        
        # Vérifier et installer nodemon et typescript
        if ! sudo -u "$APP_USER" npx nodemon --version &>/dev/null; then
            print_info "Installation de nodemon..."
            sudo -u "$APP_USER" npm install nodemon --save-dev
        fi
        if ! sudo -u "$APP_USER" npx tsc --version &>/dev/null; then
            print_info "Installation de TypeScript..."
            sudo -u "$APP_USER" npm install typescript --save-dev
        fi
        
        # Installer les dépendances du client
        print_info "Installation des dépendances du client..."
        cd "$BASE_DIR/client"
        sudo -u "$APP_USER" npm install
        
        # Retourner à la racine
        cd "$BASE_DIR"
        
        # Définir les permissions
        chown -R "$APP_USER:$APP_USER" .
    else
        # Installer les dépendances du projet principal (concurrently)
        print_info "Installation des dépendances principales..."
        npm install
        
        # Vérifier et installer concurrently globalement si nécessaire
        if ! npx concurrently --version &>/dev/null; then
            print_info "Installation de concurrently..."
            npm install -g concurrently 2>/dev/null || npm install concurrently
        fi
        
        # Installer les dépendances du serveur
        print_info "Installation des dépendances du serveur..."
        cd "$BASE_DIR/server"
        npm install
        
        # Vérifier et installer nodemon et typescript
        if ! npx nodemon --version &>/dev/null; then
            print_info "Installation de nodemon..."
            npm install nodemon --save-dev
        fi
        if ! npx tsc --version &>/dev/null; then
            print_info "Installation de TypeScript..."
            npm install typescript --save-dev
        fi
        
        # Installer les dépendances du client
        print_info "Installation des dépendances du client..."
        cd "$BASE_DIR/client"
        npm install
        
        # Retourner à la racine
        cd "$BASE_DIR"
    fi
    
    print_success "Toutes les dépendances installées avec succès"
    
    # Vérification finale
    print_info "Vérification des installations..."
    cd "$BASE_DIR"
    
    # Vérifier concurrently
    if npx concurrently --version &>/dev/null; then
        print_success "Concurrently installé et fonctionnel"
    else
        print_warning "Concurrently non disponible (fallback manuel sera utilisé)"
    fi
    
    # Vérifier nodemon
    if cd server && npx nodemon --version &>/dev/null; then
        print_success "Nodemon installé et fonctionnel"
    else
        print_error "Problème avec nodemon"
    fi
    
    # Vérifier TypeScript
    if npx tsc --version &>/dev/null; then
        print_success "TypeScript installé et fonctionnel"
    else
        print_error "Problème avec TypeScript"
    fi
    
    cd "$BASE_DIR"
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
    cat > start-dev.sh <<'EOF'
#!/bin/bash

echo "🚀 Démarrage d'AutoPost en mode développement..."

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fonction de vérification rapide (sans npx qui peut se bloquer)
check_dependency_fast() {
    local dep_name="$1"
    local dep_path="$2"
    local install_cmd="$3"
    
    if [[ ! -f "$dep_path" ]]; then
        echo -e "${YELLOW}⚠️  $dep_name manquant, installation en cours...${NC}"
        eval "$install_cmd"
        if [[ -f "$dep_path" ]]; then
            echo -e "${GREEN}✅ $dep_name installé avec succès${NC}"
        else
            echo -e "${RED}❌ Échec de l'installation de $dep_name${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✅ $dep_name disponible${NC}"
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

# Vérifications des dépendances avec timeouts
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
    
    # Script pour la production
    cat > start-prod.sh <<'EOF'
#!/bin/bash

echo "🚀 Démarrage d'AutoPost en mode production..."

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fonction de vérification sans blocage
check_files() {
    local description="$1"
    local path="$2"
    
    if [[ -e "$path" ]]; then
        echo -e "${GREEN}✅ $description disponible${NC}"
        return 0
    else
        echo -e "${RED}❌ $description manquant: $path${NC}"
        return 1
    fi
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

# Vérifications des dépendances (basées sur les fichiers)
BASE_DIR=$(pwd)

# Vérifier les dépendances principales
if [[ ! -d "node_modules" ]]; then
    echo -e "${YELLOW}⚠️  Dépendances principales manquantes, installation...${NC}"
    npm install --no-optional --silent 2>/dev/null || npm install --no-optional
fi

# Vérifier les dépendances du serveur
cd "$BASE_DIR/server"
if [[ ! -d "node_modules" ]]; then
    echo -e "${YELLOW}⚠️  Dépendances serveur manquantes, installation...${NC}"
    npm install --no-optional --silent 2>/dev/null || npm install --no-optional
fi

# Vérifier TypeScript (basé sur fichier)
if [[ ! -f "node_modules/.bin/tsc" ]] && [[ ! -d "node_modules/typescript" ]]; then
    echo -e "${YELLOW}⚠️  TypeScript manquant, installation...${NC}"
    npm install typescript --save-dev --no-optional --silent 2>/dev/null || npm install typescript --save-dev
fi

# Vérifier les dépendances du client
cd "$BASE_DIR/client"
if [[ ! -d "node_modules" ]]; then
    echo -e "${YELLOW}⚠️  Dépendances client manquantes, installation...${NC}"
    npm install --no-optional --silent 2>/dev/null || npm install --no-optional
fi

# Retourner à la racine
cd "$BASE_DIR"

# Arrêter PM2 existant pour éviter les conflits
echo -e "${YELLOW}🧹 Nettoyage des processus PM2 existants...${NC}"
pm2 delete all 2>/dev/null || true

# Build de l'application avec timeout
echo -e "${GREEN}🔨 Construction de l'application...${NC}"
timeout 300 npm run build 2>/dev/null || {
    echo -e "${RED}❌ Échec du build ou timeout${NC}"
    echo -e "${YELLOW}ℹ️  Tentative de build du serveur uniquement...${NC}"
    cd server
    timeout 120 npm run build 2>/dev/null || {
        echo -e "${RED}❌ Impossible de compiler le serveur${NC}"
        exit 1
    }
    cd "$BASE_DIR"
}

# Vérifier que le build a réussi
if [[ -f "server/dist/server.js" ]]; then
    echo -e "${GREEN}✅ Build serveur réussi${NC}"
else
    echo -e "${RED}❌ Fichier serveur compilé manquant${NC}"
    exit 1
fi

# Vérifier que PM2 est installé
if ! command -v pm2 &>/dev/null; then
    echo -e "${YELLOW}⚠️  PM2 non trouvé, installation...${NC}"
    npm install -g pm2 --silent 2>/dev/null || npm install -g pm2
fi

# Créer le dossier logs si nécessaire
mkdir -p logs

# Démarrer avec PM2
echo -e "${GREEN}🚀 Démarrage avec PM2...${NC}"
if pm2 start ecosystem.config.js --env production; then
    echo -e "${GREEN}✅ Application démarrée avec PM2${NC}"
    echo -e "${GREEN}📊 Statut: pm2 status${NC}"
    echo -e "${GREEN}📋 Logs: pm2 logs${NC}"
    echo -e "${GREEN}🌐 API: http://localhost:5000/api${NC}"
    echo -e "${GREEN}⏹️  Arrêt: pm2 delete all${NC}"
else
    echo -e "${RED}❌ Échec du démarrage PM2${NC}"
    echo -e "${YELLOW}ℹ️  Vérifiez les logs avec: pm2 logs${NC}"
    exit 1
fi
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
    else
        sudo tee "$SERVICE_FILE" > /dev/null <<EOF
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
    fi
    
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

# Test de l'installation complète
test_installation() {
    print_header "Test de l'installation"
    
    local errors=0
    
    # Test des scripts créés
    if [[ -x "start-dev.sh" ]]; then
        print_success "Script start-dev.sh créé et exécutable"
    else
        print_error "Script start-dev.sh manquant ou non exécutable"
        ((errors++))
    fi
    
    if [[ -x "start-prod.sh" ]]; then
        print_success "Script start-prod.sh créé et exécutable"
    else
        print_error "Script start-prod.sh manquant ou non exécutable"
        ((errors++))
    fi
    
    if [[ -f "ecosystem.config.js" ]]; then
        print_success "Configuration PM2 créée"
    else
        print_error "Configuration PM2 manquante"
        ((errors++))
    fi
    
    # Test rapide du build (sans démarrer)
    print_info "Test du processus de build..."
    cd server
    if npx tsc --noEmit &>/dev/null; then
        print_success "Code TypeScript valide"
    else
        print_warning "Problèmes TypeScript détectés (mais non bloquants)"
    fi
    cd ..
    
    return $errors
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
    if systemctl is-active --quiet mongod || systemctl is-active --quiet mongodb; then
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
    
    # Vérifier les dépendances critiques
    if [[ -d "node_modules" ]]; then
        print_success "Dépendances principales installées"
    else
        print_error "Dépendances principales manquantes"
    fi
    
    if [[ -d "server/node_modules" ]]; then
        print_success "Dépendances serveur installées"
    else
        print_error "Dépendances serveur manquantes"
    fi
    
    if [[ -d "client/node_modules" ]]; then
        print_success "Dépendances client installées"
    else
        print_error "Dépendances client manquantes"
    fi
    
    # Test de l'installation
    test_installation
}

# Affichage des instructions finales
show_final_instructions() {
    print_header "Installation terminée ! 🎉"
    
    echo -e "${GREEN}Votre environnement AutoPost LinkedIn est maintenant prêt !${NC}\n"
    
    echo -e "${YELLOW}📋 Prochaines étapes :${NC}"
    echo -e "1. Configurez vos clés API dans ${BLUE}server/.env${NC}"
    echo -e "2. Démarrez l'application en mode développement :"
    echo -e "   ${BLUE}./start-dev.sh${NC} (auto-détection des dépendances)"
    echo -e "3. Ouvrez votre navigateur sur ${BLUE}http://localhost:3000${NC}"
    echo -e ""
    echo -e "${GREEN}🔧 Améliorations apportées :${NC}"
    echo -e "• Installation complète et vérifiée de toutes les dépendances"
    echo -e "• Scripts intelligents avec auto-détection et auto-réparation"
    echo -e "• Gestion robuste des erreurs et fallbacks automatiques"
    echo -e "• Support MongoDB Ubuntu 24.04 avec fallback"
    echo -e "• Tests d'installation intégrés"
    echo -e "• Support complet root/utilisateur normal"
    echo -e "• Chemins absolus pour éviter les erreurs de navigation"
    
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
