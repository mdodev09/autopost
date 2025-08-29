import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { usePost, useUpdatePost, useDeletePost, usePublishPost } from '../hooks/usePosts';
import LoadingSpinner from '../components/LoadingSpinner';
import { ArrowLeft, Edit, Trash2, Send, Calendar, TrendingUp } from 'lucide-react';

const PostDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  
  const { data: postData, isLoading } = usePost(id!);
  const updatePost = useUpdatePost();
  const deletePost = useDeletePost();
  const publishPost = usePublishPost();

  if (isLoading) {
    return (
      <div className="flex justify-center py-12">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  if (!postData?.post) {
    return (
      <div className="text-center py-12">
        <h3 className="text-lg font-medium text-gray-900">Post non trouvé</h3>
        <p className="mt-1 text-sm text-gray-500">
          Ce post n'existe pas ou a été supprimé.
        </p>
        <button
          onClick={() => navigate('/posts')}
          className="mt-4 btn-primary btn-sm"
        >
          Retour aux posts
        </button>
      </div>
    );
  }

  const post = postData.post;

  const handleDelete = async () => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce post ?')) {
      await deletePost.mutateAsync(post._id);
      navigate('/posts');
    }
  };

  const handlePublish = async () => {
    if (window.confirm('Êtes-vous sûr de vouloir publier ce post sur LinkedIn ?')) {
      await publishPost.mutateAsync(post._id);
    }
  };

  const getStatusBadge = (status: string) => {
    const badges = {
      draft: 'bg-gray-100 text-gray-800',
      scheduled: 'bg-yellow-100 text-yellow-800',
      published: 'bg-green-100 text-green-800',
      failed: 'bg-red-100 text-red-800'
    };
    
    const labels = {
      draft: 'Brouillon',
      scheduled: 'Programmé',
      published: 'Publié',
      failed: 'Échec'
    };

    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${badges[status as keyof typeof badges]}`}>
        {labels[status as keyof typeof labels]}
      </span>
    );
  };

  return (
    <div className="max-w-4xl mx-auto">
      {/* Navigation */}
      <div className="mb-6">
        <button
          onClick={() => navigate('/posts')}
          className="flex items-center text-sm text-gray-500 hover:text-gray-700"
        >
          <ArrowLeft className="h-4 w-4 mr-1" />
          Retour aux posts
        </button>
      </div>

      {/* En-tête */}
      <div className="flex items-start justify-between mb-6">
        <div>
          <div className="flex items-center space-x-3 mb-2">
            <h1 className="text-2xl font-bold text-gray-900">{post.topic}</h1>
            {getStatusBadge(post.status)}
          </div>
          <div className="flex items-center text-sm text-gray-500 space-x-4">
            <span>Ton: {post.tone}</span>
            <span>•</span>
            <span>Créé le {new Date(post.createdAt).toLocaleDateString('fr-FR')}</span>
            {post.publishedAt && (
              <>
                <span>•</span>
                <span>Publié le {new Date(post.publishedAt).toLocaleDateString('fr-FR')}</span>
              </>
            )}
          </div>
        </div>
        
        {/* Actions */}
        <div className="flex items-center space-x-2">
          {post.status === 'draft' && (
            <>
              <button className="btn-outline btn-sm">
                <Edit className="h-4 w-4 mr-2" />
                Modifier
              </button>
              <button
                onClick={handlePublish}
                disabled={publishPost.isLoading}
                className="btn-primary btn-sm"
              >
                <Send className="h-4 w-4 mr-2" />
                Publier
              </button>
            </>
          )}
          
          {post.status === 'scheduled' && (
            <button className="btn-outline btn-sm">
              <Calendar className="h-4 w-4 mr-2" />
              Reprogrammer
            </button>
          )}
          
          {post.status !== 'published' && (
            <button
              onClick={handleDelete}
              disabled={deletePost.isLoading}
              className="btn-outline btn-sm text-red-600 hover:text-red-700"
            >
              <Trash2 className="h-4 w-4 mr-2" />
              Supprimer
            </button>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Contenu du post */}
        <div className="lg:col-span-2">
          <div className="card">
            <div className="card-header">
              <h3 className="text-lg font-medium text-gray-900">Contenu du post</h3>
            </div>
            <div className="card-content">
              <div className="bg-gray-50 rounded-lg p-4">
                <div className="whitespace-pre-wrap text-gray-900">
                  {post.content}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Sidebar avec informations et analytics */}
        <div className="space-y-6">
          {/* Informations */}
          <div className="card">
            <div className="card-header">
              <h3 className="text-lg font-medium text-gray-900">Informations</h3>
            </div>
            <div className="card-content">
              <dl className="space-y-3">
                <div>
                  <dt className="text-sm font-medium text-gray-500">Statut</dt>
                  <dd className="mt-1">{getStatusBadge(post.status)}</dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-gray-500">Ton</dt>
                  <dd className="mt-1 text-sm text-gray-900 capitalize">{post.tone}</dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-gray-500">Créé le</dt>
                  <dd className="mt-1 text-sm text-gray-900">
                    {new Date(post.createdAt).toLocaleDateString('fr-FR', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </dd>
                </div>
                {post.publishedAt && (
                  <div>
                    <dt className="text-sm font-medium text-gray-500">Publié le</dt>
                    <dd className="mt-1 text-sm text-gray-900">
                      {new Date(post.publishedAt).toLocaleDateString('fr-FR', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </dd>
                  </div>
                )}
                {post.scheduledAt && (
                  <div>
                    <dt className="text-sm font-medium text-gray-500">Programmé pour</dt>
                    <dd className="mt-1 text-sm text-gray-900">
                      {new Date(post.scheduledAt).toLocaleDateString('fr-FR', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </dd>
                  </div>
                )}
              </dl>
            </div>
          </div>

          {/* Analytics */}
          {post.status === 'published' && post.analytics && (
            <div className="card">
              <div className="card-header">
                <h3 className="text-lg font-medium text-gray-900 flex items-center">
                  <TrendingUp className="h-5 w-5 text-primary-600 mr-2" />
                  Analytics
                </h3>
              </div>
              <div className="card-content">
                <dl className="space-y-3">
                  <div className="flex justify-between">
                    <dt className="text-sm font-medium text-gray-500">Likes</dt>
                    <dd className="text-sm font-medium text-gray-900">{post.analytics.likes}</dd>
                  </div>
                  <div className="flex justify-between">
                    <dt className="text-sm font-medium text-gray-500">Commentaires</dt>
                    <dd className="text-sm font-medium text-gray-900">{post.analytics.comments}</dd>
                  </div>
                  <div className="flex justify-between">
                    <dt className="text-sm font-medium text-gray-500">Partages</dt>
                    <dd className="text-sm font-medium text-gray-900">{post.analytics.shares}</dd>
                  </div>
                  <div className="flex justify-between">
                    <dt className="text-sm font-medium text-gray-500">Impressions</dt>
                    <dd className="text-sm font-medium text-gray-900">{post.analytics.impressions}</dd>
                  </div>
                </dl>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default PostDetailPage;
