import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class StoryService {
  constructor(private prisma: PrismaService) {}

  async getStories(userId: number) {
    const stories = await this.prisma.story.findMany({
      where: {
        OR: [
          { userId },
          { user: { followers: { some: { followerId: userId } } } },
        ],
        createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
      },
      include: {
        user: { select: { id: true, name: true, photo: true, username: true } },
        _count: { select: { views: true, likes: true } },
        likes: { where: { userId } },
      },
      orderBy: { createdAt: 'desc' },
    });

    const grouped = stories.reduce((acc: any, story) => {
      const uId = story.userId.toString();
      if (!acc[uId]) {
        acc[uId] = {
          user_id: uId,
          name: story.user.name,
          photo: story.user.photo,
          stories: [],
        };
      }
      acc[uId].stories.push({
        id: story.id.toString(),
        media_url: story.mediaUrl,
        media_type: story.mediaType,
        created_at: story.createdAt,
        isLiked: story.likes.length > 0,
        views: story._count.views,
        likes: story._count.likes,
      });
      return acc;
    }, {});

    return Object.values(grouped);
  }

  async addStory(userId: number, mediaUrl: string, mediaType: string) {
    return this.prisma.story.create({
      data: {
        userId,
        mediaUrl,
        mediaType,
      },
    });
  }

  async toggleLike(userId: number, storyId: number) {
    const existing = await this.prisma.storyLike.findUnique({
      where: { userId_storyId: { userId, storyId } },
    });

    if (existing) {
      await this.prisma.storyLike.delete({ where: { id: existing.id } });
      return { liked: false };
    } else {
      await this.prisma.storyLike.create({ data: { userId, storyId } });
      return { liked: true };
    }
  }

  async markViewed(userId: number, storyId: number) {
    return this.prisma.storyView.upsert({
      where: { userId_storyId: { userId, storyId } },
      create: { userId, storyId },
      update: {},
    });
  }

  async deleteStory(userId: number, storyId: number) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) throw new NotFoundException('القصة غير موجودة');
    if (story.userId !== userId) throw new ForbiddenException('غير مصرح لك بحذف هذه القصة');
    
    // Cleanup media file from storage
    if (story.mediaUrl && story.mediaUrl.startsWith('/uploads/')) {
      const filePath = path.join(process.cwd(), story.mediaUrl);
      try {
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      } catch (e) {
        console.error(`Failed to delete story media: ${filePath}`, e);
      }
    }

    await this.prisma.story.delete({ where: { id: storyId } });
    return { success: true, message: 'تم حذف القصة بنجاح' };
  }
}
