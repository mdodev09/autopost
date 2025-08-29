import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { usePosts } from '../hooks/usePosts';
import { 
  PlusCircle, 
  FileText, 
  TrendingUp, 
  Calendar,
  Linkedin,
  AlertCircle
} from 'lucide-react';
import LoadingSpinner from '../components/LoadingSpinner';

const DashboardPage: React.FC = () => {
  const { user } = useAuth();
  const { data: postsData, isLoading } = usePosts({ limit: 5 });

  const stats = [
    {
      name: 'Posts générés',
      value: postsData?.pagination.total || 0,
      icon: FileText,
      color: 'bg-blue-500'
    },
    {
      name: 'Posts publiés',
      value: postsData?.posts.filter(p => p.status === 'published').length || 0,
      icon: TrendingUp,
      color: 'bg-green-500'
    },
    {
      name: 'Posts programmés',
      value: postsData?.posts.filter(p => p.status === 'scheduled').length || 0,
      icon: Calendar,
      color: 'bg-yellow-500'
    },
    {
      name: 'Brouillons',
      value: postsData?.posts.filter(p => p.status === 'draft').length || 0,
      icon: FileText,
      color: 'bg-gray-500'
    }
  ];

  return (
    <div>
      {/* En-tête */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">
          Bienvenue, {user?.firstName} !
        </h1>
        <p className="mt-1 text-sm text-gray-600">
          Gérez vos posts LinkedIn et suivez vos performances
        </p>
      </div>

      {/* Alerte LinkedIn */}
      {!user?.linkedinConnected && (
        <div className="mb-6 bg-yellow-50 border border-yellow-200 rounded-md p-4">
          <div className="flex">
            <AlertCircle className="h-5 w-5 text-yellow-400 mt-0.5" />
            <div className="ml-3">
              <h3 className="text-sm font-medium text-yellow-800">
                Connectez votre compte LinkedIn
              </h3>
              <div className="mt-2 text-sm text-yellow-700">
                <p>
                  Pour publier automatiquement vos posts, vous devez connecter votre compte LinkedIn.
                </p>
              </div>
              <div className="mt-4">
                <Link
                  to="/profile"
                  className="text-sm bg-yellow-100 text-yellow-800 rounded-md px-3 py-2 hover:bg-yellow-200 transition-colors inline-flex items-center"
                >
                  <Linkedin className="h-4 w-4 mr-2" />
                  Connecter LinkedIn
                </Link>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Statistiques */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4 mb-8">
        {stats.map((stat) => (
          <div key={stat.name} className="card">
            <div className="card-content">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className={`p-3 rounded-md ${stat.color}`}>
                    <stat.icon className="h-6 w-6 text-white" />
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      {stat.name}
                    </dt>
                    <dd className="text-lg font-medium text-gray-900">
                      {stat.value}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Actions rapides */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 mb-8">
        <Link
          to="/generate"
          className="card hover:shadow-md transition-shadow cursor-pointer group"
        >
          <div className="card-content">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <PlusCircle className="h-8 w-8 text-primary-600 group-hover:text-primary-500" />
              </div>
              <div className="ml-4">
                <h3 className="text-lg font-medium text-gray-900">
                  Créer un nouveau post
                </h3>
                <p className="text-sm text-gray-500">
                  Générez un post avec l'IA
                </p>
              </div>
            </div>
          </div>
        </Link>

        <Link
          to="/posts"
          className="card hover:shadow-md transition-shadow cursor-pointer group"
        >
          <div className="card-content">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <FileText className="h-8 w-8 text-green-600 group-hover:text-green-500" />
              </div>
              <div className="ml-4">
                <h3 className="text-lg font-medium text-gray-900">
                  Gérer mes posts
                </h3>
                <p className="text-sm text-gray-500">
                  Voir et modifier vos posts
                </p>
              </div>
            </div>
          </div>
        </Link>

        <Link
          to="/profile"
          className="card hover:shadow-md transition-shadow cursor-pointer group"
        >
          <div className="card-content">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Linkedin className="h-8 w-8 text-linkedin-500 group-hover:text-linkedin-600" />
              </div>
              <div className="ml-4">
                <h3 className="text-lg font-medium text-gray-900">
                  Profil LinkedIn
                </h3>
                <p className="text-sm text-gray-500">
                  {user?.linkedinConnected ? 'Gérer la connexion' : 'Connecter le compte'}
                </p>
              </div>
            </div>
          </div>
        </Link>
      </div>

      {/* Posts récents */}
      <div className="card">
        <div className="card-header">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-medium text-gray-900">
              Posts récents
            </h3>
            <Link
              to="/posts"
              className="text-sm text-primary-600 hover:text-primary-500"
            >
              Voir tous
            </Link>
          </div>
        </div>
        <div className="card-content">
          {isLoading ? (
            <div className="flex justify-center py-4">
              <LoadingSpinner />
            </div>
          ) : postsData?.posts.length === 0 ? (
            <div className="text-center py-6">
              <FileText className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">
                Aucun post
              </h3>
              <p className="mt-1 text-sm text-gray-500">
                Commencez par créer votre premier post LinkedIn.
              </p>
              <div className="mt-6">
                <Link
                  to="/generate"
                  className="btn-primary btn-sm"
                >
                  <PlusCircle className="h-4 w-4 mr-2" />
                  Créer un post
                </Link>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              {postsData?.posts.map((post) => (
                <div key={post._id} className="border-l-4 border-primary-200 pl-4">
                  <div className="flex items-center justify-between">
                    <div className="flex-1">
                      <h4 className="text-sm font-medium text-gray-900">
                        {post.topic}
                      </h4>
                      <p className="text-sm text-gray-500 mt-1 line-clamp-2">
                        {post.content.substring(0, 100)}...
                      </p>
                      <div className="flex items-center mt-2 space-x-4">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          post.status === 'published' ? 'bg-green-100 text-green-800' :
                          post.status === 'scheduled' ? 'bg-yellow-100 text-yellow-800' :
                          post.status === 'draft' ? 'bg-gray-100 text-gray-800' :
                          'bg-red-100 text-red-800'
                        }`}>
                          {post.status === 'published' ? 'Publié' :
                           post.status === 'scheduled' ? 'Programmé' :
                           post.status === 'draft' ? 'Brouillon' : 'Échec'}
                        </span>
                        <span className="text-xs text-gray-500">
                          {new Date(post.createdAt).toLocaleDateString('fr-FR')}
                        </span>
                      </div>
                    </div>
                    <Link
                      to={`/posts/${post._id}`}
                      className="btn-outline btn-sm ml-4"
                    >
                      Voir
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;
