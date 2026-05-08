import { Controller, Post, Body, UseGuards, UseInterceptors, UploadedFile } from '@nestjs/common';
import { AIService } from './ai.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { FileInterceptor } from '@nestjs/platform-express';

@Controller('ai')
@UseGuards(JwtAuthGuard)
export class AIController {
  constructor(private readonly aiService: AIService) {}

  @Post('prompt')
  async handlePrompt(@Body() body: { prompt: string }) {
    const result = await this.aiService.processPrompt(body.prompt);
    return { success: true, data: result };
  }

  @Post('analyze-image')
  @UseInterceptors(FileInterceptor('file'))
  async analyzeImage(@UploadedFile() file: Express.Multer.File, @Body('prompt') prompt?: string) {
    const result = await this.aiService.analyzeImage(file, prompt);
    return { success: true, data: result };
  }
}
