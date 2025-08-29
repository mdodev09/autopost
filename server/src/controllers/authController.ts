import { Request, Response } from 'express';
import { validationResult } from 'express-validator';
import User from '../models/User';
import { generateToken, AuthRequest } from '../middleware/auth';
import linkedinService from '../services/linkedinService';

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    // Vérifier les erreurs de validation
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ 
        message: 'Données invalides', 
        errors: errors.array() 
      });
      return;
    }

    const { email, password, firstName, lastName } = req.body;

    // Vérifier si l'utilisateur existe déjà
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      res.status(409).json({ message: 'Un utilisateur avec cet email existe déjà' });
      return;
    }

    // Créer le nouvel utilisateur
    const user = new User({
      email,
      password,
      firstName,
      lastName
    });

    await user.save();

    // Générer le token
    const token = generateToken(user._id.toString(), user.email);

    res.status(201).json({
      message: 'Utilisateur créé avec succès',
      token,
      user: {
        id: user._id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName
      }
    });
  } catch (error) {
    console.error('Erreur lors de l\'inscription:', error);
    res.status(500).json({ message: 'Erreur serveur lors de l\'inscription' });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    // Vérifier les erreurs de validation
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ 
        message: 'Données invalides', 
        errors: errors.array() 
      });
      return;
    }

    const { email, password } = req.body;

    // Trouver l'utilisateur
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      res.status(401).json({ message: 'Email ou mot de passe incorrect' });
      return;
    }

    // Vérifier le mot de passe
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      res.status(401).json({ message: 'Email ou mot de passe incorrect' });
      return;
    }

    // Générer le token
    const token = generateToken(user._id.toString(), user.email);

    res.json({
      message: 'Connexion réussie',
      token,
      user: {
        id: user._id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        linkedinConnected: !!user.linkedinAccessToken
      }
    });
  } catch (error) {
    console.error('Erreur lors de la connexion:', error);
    res.status(500).json({ message: 'Erreur serveur lors de la connexion' });
  }
};

export const getProfile = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = await User.findById(req.user?.userId);
    if (!user) {
      res.status(404).json({ message: 'Utilisateur non trouvé' });
      return;
    }

    res.json({
      user: {
        id: user._id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        linkedinConnected: !!user.linkedinAccessToken,
        linkedinProfile: user.linkedinProfile
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération du profil:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

export const getLinkedInAuthUrl = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const state = `${req.user?.userId}-${Date.now()}`;
    const authUrl = linkedinService.getAuthorizationUrl(state);
    
    res.json({ authUrl, state });
  } catch (error) {
    console.error('Erreur lors de la génération de l\'URL LinkedIn:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

export const handleLinkedInCallback = async (req: Request, res: Response): Promise<void> => {
  try {
    const { code, state } = req.query;
    
    if (!code || !state) {
      res.status(400).json({ message: 'Code ou state manquant' });
      return;
    }

    // Extraire l'userId du state
    const userId = (state as string).split('-')[0];
    
    // Échanger le code contre un token
    const tokenResponse = await linkedinService.exchangeCodeForToken(code as string);
    
    // Récupérer le profil utilisateur
    const profile = await linkedinService.getUserProfile(tokenResponse.access_token);
    
    // Mettre à jour l'utilisateur avec les tokens et le profil LinkedIn
    await User.findByIdAndUpdate(userId, {
      linkedinAccessToken: tokenResponse.access_token,
      linkedinRefreshToken: tokenResponse.refresh_token,
      linkedinProfile: {
        id: profile.id,
        firstName: profile.firstName.localized['en_US'] || '',
        lastName: profile.lastName.localized['en_US'] || '',
        profilePicture: profile.profilePicture?.['displayImage~']?.elements?.[0]?.identifiers?.[0]?.identifier
      }
    });

    res.json({ 
      message: 'LinkedIn connecté avec succès',
      profile: {
        id: profile.id,
        firstName: profile.firstName.localized['en_US'] || '',
        lastName: profile.lastName.localized['en_US'] || ''
      }
    });
  } catch (error) {
    console.error('Erreur lors de la connexion LinkedIn:', error);
    res.status(500).json({ message: 'Erreur lors de la connexion LinkedIn' });
  }
};

export const disconnectLinkedIn = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await User.findByIdAndUpdate(req.user?.userId, {
      $unset: {
        linkedinAccessToken: 1,
        linkedinRefreshToken: 1,
        linkedinProfile: 1
      }
    });

    res.json({ message: 'LinkedIn déconnecté avec succès' });
  } catch (error) {
    console.error('Erreur lors de la déconnexion LinkedIn:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
