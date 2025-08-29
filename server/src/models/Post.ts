import mongoose, { Schema, Document } from 'mongoose';

export interface IPost extends Document {
  userId: mongoose.Types.ObjectId;
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
}

const PostSchema: Schema = new Schema({
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  content: {
    type: String,
    required: true,
    maxlength: 3000
  },
  topic: {
    type: String,
    required: true,
    trim: true
  },
  tone: {
    type: String,
    required: true,
    enum: ['professional', 'casual', 'inspiring', 'educational', 'promotional']
  },
  scheduledAt: {
    type: Date
  },
  publishedAt: {
    type: Date
  },
  status: {
    type: String,
    enum: ['draft', 'scheduled', 'published', 'failed'],
    default: 'draft'
  },
  linkedinPostId: {
    type: String
  },
  analytics: {
    likes: { type: Number, default: 0 },
    comments: { type: Number, default: 0 },
    shares: { type: Number, default: 0 },
    impressions: { type: Number, default: 0 }
  }
}, {
  timestamps: true
});

// Index for efficient queries
PostSchema.index({ userId: 1, createdAt: -1 });
PostSchema.index({ status: 1, scheduledAt: 1 });

export default mongoose.model<IPost>('Post', PostSchema);
