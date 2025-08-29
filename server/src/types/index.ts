export interface User {
  _id?: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  linkedinAccessToken?: string;
  linkedinRefreshToken?: string;
  linkedinProfile?: {
    id: string;
    firstName: string;
    lastName: string;
    profilePicture?: string;
  };
  createdAt?: Date;
  updatedAt?: Date;
}

export interface Post {
  _id?: string;
  userId: string;
  content: string;
  topic: string;
  tone: string;
  scheduledAt?: Date;
  publishedAt?: Date;
  status: 'draft' | 'scheduled' | 'published' | 'failed';
  linkedinPostId?: string;
  analytics?: {
    likes: number;
    comments: number;
    shares: number;
    impressions: number;
  };
  createdAt?: Date;
  updatedAt?: Date;
}

export interface AuthRequest extends Request {
  user?: {
    userId: string;
    email: string;
  };
}

export interface PostGenerationRequest {
  topic: string;
  tone: 'professional' | 'casual' | 'inspiring' | 'educational' | 'promotional';
  length: 'short' | 'medium' | 'long';
  includeHashtags: boolean;
  includeEmojis: boolean;
  targetAudience?: string;
}

export interface LinkedInAuthResponse {
  access_token: string;
  expires_in: number;
  refresh_token?: string;
  refresh_token_expires_in?: number;
}

export interface LinkedInProfile {
  id: string;
  firstName: {
    localized: {
      [key: string]: string;
    };
  };
  lastName: {
    localized: {
      [key: string]: string;
    };
  };
  profilePicture?: {
    'displayImage~': {
      elements: Array<{
        identifiers: Array<{
          identifier: string;
        }>;
      }>;
    };
  };
}
