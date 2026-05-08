import { Controller, Get, Post, Body, UseInterceptors, UploadedFile, BadRequestException, UseGuards, Req } from '@nestjs/common';
import { StoryService } from './stories.service';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { mkdirSync } from 'fs';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('stories')
@UseGuards(JwtAuthGuard)
export class StoryController {
  constructor(private readonly storyService: StoryService) {}

  @Get('get_stories')
  async getStories(@Req() req: any) {
    const result = await this.storyService.getStories(req.user.id);
    return { success: true, data: result };
  }

  @Post('add_story')
  @UseInterceptors(FileInterceptor('media', {
    storage: diskStorage({
      destination: (req, file, cb) => {
        const uploadPath = join(process.cwd(), 'uploads');
        mkdirSync(uploadPath, { recursive: true });
        cb(null, uploadPath);
      },
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, uniqueSuffix + extname(file.originalname));
      },
    }),
  }))
  async addStory(@Req() req: any, @Body() body: any, @UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Media file is required');
    const { media_type } = body;
    const result = await this.storyService.addStory(
      req.user.id,
      `/uploads/${file.filename}`,
      media_type || (file.mimetype.startsWith('video') ? 'video' : 'image'),
    );
    return { success: true, data: result };
  }

  @Post('toggle_story_like')
  async toggleLike(@Req() req: any, @Body() body: any) {
    const { story_id } = body;
    const result = await this.storyService.toggleLike(req.user.id, parseInt(story_id));
    return { success: true, ...result };
  }

  @Post('mark_story_viewed')
  async markViewed(@Req() req: any, @Body() body: any) {
    const { story_id } = body;
    await this.storyService.markViewed(req.user.id, parseInt(story_id));
    return { success: true };
  }

  @Post('delete_story')
  async deleteStory(@Req() req: any, @Body() body: any) {
    const { story_id } = body;
    if (!story_id) throw new BadRequestException('Story ID is required');
    const result = await this.storyService.deleteStory(req.user.id, parseInt(story_id));
    return result;
  }
}
