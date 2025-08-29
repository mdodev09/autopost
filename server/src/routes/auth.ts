import { Router } from 'express';
import {
  register,
  login,
  getProfile,
  getLinkedInAuthUrl,
  handleLinkedInCallback,
  disconnectLinkedIn
} from '../controllers/authController';
import { authenticateToken } from '../middleware/auth';
import { validateRegister, validateLogin } from '../middleware/validation';

const router = Router();

// Routes publiques
router.post('/register', validateRegister, register);
router.post('/login', validateLogin, login);
router.get('/linkedin/callback', handleLinkedInCallback);

// Routes protégées
router.get('/profile', authenticateToken, getProfile);
router.get('/linkedin/auth', authenticateToken, getLinkedInAuthUrl);
router.delete('/linkedin/disconnect', authenticateToken, disconnectLinkedIn);

export default router;
