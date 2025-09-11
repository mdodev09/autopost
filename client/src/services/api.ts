import axios, { AxiosResponse } from 'axios';
import toast from 'react-hot-toast';
import {
  User,
  Post,
  PostGenerationRequest,
  AuthResponse,
  PostsResponse,
  LinkedInAuthResponse
} from '../types';

// Configuration d'axios
const api = axios.create({
  baseURL: '/api',
  timeout: 30000,
});

// Intercepteur pour ajouter le token d'autorisation
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Intercepteur pour gérer les erreurs globalement
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('authToken');
      window.location.href = '/login';
    }
    
    const message = error.response?.data?.message || 'Une erreur est survenue';
    toast.error(message);
    
    return Promise.reject(error);
  }
);

// Services d'authentification
export const authService = {
  async register(userData: {
    email: string;
    password: string;
    firstName: string;
    lastName: string;
  }): Promise<AuthResponse> {
    const response: AxiosResponse<AuthResponse> = await api.post('/auth/register', userData);
    return response.data;
  },

  async login(credentials: { email: string; password: string }): Promise<AuthResponse> {
    const response: AxiosResponse<AuthResponse> = await api.post('/auth/login', credentials);
    return response.data;
  },

  async getProfile(): Promise<{ user: User }> {
    const response = await api.get('/auth/profile');
    return response.data;
  },

  async getLinkedInAuthUrl(): Promise<LinkedInAuthResponse> {
    const response = await api.get('/auth/linkedin/auth');
    return response.data;
  },

  async disconnectLinkedIn(): Promise<{ message: string }> {
    const response = await api.delete('/auth/linkedin/disconnect');
    return response.data;
  }
};

// Services pour les posts
export const postService = {
  async generatePost(request: PostGenerationRequest): Promise<{ post: Post }> {
    const response = await api.post('/posts/generate', request);
    return response.data;
  },

  async getPosts(params?: {
    page?: number;
    limit?: number;
    status?: string;
  }): Promise<PostsResponse> {
    const response = await api.get('/posts', { params });
    return response.data;
  },

  async getPost(id: string): Promise<{ post: Post }> {
    const response = await api.get(`/posts/${id}`);
    return response.data;
  },

  async updatePost(id: string, data: Partial<Post>): Promise<{ post: Post }> {
    const response = await api.put(`/posts/${id}`, data);
    return response.data;
  },

  async deletePost(id: string): Promise<{ message: string }> {
    const response = await api.delete(`/posts/${id}`);
    return response.data;
  },

  async publishPost(id: string): Promise<{ post: Post }> {
    const response = await api.post(`/posts/${id}/publish`);
    return response.data;
  },

  async schedulePost(postId: string, scheduledAt: string): Promise<{ post: Post }> {
    const response = await api.post('/posts/schedule', { postId, scheduledAt });
    return response.data;
  },

  async getPostAnalytics(id: string): Promise<{ analytics: Post['analytics'] }> {
    const response = await api.get(`/posts/${id}/analytics`);
    return response.data;
  },

  async generateHashtags(topic: string, count = 5): Promise<{ hashtags: string[] }> {
    const response = await api.post('/posts/hashtags', { topic, count });
    return response.data;
  }
};

// Utilitaire pour gérer le token d'authentification
export const tokenService = {
  setToken(token: string): void {
    localStorage.setItem('authToken', token);
  },

  getToken(): string | null {
    return localStorage.getItem('authToken');
  },

  removeToken(): void {
    localStorage.removeItem('authToken');
  },

  isAuthenticated(): boolean {
    return !!this.getToken();
  }
};

export default api;
