import OpenAI from 'openai';
import { PostGenerationRequest } from '../types';

class OpenAIService {
  private openai: OpenAI;

  constructor() {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY non configuré');
    }

    this.openai = new OpenAI({
      apiKey: apiKey,
    });
  }

  async generateLinkedInPost(request: PostGenerationRequest): Promise<string> {
    try {
      const prompt = this.buildPrompt(request);
      
      const completion = await this.openai.chat.completions.create({
        model: 'gpt-4',
        messages: [
          {
            role: 'system',
            content: `Tu es un expert en marketing digital et en création de contenu LinkedIn. 
                     Tu crées des posts engageants, professionnels et adaptés à l'audience LinkedIn.
                     Respecte toujours la limite de 3000 caractères de LinkedIn.`
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 1000,
        temperature: 0.7,
      });

      const generatedContent = completion.choices[0]?.message?.content;
      
      if (!generatedContent) {
        throw new Error('Aucun contenu généré par OpenAI');
      }

      return generatedContent.trim();
    } catch (error) {
      console.error('Erreur lors de la génération du post:', error);
      throw new Error('Erreur lors de la génération du contenu');
    }
  }

  private buildPrompt(request: PostGenerationRequest): string {
    const {
      topic,
      tone,
      length,
      includeHashtags,
      includeEmojis,
      targetAudience
    } = request;

    let prompt = `Crée un post LinkedIn sur le sujet : "${topic}"\n\n`;

    // Définir le ton
    const toneInstructions = {
      professional: 'Adopte un ton professionnel et formel',
      casual: 'Adopte un ton décontracté et amical',
      inspiring: 'Adopte un ton inspirant et motivationnel',
      educational: 'Adopte un ton éducatif et informatif',
      promotional: 'Adopte un ton promotionnel mais pas trop commercial'
    };
    prompt += `${toneInstructions[tone]}.\n`;

    // Définir la longueur
    const lengthInstructions = {
      short: 'Garde le post court (100-200 mots)',
      medium: 'Crée un post de longueur moyenne (200-400 mots)',
      long: 'Développe un post détaillé (400-600 mots)'
    };
    prompt += `${lengthInstructions[length]}.\n`;

    // Audience cible
    if (targetAudience) {
      prompt += `Adapte le contenu pour cette audience : ${targetAudience}.\n`;
    }

    // Instructions pour les hashtags et emojis
    if (includeHashtags) {
      prompt += 'Inclus 3-5 hashtags pertinents à la fin du post.\n';
    }

    if (includeEmojis) {
      prompt += 'Utilise des emojis appropriés pour rendre le post plus engageant.\n';
    }

    prompt += `\nStructure le post de manière à maximiser l'engagement :
- Commence par un hook accrocheur
- Développe ton message principal
- Termine par une question ou un call-to-action pour encourager les interactions
- Assure-toi que le contenu apporte de la valeur à ton audience

Respecte la limite de 3000 caractères de LinkedIn.`;

    return prompt;
  }

  async generateHashtags(topic: string, count: number = 5): Promise<string[]> {
    try {
      const prompt = `Génère ${count} hashtags pertinents et populaires pour un post LinkedIn sur le sujet : "${topic}".
                     Retourne uniquement les hashtags, un par ligne, sans le symbole #.`;

      const completion = await this.openai.chat.completions.create({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 200,
        temperature: 0.5,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        return [];
      }

      return content
        .split('\n')
        .map(tag => tag.trim().replace(/^#/, ''))
        .filter(tag => tag.length > 0)
        .slice(0, count);
    } catch (error) {
      console.error('Erreur lors de la génération des hashtags:', error);
      return [];
    }
  }
}

export default new OpenAIService();
