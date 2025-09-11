import { Response } from 'express';
import { validationResult } from 'express-validator';
import Post from '../models/Post';
import User from '../models/User';
import { AuthRequest } from '../middleware/auth';
import openaiService from '../services/openaiService';
import linkedinService from '../services/linkedinService';

export const generatePost = async (req: AuthRequest, res: Response): Promise<void> => {
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

    const { topic, tone, length, includeHashtags, includeEmojis, targetAudience } = req.body;

    // Générer le contenu avec OpenAI
    const content = await openaiService.generateLinkedInPost({
      topic,
      tone,
      length,
      includeHashtags,
      includeEmojis,
      targetAudience
    });

    // Sauvegarder le post en tant que brouillon
    const post = new Post({
      userId: req.user?.userId,
      content,
      topic,
      tone,
      status: 'draft'
    });

    await post.save();

    res.json({
      message: 'Post généré avec succès',
      post: {
        id: post._id,
        content: post.content,
        topic: post.topic,
        tone: post.tone,
        status: post.status,
        createdAt: (post as any).createdAt
      }
    });
  } catch (error) {
    console.error('Erreur lors de la génération du post:', error);
    res.status(500).json({ message: 'Erreur lors de la génération du post' });
  }
};

export const generateHashtags = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({
        message: 'Données invalides',
        errors: errors.array()
      });
      return;
    }

    const { topic, count } = req.body;
    const hashtags = await openaiService.generateHashtags(topic, count);

    res.json({ hashtags });
  } catch (error) {
    console.error('Erreur lors de la génération des hashtags:', error);
    res.status(500).json({ message: 'Erreur lors de la génération des hashtags' });
  }
};

export const getUserPosts = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    const status = req.query.status as string;

    const query: any = { userId: req.user?.userId };
    if (status && ['draft', 'scheduled', 'published', 'failed'].includes(status)) {
      query.status = status;
    }

    const posts = await Post.find(query)
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip((page - 1) * limit);

    const total = await Post.countDocuments(query);

    res.json({
      posts,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des posts:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

export const getPost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    
    const post = await Post.findOne({ 
      _id: id, 
      userId: req.user?.userId 
    });

    if (!post) {
      res.status(404).json({ message: 'Post non trouvé' });
      return;
    }

    res.json({ post });
  } catch (error) {
    console.error('Erreur lors de la récupération du post:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

export const updatePost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { content, topic, tone } = req.body;

    const post = await Post.findOne({ 
      _id: id, 
      userId: req.user?.userId 
    });

    if (!post) {
      res.status(404).json({ message: 'Post non trouvé' });
      return;
    }

    if (post.status === 'published') {
      res.status(400).json({ message: 'Impossible de modifier un post publié' });
      return;
    }

    // Mettre à jour le post
    post.content = content || post.content;
    post.topic = topic || post.topic;
    post.tone = tone || post.tone;

    await post.save();

    res.json({
      message: 'Post mis à jour avec succès',
      post
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du post:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

export const deletePost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const post = await Post.findOneAndDelete({ 
      _id: id, 
      userId: req.user?.userId 
    });

    if (!post) {
      res.status(404).json({ message: 'Post non trouvé' });
      return;
    }

    res.json({ message: 'Post supprimé avec succès' });
  } catch (error) {
    console.error('Erreur lors de la suppression du post:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

export const publishPost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const post = await Post.findOne({ 
      _id: id, 
      userId: req.user?.userId 
    });

    if (!post) {
      res.status(404).json({ message: 'Post non trouvé' });
      return;
    }

    if (post.status === 'published') {
      res.status(400).json({ message: 'Post déjà publié' });
      return;
    }

    // Récupérer les informations LinkedIn de l'utilisateur
    const user = await User.findById(req.user?.userId).select('+linkedinAccessToken');
    if (!user?.linkedinAccessToken || !user.linkedinProfile?.id) {
      res.status(400).json({ message: 'Compte LinkedIn non connecté' });
      return;
    }

    try {
      // Publier sur LinkedIn
      const linkedinPostId = await linkedinService.publishPost(
        user.linkedinAccessToken,
        post.content,
        user.linkedinProfile.id
      );

      // Mettre à jour le post
      post.status = 'published';
      post.publishedAt = new Date();
      post.linkedinPostId = linkedinPostId;

      await post.save();

      res.json({
        message: 'Post publié avec succès sur LinkedIn',
        post
      });
    } catch (linkedinError) {
      console.error('Erreur LinkedIn:', linkedinError);
      
      // Marquer le post comme échoué
      post.status = 'failed';
      await post.save();

      res.status(500).json({ message: 'Erreur lors de la publication sur LinkedIn' });
    }
  } catch (error) {
    console.error('Erreur lors de la publication:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

export const schedulePost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ 
        message: 'Données invalides', 
        errors: errors.array() 
      });
      return;
    }

    const { postId, scheduledAt } = req.body;

    const post = await Post.findOne({ 
      _id: postId, 
      userId: req.user?.userId 
    });

    if (!post) {
      res.status(404).json({ message: 'Post non trouvé' });
      return;
    }

    if (post.status === 'published') {
      res.status(400).json({ message: 'Post déjà publié' });
      return;
    }

    post.scheduledAt = new Date(scheduledAt);
    post.status = 'scheduled';

    await post.save();

    res.json({
      message: 'Post programmé avec succès',
      post
    });
  } catch (error) {
    console.error('Erreur lors de la programmation:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

export const getPostAnalytics = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const post = await Post.findOne({ 
      _id: id, 
      userId: req.user?.userId 
    });

    if (!post) {
      res.status(404).json({ message: 'Post non trouvé' });
      return;
    }

    if (post.status !== 'published' || !post.linkedinPostId) {
      res.status(400).json({ message: 'Post non publié ou sans ID LinkedIn' });
      return;
    }

    const user = await User.findById(req.user?.userId).select('+linkedinAccessToken');
    if (!user?.linkedinAccessToken) {
      res.status(400).json({ message: 'Token LinkedIn non disponible' });
      return;
    }

    try {
      const analytics = await linkedinService.getPostAnalytics(
        user.linkedinAccessToken,
        post.linkedinPostId
      );

      // Mettre à jour les analytics du post
      post.analytics = analytics;
      await post.save();

      res.json({
        analytics: post.analytics
      });
    } catch (linkedinError) {
      console.error('Erreur récupération analytics LinkedIn:', linkedinError);
      res.status(500).json({ message: 'Erreur lors de la récupération des analytics' });
    }
  } catch (error) {
    console.error('Erreur lors de la récupération des analytics:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
