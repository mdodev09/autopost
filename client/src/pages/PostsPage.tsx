import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { usePosts, useDeletePost, usePublishPost } from '../hooks/usePosts';
import LoadingSpinner from '../components/LoadingSpinner';
import { 
  FileText, 
  PlusCircle, 
  Edit, 
  Trash2, 
  Send, 
  Calendar,
  TrendingUp,
  Filter
} from 'lucide-react';

const PostsPage: React.FC = () => {
  const [currentPage, setCurrentPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<string>('');
  
  const { data: postsData, isLoading } = usePosts({
    page: currentPage,
    limit: 10,
    status: statusFilter || undefined
  });
  
  const deletePost = useDeletePost();
  const publishPost = usePublishPost();

  const handleDelete = async (id: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce post ?')) {
      await deletePost.mutateAsync(id);
    }
  };

  const handlePublish = async (id: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir publier ce post sur LinkedIn ?')) {
      await publishPost.mutateAsync(id);
    }
  };

  const statusOptions = [
    { value: '', label: 'Tous les posts' },
    { value: 'draft', label: 'Brouillons' },
    { value: 'scheduled', label: 'Programmés' },
    { value: 'published', label: 'Publiés' },
    { value: 'failed', label: 'Échecs' }
  ];

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
    <div>
      {/* En-tête */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Mes Posts</h1>
          <p className="mt-1 text-sm text-gray-600">
            Gérez tous vos posts LinkedIn
          </p>
        </div>
        <Link to="/generate" className="btn-primary btn-md">
          <PlusCircle className="h-4 w-4 mr-2" />
          Nouveau post
        </Link>
      </div>

      {/* Filtres */}
      <div className="mb-6 flex items-center space-x-4">
        <div className="flex items-center">
          <Filter className="h-5 w-5 text-gray-400 mr-2" />
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="input w-48"
          >
            {statusOptions.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>
        
        {postsData && (
          <p className="text-sm text-gray-500">
            {postsData.pagination.total} post(s) au total
          </p>
        )}
      </div>

      {/* Liste des posts */}
      <div className="card">
        {isLoading ? (
          <div className="flex justify-center py-8">
            <LoadingSpinner />
          </div>
        ) : !postsData?.posts.length ? (
          <div className="text-center py-12">
            <FileText className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">
              {statusFilter ? 'Aucun post trouvé' : 'Aucun post'}
            </h3>
            <p className="mt-1 text-sm text-gray-500">
              {statusFilter 
                ? 'Aucun post ne correspond aux filtres sélectionnés.'
                : 'Commencez par créer votre premier post LinkedIn.'
              }
            </p>
            {!statusFilter && (
              <div className="mt-6">
                <Link to="/generate" className="btn-primary btn-sm">
                  <PlusCircle className="h-4 w-4 mr-2" />
                  Créer un post
                </Link>
              </div>
            )}
          </div>
        ) : (
          <div className="divide-y divide-gray-200">
            {postsData.posts.map((post) => (
              <div key={post._id} className="p-6">
                <div className="flex items-start justify-between">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center space-x-3 mb-2">
                      <h3 className="text-lg font-medium text-gray-900 truncate">
                        {post.topic}
                      </h3>
                      {getStatusBadge(post.status)}
                    </div>
                    
                    <p className="text-gray-600 text-sm mb-3 line-clamp-3">
                      {post.content}
                    </p>
                    
                    <div className="flex items-center text-sm text-gray-500 space-x-4">
                      <span>Ton: {post.tone}</span>
                      <span>•</span>
                      <span>{new Date(post.createdAt).toLocaleDateString('fr-FR')}</span>
                      {post.publishedAt && (
                        <>
                          <span>•</span>
                          <span>Publié le {new Date(post.publishedAt).toLocaleDateString('fr-FR')}</span>
                        </>
                      )}
                      {post.scheduledAt && (
                        <>
                          <span>•</span>
                          <span>Programmé pour le {new Date(post.scheduledAt).toLocaleDateString('fr-FR')}</span>
                        </>
                      )}
                    </div>

                    {/* Analytics */}
                    {post.status === 'published' && post.analytics && (
                      <div className="mt-3 flex items-center space-x-6">
                        <div className="flex items-center text-sm text-gray-500">
                          <TrendingUp className="h-4 w-4 mr-1" />
                          {post.analytics.likes} likes
                        </div>
                        <div className="text-sm text-gray-500">
                          {post.analytics.comments} commentaires
                        </div>
                        <div className="text-sm text-gray-500">
                          {post.analytics.shares} partages
                        </div>
                      </div>
                    )}
                  </div>
                  
                  {/* Actions */}
                  <div className="flex items-center space-x-2 ml-4">
                    <Link
                      to={`/posts/${post._id}`}
                      className="btn-outline btn-sm"
                    >
                      Voir
                    </Link>
                    
                    {post.status === 'draft' && (
                      <>
                        <Link
                          to={`/posts/${post._id}`}
                          className="btn-outline btn-sm"
                        >
                          <Edit className="h-4 w-4" />
                        </Link>
                        <button
                          onClick={() => handlePublish(post._id)}
                          disabled={publishPost.isLoading}
                          className="btn-primary btn-sm"
                        >
                          <Send className="h-4 w-4" />
                        </button>
                      </>
                    )}
                    
                    {post.status === 'scheduled' && (
                      <button className="btn-outline btn-sm">
                        <Calendar className="h-4 w-4" />
                      </button>
                    )}
                    
                    {post.status !== 'published' && (
                      <button
                        onClick={() => handleDelete(post._id)}
                        disabled={deletePost.isLoading}
                        className="btn-outline btn-sm text-red-600 hover:text-red-700"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Pagination */}
      {postsData && postsData.pagination.pages > 1 && (
        <div className="mt-6 flex items-center justify-between">
          <div className="text-sm text-gray-700">
            Page {postsData.pagination.page} sur {postsData.pagination.pages}
          </div>
          <div className="flex space-x-2">
            <button
              onClick={() => setCurrentPage(currentPage - 1)}
              disabled={currentPage === 1}
              className="btn-outline btn-sm disabled:opacity-50"
            >
              Précédent
            </button>
            <button
              onClick={() => setCurrentPage(currentPage + 1)}
              disabled={currentPage === postsData.pagination.pages}
              className="btn-outline btn-sm disabled:opacity-50"
            >
              Suivant
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default PostsPage;
