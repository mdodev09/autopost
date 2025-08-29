export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  linkedinConnected: boolean;
  linkedinProfile?: {
    id: string;
    firstName: string;
    lastName: string;
    profilePicture?: string;
  };
}

export interface Post {
  _id: string;
  userId: string;
  content: string;
  topic: string;
  tone: 'professional' | 'casual' | 'inspiring' | 'educational' | 'promotional';
  scheduledAt?: string;
  publishedAt?: string;
  status: 'draft' | 'scheduled' | 'published' | 'failed';
  linkedinPostId?: string;
  analytics?: {
    likes: number;
    comments: number;
    shares: number;
    impressions: number;
  };
  createdAt: string;
  updatedAt: string;
}

export interface PostGenerationRequest {
  topic: string;
  tone: 'professional' | 'casual' | 'inspiring' | 'educational' | 'promotional';
  length: 'short' | 'medium' | 'long';
  includeHashtags: boolean;
  includeEmojis: boolean;
  targetAudience?: string;
}

export interface AuthResponse {
  message: string;
  token: string;
  user: User;
}

export interface ApiResponse<T = any> {
  message?: string;
  data?: T;
  error?: string;
}

export interface PostsResponse {
  posts: Post[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

export interface LinkedInAuthResponse {
  authUrl: string;
  state: string;
}
