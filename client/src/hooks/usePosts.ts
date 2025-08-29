import { useQuery, useMutation, useQueryClient } from 'react-query';
import { postService } from '../services/api';
import { Post, PostGenerationRequest } from '../types';
import toast from 'react-hot-toast';

// Hook pour récupérer les posts
export const usePosts = (params?: {
  page?: number;
  limit?: number;
  status?: string;
}) => {
  return useQuery(
    ['posts', params],
    () => postService.getPosts(params),
    {
      staleTime: 1000 * 60 * 5, // 5 minutes
      cacheTime: 1000 * 60 * 10, // 10 minutes
    }
  );
};

// Hook pour récupérer un post spécifique
export const usePost = (id: string) => {
  return useQuery(
    ['post', id],
    () => postService.getPost(id),
    {
      enabled: !!id,
    }
  );
};

// Hook pour générer un nouveau post
export const useGeneratePost = () => {
  const queryClient = useQueryClient();

  return useMutation(
    (request: PostGenerationRequest) => postService.generatePost(request),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(['posts']);
        toast.success('Post généré avec succès !');
      },
      onError: () => {
        toast.error('Erreur lors de la génération du post');
      },
    }
  );
};

// Hook pour mettre à jour un post
export const useUpdatePost = () => {
  const queryClient = useQueryClient();

  return useMutation(
    ({ id, data }: { id: string; data: Partial<Post> }) =>
      postService.updatePost(id, data),
    {
      onSuccess: (response, variables) => {
        queryClient.invalidateQueries(['posts']);
        queryClient.invalidateQueries(['post', variables.id]);
        toast.success('Post mis à jour avec succès !');
      },
      onError: () => {
        toast.error('Erreur lors de la mise à jour du post');
      },
    }
  );
};

// Hook pour supprimer un post
export const useDeletePost = () => {
  const queryClient = useQueryClient();

  return useMutation(
    (id: string) => postService.deletePost(id),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(['posts']);
        toast.success('Post supprimé avec succès !');
      },
      onError: () => {
        toast.error('Erreur lors de la suppression du post');
      },
    }
  );
};

// Hook pour publier un post
export const usePublishPost = () => {
  const queryClient = useQueryClient();

  return useMutation(
    (id: string) => postService.publishPost(id),
    {
      onSuccess: (response, id) => {
        queryClient.invalidateQueries(['posts']);
        queryClient.invalidateQueries(['post', id]);
        toast.success('Post publié avec succès sur LinkedIn !');
      },
      onError: () => {
        toast.error('Erreur lors de la publication sur LinkedIn');
      },
    }
  );
};

// Hook pour programmer un post
export const useSchedulePost = () => {
  const queryClient = useQueryClient();

  return useMutation(
    ({ postId, scheduledAt }: { postId: string; scheduledAt: string }) =>
      postService.schedulePost(postId, scheduledAt),
    {
      onSuccess: (response, variables) => {
        queryClient.invalidateQueries(['posts']);
        queryClient.invalidateQueries(['post', variables.postId]);
        toast.success('Post programmé avec succès !');
      },
      onError: () => {
        toast.error('Erreur lors de la programmation du post');
      },
    }
  );
};

// Hook pour récupérer les analytics d'un post
export const usePostAnalytics = (id: string) => {
  return useQuery(
    ['post-analytics', id],
    () => postService.getPostAnalytics(id),
    {
      enabled: !!id,
      refetchInterval: 1000 * 60 * 5, // Refresh toutes les 5 minutes
    }
  );
};
