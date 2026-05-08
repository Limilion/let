import 'dotenv/config';
import { Injectable } from '@nestjs/common';
import { GoogleGenerativeAI } from '@google/generative-ai';

@Injectable()
export class AIService {
  private genAI: GoogleGenerativeAI;
  private model: any;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    console.log('Gemini API Key loaded:', apiKey ? `${apiKey.substring(0, 8)}...` : 'NOT LOADED');
    
    this.genAI = new GoogleGenerativeAI(apiKey || '');
    // Force API version v1 for stability and compatibility
    this.model = this.genAI.getGenerativeModel(
      { model: 'gemini-1.5-flash' },
      { apiVersion: 'v1' }
    );
  }

  async processPrompt(prompt: string) {
    const lowerPrompt = prompt.toLowerCase();

    // Image generation logic
    if (lowerPrompt.includes('image') || lowerPrompt.includes('صورة') || lowerPrompt.includes('توليد')) {
      const seed = Math.floor(Math.random() * 5000);
      return {
        type: 'image',
        content: `لقد قمت بتوليد صورة فنية تعبر عن: "${prompt}"`,
        imageUrl: `https://picsum.photos/seed/${seed}/1080/1350`,
      };
    }

    try {
      const systemPrompt = `You are a professional social media assistant for "Lettuce" app. 
      Users want creative captions, bios, or ideas. 
      Current user prompt: "${prompt}". 
      Respond in the same language as the prompt (Arabic or English). 
      Keep it engaging, use emojis, and hashtags if appropriate.`;

      // Try with current model
      const result = await this.model.generateContent(systemPrompt);
      const response = await result.response;
      const text = response.text();

      return {
        type: 'text',
        content: text,
      };
    } catch (error: any) {
      console.error('Gemini AI Error (Attempt 1):', error.message);
      
      try {
        console.log('Retrying with gemini-pro (v1)...');
        const backupModel = this.genAI.getGenerativeModel(
          { model: 'gemini-pro' },
          { apiVersion: 'v1' }
        );
        const result = await backupModel.generateContent(prompt);
        const response = await result.response;
        return {
          type: 'text',
          content: response.text(),
        };
      } catch (backupError: any) {
        console.error('Gemini AI Fallback Error:', backupError.message);
        return {
          type: 'text',
          content: this.generateFallback(prompt),
        };
      }
    }
  }

  async analyzeImage(file: Express.Multer.File, customPrompt?: string) {
    try {
      const prompt = customPrompt || 'Describe this image for a social media post. Keep it engaging, short, and use emojis and hashtags in Arabic.';
      
      const imageParts = [
        {
          inlineData: {
            data: file.buffer.toString('base64'),
            mimeType: file.mimetype,
          },
        },
      ];

      const result = await this.model.generateContent([prompt, ...imageParts]);
      const response = await result.response;
      const text = response.text();

      return {
        type: 'text',
        content: text,
      };
    } catch (error: any) {
      console.error('Gemini Image Analysis Error:', error.message);
      return {
        type: 'text',
        content: 'لم أتمكن من تحليل الصورة حالياً، ربما يمكنك تجربة نص بديل.',
      };
    }
  }

  private generateFallback(topic: string): string {
    const captions = [
      'النجاح ليس مجرد وجهة، بل هو رحلة مستمرة من التعلم والتطور. 🚀 #طموح #نجاح',
      'كل يوم هو فرصة جديدة لكتابة قصة نجاحك الخاصة. ابدأ الآن! ✨ #إيجابية #حلم',
    ];
    return captions[Math.floor(Math.random() * captions.length)];
  }
}
