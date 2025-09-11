import { Router } from 'express';
import {
  generatePost,
  generateHashtags,
  getUserPosts,
  getPost,
  updatePost,
  deletePost,
  publishPost,
  schedulePost,
  getPostAnalytics
} from '../controllers/postController';
import { authenticateToken } from '../middleware/auth';
import { validatePostGeneration, validateHashtagGeneration, validateSchedulePost } from '../middleware/validation';

const router = Router();

// Toutes les routes nécessitent une authentification
router.use(authenticateToken);

// Routes pour les posts
router.post('/generate', validatePostGeneration, generatePost);
router.post('/hashtags', validateHashtagGeneration, generateHashtags);
router.get('/', getUserPosts);
router.get('/:id', getPost);
router.put('/:id', updatePost);
router.delete('/:id', deletePost);
router.post('/:id/publish', publishPost);
router.post('/schedule', validateSchedulePost, schedulePost);
router.get('/:id/analytics', getPostAnalytics);

export default router;
