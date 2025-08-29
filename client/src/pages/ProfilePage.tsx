import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { authService } from '../services/api';
import LoadingSpinner from '../components/LoadingSpinner';
import { Linkedin, User, Mail, CheckCircle, AlertCircle } from 'lucide-react';
import toast from 'react-hot-toast';

const ProfilePage: React.FC = () => {
  const { user, refreshUser } = useAuth();
  const [linking, setLinking] = useState(false);
  const [unlinking, setUnlinking] = useState(false);

  const handleLinkedInConnect = async () => {
    setLinking(true);
    try {
      const response = await authService.getLinkedInAuthUrl();
      window.location.href = response.authUrl;
    } catch (error) {
      console.error('Erreur lors de la connexion LinkedIn:', error);
      toast.error('Erreur lors de la connexion LinkedIn');
    } finally {
      setLinking(false);
    }
  };

  const handleLinkedInDisconnect = async () => {
    if (!window.confirm('Êtes-vous sûr de vouloir déconnecter votre compte LinkedIn ?')) {
      return;
    }

    setUnlinking(true);
    try {
      await authService.disconnectLinkedIn();
      await refreshUser();
      toast.success('Compte LinkedIn déconnecté avec succès');
    } catch (error) {
      console.error('Erreur lors de la déconnexion:', error);
      toast.error('Erreur lors de la déconnexion LinkedIn');
    } finally {
      setUnlinking(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto">
      {/* En-tête */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Profil</h1>
        <p className="mt-1 text-sm text-gray-600">
          Gérez vos informations personnelles et vos connexions
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Informations personnelles */}
        <div className="card">
          <div className="card-header">
            <h3 className="text-lg font-medium text-gray-900 flex items-center">
              <User className="h-5 w-5 text-primary-600 mr-2" />
              Informations personnelles
            </h3>
          </div>
          <div className="card-content">
            <dl className="space-y-4">
              <div>
                <dt className="text-sm font-medium text-gray-500">Nom complet</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  {user?.firstName} {user?.lastName}
                </dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Email</dt>
                <dd className="mt-1 text-sm text-gray-900 flex items-center">
                  <Mail className="h-4 w-4 text-gray-400 mr-2" />
                  {user?.email}
                </dd>
              </div>
            </dl>
          </div>
        </div>

        {/* Connexion LinkedIn */}
        <div className="card">
          <div className="card-header">
            <h3 className="text-lg font-medium text-gray-900 flex items-center">
              <Linkedin className="h-5 w-5 text-linkedin-500 mr-2" />
              Connexion LinkedIn
            </h3>
          </div>
          <div className="card-content">
            {user?.linkedinConnected ? (
              <div>
                <div className="flex items-center mb-4">
                  <CheckCircle className="h-5 w-5 text-green-500 mr-2" />
                  <span className="text-sm font-medium text-green-700">
                    Compte LinkedIn connecté
                  </span>
                </div>
                
                {user.linkedinProfile && (
                  <div className="bg-green-50 rounded-lg p-4 mb-4">
                    <div className="flex items-center">
                      {user.linkedinProfile.profilePicture && (
                        <img
                          src={user.linkedinProfile.profilePicture}
                          alt="Profile"
                          className="h-12 w-12 rounded-full mr-3"
                        />
                      )}
                      <div>
                        <p className="font-medium text-green-900">
                          {user.linkedinProfile.firstName} {user.linkedinProfile.lastName}
                        </p>
                        <p className="text-sm text-green-700">
                          Profil LinkedIn connecté
                        </p>
                      </div>
                    </div>
                  </div>
                )}

                <div className="bg-blue-50 border border-blue-200 rounded-md p-4 mb-4">
                  <div className="flex">
                    <CheckCircle className="h-5 w-5 text-blue-400 mt-0.5" />
                    <div className="ml-3">
                      <h4 className="text-sm font-medium text-blue-800">
                        Fonctionnalités disponibles
                      </h4>
                      <ul className="mt-2 text-sm text-blue-700 list-disc list-inside space-y-1">
                        <li>Publication automatique de posts</li>
                        <li>Programmation de posts</li>
                        <li>Suivi des performances</li>
                      </ul>
                    </div>
                  </div>
                </div>

                <button
                  onClick={handleLinkedInDisconnect}
                  disabled={unlinking}
                  className="btn-outline w-full btn-md text-red-600 hover:text-red-700 border-red-300 hover:border-red-400"
                >
                  {unlinking ? (
                    <>
                      <LoadingSpinner size="sm" className="mr-2" />
                      Déconnexion...
                    </>
                  ) : (
                    'Déconnecter LinkedIn'
                  )}
                </button>
              </div>
            ) : (
              <div>
                <div className="flex items-center mb-4">
                  <AlertCircle className="h-5 w-5 text-yellow-500 mr-2" />
                  <span className="text-sm font-medium text-yellow-700">
                    Compte LinkedIn non connecté
                  </span>
                </div>

                <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4 mb-4">
                  <div className="flex">
                    <AlertCircle className="h-5 w-5 text-yellow-400 mt-0.5" />
                    <div className="ml-3">
                      <h4 className="text-sm font-medium text-yellow-800">
                        Pourquoi connecter LinkedIn ?
                      </h4>
                      <ul className="mt-2 text-sm text-yellow-700 list-disc list-inside space-y-1">
                        <li>Publier automatiquement vos posts générés</li>
                        <li>Programmer des publications à l'avance</li>
                        <li>Suivre les performances de vos posts</li>
                        <li>Synchroniser avec votre profil professionnel</li>
                      </ul>
                    </div>
                  </div>
                </div>

                <button
                  onClick={handleLinkedInConnect}
                  disabled={linking}
                  className="btn-linkedin w-full btn-md"
                >
                  {linking ? (
                    <>
                      <LoadingSpinner size="sm" className="mr-2" />
                      Connexion...
                    </>
                  ) : (
                    <>
                      <Linkedin className="h-4 w-4 mr-2" />
                      Connecter LinkedIn
                    </>
                  )}
                </button>

                <p className="text-xs text-gray-500 mt-3">
                  En connectant votre compte LinkedIn, vous autorisez AutoPost à publier 
                  des posts en votre nom. Vous pouvez révoquer cette autorisation à tout moment.
                </p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Informations supplémentaires */}
      <div className="mt-6 card">
        <div className="card-header">
          <h3 className="text-lg font-medium text-gray-900">Sécurité et confidentialité</h3>
        </div>
        <div className="card-content">
          <div className="space-y-4">
            <div>
              <h4 className="text-sm font-medium text-gray-900">Protection des données</h4>
              <p className="text-sm text-gray-600 mt-1">
                Vos données sont chiffrées et stockées de manière sécurisée. 
                Nous ne partageons jamais vos informations avec des tiers.
              </p>
            </div>
            <div>
              <h4 className="text-sm font-medium text-gray-900">Tokens d'accès</h4>
              <p className="text-sm text-gray-600 mt-1">
                Les tokens LinkedIn sont stockés de manière sécurisée et utilisés 
                uniquement pour publier vos posts autorisés.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProfilePage;
