import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { useGeneratePost, useGenerateHashtags } from '../hooks/usePosts';
import { PostGenerationRequest } from '../types';
import LoadingSpinner from '../components/LoadingSpinner';
import { Sparkles, FileText, Target, MessageSquare, Hash } from 'lucide-react';

const PostGeneratorPage: React.FC = () => {
  const navigate = useNavigate();
  const generatePost = useGeneratePost();
  const generateHashtags = useGenerateHashtags();
  const [generatedPost, setGeneratedPost] = useState<string>('');
  const [hashtags, setHashtags] = useState<string[]>([]);
  
  const {
    register,
    handleSubmit,
    watch,
    formState: { errors }
  } = useForm<PostGenerationRequest>({
    defaultValues: {
      tone: 'professional',
      length: 'medium',
      includeHashtags: true,
      includeEmojis: false
    }
  });

  const watchTone = watch('tone');
  const watchLength = watch('length');

  const onSubmit = async (data: PostGenerationRequest) => {
    try {
      const result = await generatePost.mutateAsync(data);
      setGeneratedPost(result.post.content);
      setHashtags([]);
    } catch (error) {
      console.error('Erreur lors de la génération:', error);
    }
  };

  const toneOptions = [
    { value: 'professional', label: 'Professionnel', description: 'Ton formel et sérieux' },
    { value: 'casual', label: 'Décontracté', description: 'Ton amical et accessible' },
    { value: 'inspiring', label: 'Inspirant', description: 'Ton motivationnel' },
    { value: 'educational', label: 'Éducatif', description: 'Ton informatif' },
    { value: 'promotional', label: 'Promotionnel', description: 'Ton commercial' }
  ];

  const lengthOptions = [
    { value: 'short', label: 'Court', description: '100-200 mots' },
    { value: 'medium', label: 'Moyen', description: '200-400 mots' },
    { value: 'long', label: 'Long', description: '400-600 mots' }
  ];

  return (
    <div className="max-w-4xl mx-auto">
      {/* En-tête */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900 flex items-center">
          <Sparkles className="h-7 w-7 text-primary-600 mr-3" />
          Générateur de posts LinkedIn
        </h1>
        <p className="mt-1 text-sm text-gray-600">
          Créez des posts engageants avec l'intelligence artificielle
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Formulaire de génération */}
        <div className="card">
          <div className="card-header">
            <h3 className="text-lg font-medium text-gray-900 flex items-center">
              <Target className="h-5 w-5 text-primary-600 mr-2" />
              Paramètres du post
            </h3>
          </div>
          <div className="card-content">
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
              {/* Sujet */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Sujet du post *
                </label>
                <textarea
                  {...register('topic', {
                    required: 'Le sujet est requis',
                    minLength: { value: 3, message: 'Le sujet doit contenir au moins 3 caractères' },
                    maxLength: { value: 200, message: 'Le sujet ne peut pas dépasser 200 caractères' }
                  })}
                  className="textarea"
                  rows={3}
                  placeholder="De quoi voulez-vous parler ? (ex: L'importance de la formation continue en technologie)"
                />
                {errors.topic && (
                  <p className="mt-1 text-sm text-red-600">{errors.topic.message}</p>
                )}
              </div>

              {/* Ton */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-3">
                  Ton du post
                </label>
                <div className="grid grid-cols-1 gap-2">
                  {toneOptions.map((option) => (
                    <label key={option.value} className="relative flex cursor-pointer">
                      <input
                        {...register('tone')}
                        type="radio"
                        value={option.value}
                        className="sr-only"
                      />
                      <div className={`flex-1 p-3 rounded-md border-2 transition-colors ${
                        watchTone === option.value
                          ? 'border-primary-500 bg-primary-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}>
                        <div className="font-medium text-sm text-gray-900">
                          {option.label}
                        </div>
                        <div className="text-sm text-gray-500">
                          {option.description}
                        </div>
                      </div>
                    </label>
                  ))}
                </div>
              </div>

              {/* Longueur */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-3">
                  Longueur du post
                </label>
                <div className="grid grid-cols-3 gap-2">
                  {lengthOptions.map((option) => (
                    <label key={option.value} className="relative flex cursor-pointer">
                      <input
                        {...register('length')}
                        type="radio"
                        value={option.value}
                        className="sr-only"
                      />
                      <div className={`flex-1 p-3 rounded-md border-2 text-center transition-colors ${
                        watchLength === option.value
                          ? 'border-primary-500 bg-primary-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}>
                        <div className="font-medium text-sm text-gray-900">
                          {option.label}
                        </div>
                        <div className="text-xs text-gray-500">
                          {option.description}
                        </div>
                      </div>
                    </label>
                  ))}
                </div>
              </div>

              {/* Audience cible */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Audience cible (optionnel)
                </label>
                <input
                  {...register('targetAudience', {
                    maxLength: { value: 100, message: 'L\'audience cible ne peut pas dépasser 100 caractères' }
                  })}
                  type="text"
                  className="input"
                  placeholder="ex: Développeurs web, Entrepreneurs, RH..."
                />
                {errors.targetAudience && (
                  <p className="mt-1 text-sm text-red-600">{errors.targetAudience.message}</p>
                )}
              </div>

              {/* Options */}
              <div className="space-y-3">
                <label className="flex items-center">
                  <input
                    {...register('includeHashtags')}
                    type="checkbox"
                    className="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                  />
                  <span className="ml-2 text-sm text-gray-700">
                    Inclure des hashtags
                  </span>
                </label>
                
                <label className="flex items-center">
                  <input
                    {...register('includeEmojis')}
                    type="checkbox"
                    className="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                  />
                  <span className="ml-2 text-sm text-gray-700">
                    Inclure des emojis
                  </span>
                </label>
              </div>

              {/* Bouton de génération */}
              <button
                type="submit"
                disabled={generatePost.isLoading}
                className="btn-primary w-full btn-md"
              >
                {generatePost.isLoading ? (
                  <>
                    <LoadingSpinner size="sm" className="mr-2" />
                    Génération en cours...
                  </>
                ) : (
                  <>
                    <Sparkles className="h-4 w-4 mr-2" />
                    Générer le post
                  </>
                )}
              </button>
            </form>
          </div>
        </div>

        {/* Aperçu du post généré */}
        <div className="card">
          <div className="card-header">
            <h3 className="text-lg font-medium text-gray-900 flex items-center">
              <MessageSquare className="h-5 w-5 text-primary-600 mr-2" />
              Aperçu du post
            </h3>
          </div>
          <div className="card-content">
            {generatePost.isLoading ? (
              <div className="flex items-center justify-center py-12">
                <div className="text-center">
                  <LoadingSpinner size="lg" className="mx-auto mb-4" />
                  <p className="text-sm text-gray-500">
                    Génération de votre post en cours...
                  </p>
                </div>
              </div>
            ) : generatedPost ? (
              <div>
                <div className="bg-gray-50 rounded-lg p-4 mb-4">
                  <div className="whitespace-pre-wrap text-sm text-gray-900">
                    {generatedPost}
                  </div>
                </div>
                {hashtags.length > 0 && (
                  <div className="mb-4 flex flex-wrap gap-2">
                    {hashtags.map((tag) => (
                      <span
                        key={tag}
                        className="bg-primary-100 text-primary-800 px-2 py-1 rounded text-sm"
                      >
                        #{tag}
                      </span>
                    ))}
                  </div>
                )}
                <div className="flex space-x-3">
                  <button
                    onClick={async () => {
                      try {
                        const result = await generateHashtags.mutateAsync({
                          topic: watch('topic'),
                          count: 5,
                        });
                        setHashtags(result.hashtags);
                      } catch (err) {
                        // Erreur déjà gérée par le hook
                      }
                    }}
                    disabled={generateHashtags.isLoading}
                    className="btn-outline btn-sm"
                  >
                    {generateHashtags.isLoading ? (
                      <>
                        <LoadingSpinner size="sm" className="mr-2" />
                        Génération...
                      </>
                    ) : (
                      <>
                        <Hash className="h-4 w-4 mr-2" />
                        Générer hashtags
                      </>
                    )}
                  </button>
                  <button
                    onClick={() => navigate('/posts')}
                    className="btn-primary btn-sm"
                  >
                    <FileText className="h-4 w-4 mr-2" />
                    Voir dans mes posts
                  </button>
                  <button
                    onClick={() => {
                      setGeneratedPost('');
                      setHashtags([]);
                    }}
                    className="btn-outline btn-sm"
                  >
                    Nouveau post
                  </button>
                </div>
              </div>
            ) : (
              <div className="text-center py-12">
                <MessageSquare className="mx-auto h-12 w-12 text-gray-400 mb-4" />
                <h3 className="text-sm font-medium text-gray-900">
                  Aucun post généré
                </h3>
                <p className="mt-1 text-sm text-gray-500">
                  Remplissez le formulaire et cliquez sur "Générer" pour créer votre post.
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default PostGeneratorPage;
