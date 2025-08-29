import { body, ValidationChain } from 'express-validator';

export const validateRegister: ValidationChain[] = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Email valide requis'),
  
  body('password')
    .isLength({ min: 6 })
    .withMessage('Le mot de passe doit contenir au moins 6 caractères')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Le mot de passe doit contenir au moins une minuscule, une majuscule et un chiffre'),
  
  body('firstName')
    .trim()
    .isLength({ min: 2 })
    .withMessage('Le prénom doit contenir au moins 2 caractères'),
  
  body('lastName')
    .trim()
    .isLength({ min: 2 })
    .withMessage('Le nom doit contenir au moins 2 caractères')
];

export const validateLogin: ValidationChain[] = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Email valide requis'),
  
  body('password')
    .notEmpty()
    .withMessage('Mot de passe requis')
];

export const validatePostGeneration: ValidationChain[] = [
  body('topic')
    .trim()
    .isLength({ min: 3, max: 200 })
    .withMessage('Le sujet doit contenir entre 3 et 200 caractères'),
  
  body('tone')
    .isIn(['professional', 'casual', 'inspiring', 'educational', 'promotional'])
    .withMessage('Ton invalide'),
  
  body('length')
    .isIn(['short', 'medium', 'long'])
    .withMessage('Longueur invalide'),
  
  body('includeHashtags')
    .isBoolean()
    .withMessage('includeHashtags doit être un booléen'),
  
  body('includeEmojis')
    .isBoolean()
    .withMessage('includeEmojis doit être un booléen'),
  
  body('targetAudience')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('L\'audience cible ne peut pas dépasser 100 caractères')
];

export const validateSchedulePost: ValidationChain[] = [
  body('postId')
    .isMongoId()
    .withMessage('ID de post invalide'),
  
  body('scheduledAt')
    .isISO8601()
    .toDate()
    .custom((value) => {
      if (new Date(value) <= new Date()) {
        throw new Error('La date de programmation doit être dans le futur');
      }
      return true;
    })
];
