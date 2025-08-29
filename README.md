# AutoPost LinkedIn 🚀

Une application web moderne pour générer automatiquement des posts LinkedIn engageants en utilisant l'intelligence artificielle (ChatGPT) et publier directement sur LinkedIn.

## ✨ Fonctionnalités

- **🤖 Génération de posts IA** : Créez des posts LinkedIn professionnels avec ChatGPT
- **🔐 Authentification sécurisée** : Système de connexion avec JWT
- **🔗 Intégration LinkedIn** : Publication automatique sur votre profil LinkedIn
- **📅 Programmation** : Planifiez vos posts à l'avance
- **📊 Analytics** : Suivez les performances de vos posts (likes, commentaires, partages)
- **🎨 Interface moderne** : Design responsive avec Tailwind CSS
- **⚡ Temps réel** : Interface réactive avec React Query

## 🛠️ Technologies

### Backend
- **Node.js** + **Express** + **TypeScript**
- **MongoDB** avec Mongoose
- **JWT** pour l'authentification
- **OpenAI API** pour la génération de contenu
- **LinkedIn API** pour la publication

### Frontend
- **React 18** + **TypeScript**
- **Tailwind CSS** pour le design
- **React Query** pour la gestion d'état
- **React Hook Form** pour les formulaires
- **React Router** pour la navigation

## 🚀 Installation

### Prérequis

- Node.js 18+
- MongoDB
- Compte OpenAI avec clé API
- Application LinkedIn (Client ID et Secret)

### 1. Cloner le repository

```bash
git clone https://github.com/votre-username/autopost-linkedin.git
cd autopost-linkedin
```

### 2. Installer les dépendances

```bash
# Installer toutes les dépendances (root, server, client)
npm run install:all
```

### 3. Configuration du backend

```bash
cd server
cp env.example .env
```

Remplir le fichier `.env` avec vos configurations :

```env
# Base de données
MONGODB_URI=mongodb://localhost:27017/autopost

# JWT
JWT_SECRET=votre_jwt_secret_tres_securise_ici
JWT_EXPIRE=7d

# OpenAI
OPENAI_API_KEY=sk-votre_cle_api_openai

# LinkedIn OAuth
LINKEDIN_CLIENT_ID=votre_client_id_linkedin
LINKEDIN_CLIENT_SECRET=votre_client_secret_linkedin
LINKEDIN_REDIRECT_URI=http://localhost:5000/api/auth/linkedin/callback

# Serveur
NODE_ENV=development
PORT=5000
FRONTEND_URL=http://localhost:3000
```

### 4. Configuration LinkedIn

1. Créez une application sur [LinkedIn Developers](https://www.linkedin.com/developers/)
2. Ajoutez les permissions : `r_liteprofile`, `r_emailaddress`, `w_member_social`
3. Configurez l'URL de redirection : `http://localhost:5000/api/auth/linkedin/callback`

### 5. Démarrage en développement

```bash
# Depuis la racine du projet
npm run dev
```

Cela démarre :
- Backend sur http://localhost:5000
- Frontend sur http://localhost:3000

## 📁 Structure du projet

```
autopost/
├── client/                 # Frontend React
│   ├── src/
│   │   ├── components/     # Composants réutilisables
│   │   ├── contexts/       # Contextes React
│   │   ├── hooks/          # Hooks personnalisés
│   │   ├── pages/          # Pages de l'application
│   │   ├── services/       # Services API
│   │   └── types/          # Types TypeScript
│   └── package.json
├── server/                 # Backend Node.js
│   ├── src/
│   │   ├── config/         # Configuration DB
│   │   ├── controllers/    # Contrôleurs API
│   │   ├── middleware/     # Middlewares
│   │   ├── models/         # Modèles MongoDB
│   │   ├── routes/         # Routes API
│   │   ├── services/       # Services (OpenAI, LinkedIn)
│   │   └── types/          # Types TypeScript
│   └── package.json
└── package.json            # Scripts globaux
```

## 🔧 Scripts disponibles

```bash
# Développement
npm run dev                 # Démarre frontend + backend

# Backend seulement
npm run server:dev          # Démarre le backend en mode dev

# Frontend seulement
npm run client:dev          # Démarre le frontend en mode dev

# Production
npm run build              # Build frontend + backend
npm start                  # Démarre en production

# Installation
npm run install:all        # Installe toutes les dépendances
```

## 🌍 Déploiement

### Variables d'environnement de production

Assurez-vous de configurer les variables suivantes pour la production :

- `NODE_ENV=production`
- `MONGODB_URI` (MongoDB Atlas recommandé)
- `JWT_SECRET` (généré de manière sécurisée)
- `OPENAI_API_KEY`
- `LINKEDIN_CLIENT_ID` et `LINKEDIN_CLIENT_SECRET`
- `LINKEDIN_REDIRECT_URI` (URL de production)

### Plateformes recommandées

- **Backend** : Heroku, Vercel, Railway
- **Frontend** : Vercel, Netlify
- **Base de données** : MongoDB Atlas

## 🔒 Sécurité

- Chiffrement des mots de passe avec bcrypt
- Authentification JWT sécurisée
- Tokens LinkedIn stockés de manière sécurisée
- Rate limiting sur l'API
- Validation des données d'entrée
- Protection CORS

## 📝 API Endpoints

### Authentification
- `POST /api/auth/register` - Inscription
- `POST /api/auth/login` - Connexion
- `GET /api/auth/profile` - Profil utilisateur
- `GET /api/auth/linkedin/auth` - URL d'auth LinkedIn
- `GET /api/auth/linkedin/callback` - Callback LinkedIn

### Posts
- `POST /api/posts/generate` - Générer un post
- `GET /api/posts` - Liste des posts
- `GET /api/posts/:id` - Détails d'un post
- `PUT /api/posts/:id` - Modifier un post
- `DELETE /api/posts/:id` - Supprimer un post
- `POST /api/posts/:id/publish` - Publier un post
- `POST /api/posts/schedule` - Programmer un post

## 🤝 Contribution

1. Fork le projet
2. Créez une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🆘 Support

Si vous rencontrez des problèmes :

1. Vérifiez les [issues existantes](https://github.com/votre-username/autopost-linkedin/issues)
2. Créez une nouvelle issue avec les détails du problème
3. Contactez l'équipe de développement

## 🎯 Roadmap

- [ ] Support de multiples comptes LinkedIn
- [ ] Templates de posts personnalisables
- [ ] Analytics avancées
- [ ] Intégration avec d'autres réseaux sociaux
- [ ] Mode sombre
- [ ] Application mobile

---

Fait avec ❤️ par [MDO Services](https://github.com/votre-username)
