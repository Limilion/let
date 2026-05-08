import { Controller, Get, Post, Body, Query, BadRequestException, UseGuards, Req } from '@nestjs/common';
import { CommentService } from './comments.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('comments')
@UseGuards(JwtAuthGuard)
export class CommentController {
  constructor(private readonly commentService: CommentService) {}

  @Get('get_comments')
  async getComments(@Req() req: any, @Query('post_id') postId: string) {
    if (!postId) throw new BadRequestException('Post ID is required');
    const result = await this.commentService.getComments(
      parseInt(postId),
      req.user.id,
    );
    return { success: true, data: result };
  }

  @Post('add_comment')
  async addComment(@Req() req: any, @Body() body: any) {
    const { post_id, comment, parent_id } = body;
    const result = await this.commentService.addComment(
      parseInt(post_id),
      req.user.id,
      comment,
      parent_id ? parseInt(parent_id) : undefined,
    );
    return { success: true, data: result };
  }

  @Post('toggle_comment_like')
  async toggleCommentLike(@Req() req: any, @Body() body: any) {
    const { comment_id } = body;
    const result = await this.commentService.toggleCommentLike(
      parseInt(comment_id),
      req.user.id,
    );
    return { success: true, ...result };
  }

  @Post('delete_comment')
  async deleteComment(@Req() req: any, @Body() body: any) {
    const { comment_id } = body;
    if (!comment_id) throw new BadRequestException('Comment ID is required');
    const result = await this.commentService.deleteComment(
      parseInt(comment_id),
      req.user.id,
    );
    return result;
  }
}
