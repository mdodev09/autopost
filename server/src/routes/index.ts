import { Router } from 'express';
import authRoutes from './auth';
import postRoutes from './posts';

const router = Router();

// Routes de l'API
router.use('/auth', authRoutes);
router.use('/posts', postRoutes);

// Route de santé
router.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

export default router;
