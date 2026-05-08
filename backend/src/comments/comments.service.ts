import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ChatGateway } from '../chat/chat.gateway';

@Injectable()
export class CommentService {
  constructor(
    private prisma: PrismaService,
    private chatGateway: ChatGateway
  ) {}

  private async notifyMentions(content: string, actorId: number, postId: number, commentId: number) {
    if (!content) return;
    const mentions = content.match(/@(\w+)/g);
    if (!mentions) return;

    const usernames = mentions.map(m => m.substring(1));
    const users = await this.prisma.user.findMany({
      where: { username: { in: usernames } },
      select: { id: true }
    });

    const actor = await this.prisma.user.findUnique({
      where: { id: actorId },
      select: { id: true, name: true, photo: true }
    });

    for (const user of users) {
      if (user.id === actorId) continue;

      const notification = await this.prisma.notification.create({
        data: {
          userId: user.id,
          actorId,
          type: 'mention',
          title: 'إشارة في تعليق',
          body: `قام ${actor?.name} بالإشارة إليك في تعليق`,
          postId,
          commentId,
        }
      });

      this.chatGateway.emitNotification(user.id.toString(), {
        ...notification,
        id: notification.id.toString(),
        actor
      });
    }
  }

  private formatComment(c: any, currentUserId?: number) {
    return {
      id: c.id.toString(),
      userId: c.userId.toString(),
      userName: c.user.name,
      userPhoto: c.user.photo,
      comment: c.comment,
      parentId: c.parentId?.toString(),
      createdAt: c.createdAt,
      time: c.createdAt.toISOString(),
      likesCount: c._count?.likes || 0,
      isLiked: currentUserId ? (c.likes?.length || 0) > 0 : false,
      replies: (c.replies || []).map((r: any) => this.formatComment(r, currentUserId)),
    };
  }

  async getComments(postId: number, userId?: number) {
    const comments = await this.prisma.comment.findMany({
      where: { postId, parentId: null },
      include: {
        user: { select: { id: true, name: true, photo: true } },
        likes: userId ? { where: { userId } } : false,
        _count: { select: { likes: true } },
        replies: {
          include: {
            user: { select: { id: true, name: true, photo: true } },
            likes: userId ? { where: { userId } } : false,
            _count: { select: { likes: true } },
          },
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return comments.map((c) => this.formatComment(c, userId));
  }

  async addComment(postId: number, userId: number, comment: string, parentId?: number) {
    const newComment = await this.prisma.comment.create({
      data: {
        postId,
        userId,
        comment,
        parentId: parentId || null,
      },
      include: {
        user: { select: { id: true, name: true, photo: true } },
        _count: { select: { likes: true } },
      },
    });

    const post = await this.prisma.post.findUnique({
      where: { id: postId },
      include: { user: true },
    });
    if (post && post.userId !== userId) {
      const notification = await this.prisma.notification.create({
        data: {
          userId: post.userId,
          actorId: userId,
          type: parentId ? 'reply' : 'comment',
          title: parentId ? 'رد جديد على تعليق' : 'تعليق جديد',
          body: comment,
          postId: post.id,
          commentId: newComment.id,
        },
      });

      const actor = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, name: true, photo: true }
      });

      this.chatGateway.emitNotification(post.userId.toString(), {
        ...notification,
        id: notification.id.toString(),
        actor
      });
    }

    if (parentId) {
      const parentComment = await this.prisma.comment.findUnique({ where: { id: parentId } });
      if (parentComment && parentComment.userId !== userId) {
        const replyNotification = await this.prisma.notification.create({
          data: {
            userId: parentComment.userId,
            actorId: userId,
            type: 'reply',
            title: 'رد على تعليقك',
            body: comment,
            postId,
            commentId: newComment.id,
          },
        });

        const actor = await this.prisma.user.findUnique({
          where: { id: userId },
          select: { id: true, name: true, photo: true }
        });

        this.chatGateway.emitNotification(parentComment.userId.toString(), {
          ...replyNotification,
          id: replyNotification.id.toString(),
          actor
        });
      }
    }

    return {
      id: newComment.id.toString(),
      userId: newComment.userId.toString(),
      userName: newComment.user.name,
      userPhoto: newComment.user.photo,
      comment: newComment.comment,
      parentId: newComment.parentId?.toString(),
      likesCount: newComment._count?.likes || 0,
      isLiked: false,
      replies: [],
      createdAt: newComment.createdAt,
    };
  }

  async toggleCommentLike(commentId: number, userId: number) {
    const existing = await this.prisma.commentLike.findUnique({
      where: { userId_commentId: { userId, commentId } },
    });

    let isLiked = false;
    if (existing) {
      await this.prisma.commentLike.delete({ where: { id: existing.id } });
    } else {
      await this.prisma.commentLike.create({ data: { commentId, userId } });
      isLiked = true;
      const comment = await this.prisma.comment.findUnique({ where: { id: commentId } });
      if (comment && comment.userId !== userId) {
        const notification = await this.prisma.notification.create({
          data: {
            userId: comment.userId,
            actorId: userId,
            type: 'comment_like',
            title: 'إعجاب بتعليقك',
            body: 'تم الإعجاب بتعليقك',
            postId: comment.postId,
            commentId: comment.id,
          },
        });

        const actor = await this.prisma.user.findUnique({
          where: { id: userId },
          select: { id: true, name: true, photo: true }
        });

        this.chatGateway.emitNotification(comment.userId.toString(), {
          ...notification,
          id: notification.id.toString(),
          actor
        });
      }
    }

    const count = await this.prisma.commentLike.count({ where: { commentId } });
    return { isLiked, likesCount: count };
  }

  async deleteComment(commentId: number, userId: number) {
    const comment = await this.prisma.comment.findUnique({
      where: { id: commentId },
      include: { post: true }
    });

    if (!comment) throw new NotFoundException('التعليق غير موجود');
    
    // User can delete if they are the comment author, or the post author
    if (comment.userId !== userId && comment.post.userId !== userId) {
      throw new ForbiddenException('غير مصرح لك بحذف هذا التعليق');
    }

    await this.prisma.comment.delete({ where: { id: commentId } });
    return { success: true, message: 'تم حذف التعليق بنجاح' };
  }
}
