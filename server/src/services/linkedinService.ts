import axios, { AxiosResponse } from 'axios';
import { LinkedInAuthResponse, LinkedInProfile } from '../types';

class LinkedInService {
  private readonly baseURL = 'https://api.linkedin.com/v2';
  private readonly authURL = 'https://www.linkedin.com/oauth/v2';

  // Configuration OAuth LinkedIn
  private readonly clientId = process.env.LINKEDIN_CLIENT_ID;
  private readonly clientSecret = process.env.LINKEDIN_CLIENT_SECRET;
  private readonly redirectUri = process.env.LINKEDIN_REDIRECT_URI;

  constructor() {
    if (!this.clientId || !this.clientSecret || !this.redirectUri) {
      throw new Error('Configuration LinkedIn manquante');
    }
  }

  // Générer l'URL d'autorisation LinkedIn
  getAuthorizationUrl(state: string): string {
    const scopes = ['r_liteprofile', 'r_emailaddress', 'w_member_social'];
    const params = new URLSearchParams({
      response_type: 'code',
      client_id: this.clientId!,
      redirect_uri: this.redirectUri!,
      state: state,
      scope: scopes.join(' ')
    });

    return `${this.authURL}/authorization?${params.toString()}`;
  }

  // Échanger le code d'autorisation contre un token d'accès
  async exchangeCodeForToken(code: string): Promise<LinkedInAuthResponse> {
    try {
      const response: AxiosResponse<LinkedInAuthResponse> = await axios.post(
        `${this.authURL}/accessToken`,
        {
          grant_type: 'authorization_code',
          code: code,
          redirect_uri: this.redirectUri,
          client_id: this.clientId,
          client_secret: this.clientSecret
        },
        {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
          }
        }
      );

      return response.data;
    } catch (error) {
      console.error('Erreur lors de l\'échange du code:', error);
      throw new Error('Erreur lors de l\'authentification LinkedIn');
    }
  }

  // Récupérer le profil utilisateur
  async getUserProfile(accessToken: string): Promise<LinkedInProfile> {
    try {
      const response: AxiosResponse<LinkedInProfile> = await axios.get(
        `${this.baseURL}/people/~:(id,firstName,lastName,profilePicture(displayImage~:playableStreams))`,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return response.data;
    } catch (error) {
      console.error('Erreur lors de la récupération du profil:', error);
      throw new Error('Erreur lors de la récupération du profil LinkedIn');
    }
  }

  // Publier un post sur LinkedIn
  async publishPost(accessToken: string, content: string, authorId: string): Promise<string> {
    try {
      const postData = {
        author: `urn:li:person:${authorId}`,
        lifecycleState: 'PUBLISHED',
        specificContent: {
          'com.linkedin.ugc.ShareContent': {
            shareCommentary: {
              text: content
            },
            shareMediaCategory: 'NONE'
          }
        },
        visibility: {
          'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC'
        }
      };

      const response = await axios.post(
        `${this.baseURL}/ugcPosts`,
        postData,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
            'X-Restli-Protocol-Version': '2.0.0'
          }
        }
      );

      return response.data.id;
    } catch (error) {
      console.error('Erreur lors de la publication:', error);
      throw new Error('Erreur lors de la publication sur LinkedIn');
    }
  }

  // Récupérer les analytics d'un post
  async getPostAnalytics(accessToken: string, postId: string) {
    try {
      const response = await axios.get(
        `${this.baseURL}/socialActions/${postId}`,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return {
        likes: response.data.likesSummary?.totalLikes || 0,
        comments: response.data.commentsSummary?.totalComments || 0,
        shares: response.data.sharesSummary?.totalShares || 0,
        impressions: response.data.impressionCount || 0
      };
    } catch (error) {
      console.error('Erreur lors de la récupération des analytics:', error);
      return {
        likes: 0,
        comments: 0,
        shares: 0,
        impressions: 0
      };
    }
  }

  // Rafraîchir le token d'accès
  async refreshAccessToken(refreshToken: string): Promise<LinkedInAuthResponse> {
    try {
      const response: AxiosResponse<LinkedInAuthResponse> = await axios.post(
        `${this.authURL}/accessToken`,
        {
          grant_type: 'refresh_token',
          refresh_token: refreshToken,
          client_id: this.clientId,
          client_secret: this.clientSecret
        },
        {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
          }
        }
      );

      return response.data;
    } catch (error) {
      console.error('Erreur lors du rafraîchissement du token:', error);
      throw new Error('Erreur lors du rafraîchissement du token');
    }
  }
}

export default new LinkedInService();
