import { Controller, Get, Post, Body, Query, UseInterceptors, UploadedFile, UploadedFiles, UseGuards, Req } from '@nestjs/common';
import { PostService } from './post.service';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { mkdirSync } from 'fs';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('posts')
@UseGuards(JwtAuthGuard)
export class PostController {
  constructor(private postService: PostService) {}

  @Get('get_posts')
  async getPosts(@Req() req: any, @Query('limit') limit: string, @Query('cursor') cursor?: string) {
    const result = await this.postService.getPosts(req.user.id.toString(), limit, cursor);
    return { success: true, data: result };
  }

  @Get('search_posts')
  async searchPosts(@Req() req: any, @Query('q') q: string) {
    const result = await this.postService.searchPosts(req.user.id.toString(), q);
    return { success: true, data: result };
  }

  @Get('get_videos')
  async getVideos(@Req() req: any) {
    const result = await this.postService.getVideos(req.user.id.toString());
    return { success: true, data: result };
  }

  @Get('get_trending_tags')
  async getTrendingTags() {
    const result = await this.postService.getTrendingTags();
    return { success: true, data: result };
  }

  @Get('get_saved_posts')
  async getSavedPosts(@Req() req: any) {
    const result = await this.postService.getSavedPosts(req.user.id.toString());
    return { success: true, data: result };
  }

  @Get('get_post')
  async getPost(@Req() req: any, @Query('post_id') post_id: string) {
    const result = await this.postService.getPostById(req.user.id.toString(), post_id);
    return { success: true, data: result };
  }

  @Post('create_post')
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
      }
    })
  }))
  async createPost(@Req() req: any, @Body() body: any, @UploadedFile() file: Express.Multer.File) {
    body.user_id = req.user.id.toString();
    const result = await this.postService.createPost(body, file);
    return { success: true, data: result };
  }

  @Post('create_post_multi')
  @UseInterceptors(
    FilesInterceptor('media', 50, {
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
    }),
  )
  async createPostMulti(@Req() req: any, @Body() body: any, @UploadedFiles() files: Express.Multer.File[]) {
    body.user_id = req.user.id.toString();
    const result = await this.postService.createPostMulti(body, files || []);
    return { success: true, data: result };
  }

  @Post('repost_post')
  async repostPost(@Req() req: any, @Body() body: any) {
    const { post_id } = body;
    const result = await this.postService.repostPost(req.user.id.toString(), post_id);
    return result;
  }

  @Post('toggle_like')
  async toggleLike(@Req() req: any, @Body() body: any) {
    const { post_id } = body;
    const result = await this.postService.toggleLike(req.user.id.toString(), post_id);
    return { success: true, ...result };
  }

  @Post('toggle_save')
  async toggleSave(@Req() req: any, @Body() body: any) {
    const { post_id } = body;
    const result = await this.postService.toggleSave(req.user.id.toString(), post_id);
    return { success: true, ...result };
  }

  @Post('mark_view')
  async markView(@Req() req: any, @Body() body: any) {
    const { post_id } = body;
    const result = await this.postService.markView(req.user.id.toString(), post_id);
    return { success: true, ...result };
  }

  @Post('delete_post')
  async deletePost(@Req() req: any, @Body() body: any) {
    const { post_id } = body;
    const result = await this.postService.deletePost(req.user.id.toString(), post_id);
    return { success: true, ...result };
  }

  @Post('track_event')
  async trackEvent(@Req() req: any, @Body() body: any) {
    const result = await this.postService.trackEvent(req.user.id.toString(), body);
    return result;
  }
}
