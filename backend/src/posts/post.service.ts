import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ChatGateway } from '../chat/chat.gateway';
import * as fs from 'fs';
import * as path from 'path';

type FeedCursor = {
  createdAt: string;
  id: number;
};

@Injectable()
export class PostService {
  constructor(
    private prisma: PrismaService,
    private chatGateway: ChatGateway
  ) {}
  private postViewsTableAvailable = true;
  private static readonly FEED_POOL_SIZE = 120;
  private static readonly DEFAULT_PAGE_SIZE = 20;

  private calculateEngagementScore(post: any): number {
    const likesWeight = 2.5;
    const commentsWeight = 5.0;
    const viewsWeight = 0.5;
    const recencyWeight = 10.0;

    const likesCount = post._count?.likes || 0;
    const commentsCount = post._count?.comments || 0;
    const viewsCount = post._count?.views || 0;

    // Time decay: newer posts get much higher scores
    const now = new Date().getTime();
    const created = new Date(post.createdAt).getTime();
    const ageHours = (now - created) / (1000 * 60 * 60);
    
    // Formula: (Likes*W + Comments*W + Views*W + Recency) / (Age + 2)^1.5
    const rawScore = (likesCount * likesWeight) + (commentsCount * commentsWeight) + (viewsCount * viewsWeight);
    const decay = Math.pow(ageHours + 2, 1.5);
    
    return (rawScore + recencyWeight) / decay;
  }

  // Helper method to format post for Flutter (snake_case)
  private formatPostForFlutter(post: any, savedPostIds?: Set<number>) {
    if (!post) return null;
    return {
      id: post.id.toString(),
      user_id: post.userId.toString(),
      name: post.user?.name || '',
      username: post.user?.username || '',
      photo: post.user?.photo,
      content: post.content,
      image_url: post.mediaUrl,
      media_type: post.mediaType,
      likes: post._count?.likes || 0,
      comments_count: post._count?.comments || 0,
      views_count: post._count?.views || 0,
      isLiked: post.likes ? post.likes.length > 0 : false,
      isSaved: savedPostIds ? savedPostIds.has(post.id) : false,
      created_at: post.createdAt,
      time: post.createdAt ? this.formatTimeAgo(post.createdAt) : 'الآن',
      media_urls: post.mediaItems ? post.mediaItems.map((item: any) => item.url) : (post.mediaUrl ? [post.mediaUrl] : []),
      is_celebrity: post.user?._count?.followers >= 10000,
      repost: post.repost ? this.formatPostForFlutter(post.repost, savedPostIds) : null,
      repost_id: post.repostId ? post.repostId.toString() : null
    };
  }

  private parseCursor(cursor?: string): FeedCursor | null {
    if (!cursor) return null;
    try {
      const parsed = JSON.parse(Buffer.from(cursor, 'base64').toString('utf8'));
      if (!parsed?.createdAt || !parsed?.id) return null;
      return {
        createdAt: parsed.createdAt,
        id: Number(parsed.id),
      };
    } catch (_) {
      return null;
    }
  }

  private buildCursor(post: any): string {
    const payload = JSON.stringify({
      createdAt: post.createdAt instanceof Date ? post.createdAt.toISOString() : post.createdAt,
      id: post.id,
    });
    return Buffer.from(payload, 'utf8').toString('base64');
  }

  private formatTimeAgo(date: Date | string): string {
    const now = new Date();
    const then = new Date(date);
    const diff = now.getTime() - then.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (minutes < 1) return 'الآن';
    if (minutes < 60) return `منذ ${minutes} د`;
    if (hours < 24) return `منذ ${hours} س`;
    if (days < 7) return `منذ ${days} ي`;
    return then.toLocaleDateString('ar-EG');
  }

  async getPosts(user_id: string, limit: string = '20', cursor?: string) {
    const uid = parseInt(user_id);
    if (!user_id || isNaN(uid)) {
      return { items: [], nextCursor: null, hasMore: false };
    }
    const pageSize = Math.min(
      Math.max(parseInt(limit || '20', 10) || PostService.DEFAULT_PAGE_SIZE, 1),
      50,
    );
    const parsedCursor = this.parseCursor(cursor);

    const [following, savedPosts] = await Promise.all([
      this.prisma.follower.findMany({
        where: { followerId: uid },
        select: { followingId: true },
      }),
      this.prisma.savedPost.findMany({
        where: { userId: uid },
        select: { postId: true },
      }),
    ]);
    const followingIds = new Set(following.map((f) => f.followingId));
    const savedPostIds = new Set(savedPosts.map((s) => s.postId));
    const cursorFilter = parsedCursor
      ? {
          OR: [
            { createdAt: { lt: new Date(parsedCursor.createdAt) } },
            {
              createdAt: new Date(parsedCursor.createdAt),
              id: { lt: parsedCursor.id },
            },
          ],
        }
      : {};

    let posts: any[] = [];
    try {
      posts = await this.prisma.post.findMany({
        where: cursorFilter,
        take: PostService.FEED_POOL_SIZE,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        include: {
          user: { 
            select: { 
              id: true, 
              name: true, 
              username: true, 
              photo: true,
              _count: { select: { followers: true } }
            } 
          },
          _count: { select: { likes: true, comments: true, views: true, reposts: true } },
          likes: { where: { userId: uid } },
          repost: { 
            include: { 
              user: { 
                select: { 
                  id: true, 
                  name: true, 
                  username: true, 
                  photo: true,
                  _count: { select: { followers: true } }
                } 
              }, 
              _count: { select: { likes: true, comments: true } } 
            } 
          },
          mediaItems: { orderBy: { position: 'asc' } },
        }
      });
      this.postViewsTableAvailable = true;
    } catch (error: any) {
      if (error?.code !== 'P2021') throw error;
      
      this.postViewsTableAvailable = false;
      posts = await this.prisma.post.findMany({
        where: cursorFilter,
        take: PostService.FEED_POOL_SIZE,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        include: {
          user: { select: { id: true, name: true, username: true, photo: true } },
          _count: { select: { likes: true, comments: true, reposts: true } },
          likes: { where: { userId: uid } },
          repost: { include: { user: true, _count: { select: { likes: true, comments: true } } } },
          mediaItems: { orderBy: { position: 'asc' } },
        }
      });
    }

    const rankedPosts = posts.map((post: any) => {
      let score = this.calculateEngagementScore(post);
      const hoursAgo = (Date.now() - new Date(post.createdAt).getTime()) / (1000 * 60 * 60);
      const creatorBoost = (post.user?._count?.followers || 0) > 1000 ? 1.08 : 1.0;
      const mediaBoost = post.mediaType?.includes('video') ? 1.1 : 1.0;
      
      if (followingIds.has(post.userId)) {
        score *= 1.6;
      } else if (hoursAgo < 12) {
        score *= 1.1;
      }
      score *= creatorBoost;
      score *= mediaBoost;
      
      return { ...post, engagement_score: score };
    });

    // Sort by final engagement score
    rankedPosts.sort((a: any, b: any) => b.engagement_score - a.engagement_score);

    const paginated = rankedPosts.slice(0, pageSize);
    const hasMore = rankedPosts.length > pageSize;
    const lastPost = paginated[paginated.length - 1];
    const nextCursor = hasMore && lastPost ? this.buildCursor(lastPost) : null;

    return {
      items: paginated.map((post: any) => this.formatPostForFlutter(post, savedPostIds)),
      nextCursor,
      hasMore,
    };
  }

  async getVideos(user_id: string) {
    if (!user_id || isNaN(parseInt(user_id))) return [];

    let posts: any[] = [];
    try {
      posts = await this.prisma.post.findMany({
        where: {
          OR: [
            { mediaType: { contains: 'video' } },
            { mediaUrl: { contains: '.mp4' } },
            { mediaUrl: { contains: '.mov' } },
            { mediaUrl: { contains: '.avi' } }
          ]
        },
        orderBy: { createdAt: 'desc' },
        include: {
          user: { 
            select: { 
              id: true, 
              name: true, 
              username: true, 
              photo: true,
              _count: { select: { followers: true } }
            } 
          },
          _count: { select: { likes: true, comments: true, views: true } },
          likes: { where: { userId: parseInt(user_id) } },
          mediaItems: { orderBy: { position: 'asc' } },
        }
      });
      this.postViewsTableAvailable = true;
    } catch (error: any) {
      if (error?.code !== 'P2021') {
        throw error;
      }
      this.postViewsTableAvailable = false;
      posts = await this.prisma.post.findMany({
        where: {
          OR: [
            { mediaType: { contains: 'video' } },
            { mediaUrl: { contains: '.mp4' } },
            { mediaUrl: { contains: '.mov' } },
            { mediaUrl: { contains: '.avi' } }
          ]
        },
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, name: true, username: true, photo: true } },
          _count: { select: { likes: true, comments: true } },
          likes: { where: { userId: parseInt(user_id) } }
          ,
          mediaItems: { orderBy: { position: 'asc' } },
        }
      });
    }

    return posts.map(post => this.formatPostForFlutter(post));
  }

  private async notifyMentions(content: string, actorId: number, postId?: number, commentId?: number) {
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
          title: 'إشارة جديدة',
          body: `قام ${actor?.name} بالإشارة إليك`,
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

  async createPost(data: any, file?: any) {
    const { user_id, content, privacy, media_type, media_url } = data;
    const post = await this.prisma.post.create({
      data: {
        userId: parseInt(user_id),
        content,
        privacy: privacy || 'public',
        mediaType: file 
          ? (file.mimetype.startsWith('video') ? 'video' : (file.mimetype.startsWith('image') ? 'image' : 'video')) 
          : (media_url ? 'image' : (media_type || 'text')),
        mediaUrl: file ? `/uploads/${file.filename}` : (media_url || null)
      },
      include: {
        user: { select: { id: true, name: true, username: true, photo: true } },
        _count: { select: { likes: true, comments: true } },
        mediaItems: { orderBy: { position: 'asc' } },
      }
    });

    // Notify mentions
    if (content) {
      this.notifyMentions(content, parseInt(user_id), post.id);
    }

    return this.formatPostForFlutter(post);
  }

  async createPostMulti(data: any, files: Express.Multer.File[] = []) {
    const { user_id, content, privacy } = data;
    const hasVideo = files.some((f) => f.mimetype.startsWith('video'));
    const mediaType = hasVideo ? 'video' : (files.length > 0 ? 'image' : 'text');
    const post = await this.prisma.post.create({
      data: {
        userId: parseInt(user_id),
        content,
        privacy: privacy || 'public',
        mediaType,
        mediaUrl: files.length > 0 ? `/uploads/${files[0].filename}` : null,
        mediaItems: {
          create: files.map((file, index) => ({
            url: `/uploads/${file.filename}`,
            mediaType: file.mimetype.startsWith('video') ? 'video' : 'image',
            position: index,
          })),
        },
      },
      include: {
        user: { select: { id: true, name: true, username: true, photo: true } },
        _count: { select: { likes: true, comments: true, views: true } },
        likes: { where: { userId: parseInt(user_id) } },
        mediaItems: { orderBy: { position: 'asc' } },
      },
    });

    // Notify mentions
    if (content) {
      this.notifyMentions(content, parseInt(user_id), post.id);
    }

    return this.formatPostForFlutter(post);
  }

  async repostPost(user_id: string, post_id: string) {
    const originalPost = await this.prisma.post.findUnique({ where: { id: parseInt(post_id) } });
    if (!originalPost) throw new NotFoundException('المنشور غير موجود');

    const newPost = await this.prisma.post.create({
      data: {
        userId: parseInt(user_id),
        repostId: parseInt(post_id),
        privacy: 'public',
        mediaType: 'text',
      }
    });
    return { success: true, message: 'تم إعادة النشر بنجاح' };
  }

  async toggleLike(user_id: string, post_id: string) {
    const uid = parseInt(user_id);
    const pid = parseInt(post_id);
    const existingLike = await this.prisma.like.findUnique({
      where: { userId_postId: { userId: uid, postId: pid } }
    });

    if (existingLike) {
      await this.prisma.like.delete({ where: { id: existingLike.id } });
      return { message: 'Like removed', isLiked: false };
    } else {
      await this.prisma.like.create({ data: { userId: uid, postId: pid } });
      const post = await this.prisma.post.findUnique({ where: { id: pid } });
      if (post && post.userId !== uid) {
        const notification = await this.prisma.notification.create({
          data: {
            userId: post.userId,
            actorId: uid,
            type: 'like',
            title: 'إعجاب جديد',
            body: 'أعجب أحد المستخدمين بمنشورك',
            postId: pid,
          },
        });

        // Fetch actor details for the notification
        const actor = await this.prisma.user.findUnique({
          where: { id: uid },
          select: { id: true, name: true, photo: true }
        });

        this.chatGateway.emitNotification(post.userId.toString(), {
          ...notification,
          id: notification.id.toString(),
          actor
        });
      }
      return { message: 'Post liked', isLiked: true };
    }
  }

  async toggleSave(user_id: string, post_id: string) {
    const uid = parseInt(user_id);
    const pid = parseInt(post_id);
    const existingSave = await this.prisma.savedPost.findUnique({
      where: { userId_postId: { userId: uid, postId: pid } }
    });

    if (existingSave) {
      await this.prisma.savedPost.delete({ where: { id: existingSave.id } });
      return { message: 'Save removed', saved: false };
    } else {
      await this.prisma.savedPost.create({ data: { userId: uid, postId: pid } });
      return { message: 'Post saved', saved: true };
    }
  }

  async markView(user_id: string, post_id: string) {
    if (!this.postViewsTableAvailable) {
      return { views_count: 0 };
    }

    const uid = parseInt(user_id);
    const pid = parseInt(post_id);

    if (Number.isNaN(uid) || Number.isNaN(pid)) {
      throw new BadRequestException('معرف المستخدم أو المنشور غير صالح');
    }

    try {
      await this.prisma.postView.upsert({
        where: { userId_postId: { userId: uid, postId: pid } },
        update: { createdAt: new Date() },
        create: { userId: uid, postId: pid },
      });
    } catch (error: any) {
      if (error?.code === 'P2021') {
        this.postViewsTableAvailable = false;
        return { views_count: 0 };
      }
      throw error;
    }

    const post = await this.prisma.post.findUnique({
      where: { id: pid },
      include: { _count: { select: { views: true } } },
    });

    if (!post) {
      throw new NotFoundException('المنشور غير موجود');
    }

    return { views_count: post._count.views };
  }

  async getSavedPosts(user_id: string) {
    if (!user_id || isNaN(parseInt(user_id))) return [];
    
    const saved = await this.prisma.savedPost.findMany({
      where: { userId: parseInt(user_id) },
      include: {
        post: {
          include: {
            user: { select: { id: true, name: true, username: true, photo: true } },
            _count: { select: { likes: true, comments: true } },
            likes: { where: { userId: parseInt(user_id) } },
            repost: { include: { user: true, _count: { select: { likes: true, comments: true } } } }
            ,
            mediaItems: { orderBy: { position: 'asc' } },
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    return saved.map(s => this.formatPostForFlutter(s.post));
  }

  async getPostById(user_id: string, post_id: string) {
    if (!user_id || isNaN(parseInt(user_id)) || !post_id || isNaN(parseInt(post_id))) {
      throw new BadRequestException('معرف المستخدم أو المنشور غير صالح');
    }
    const uid = parseInt(user_id);
    const pid = parseInt(post_id);
    const post = await this.prisma.post.findUnique({
      where: { id: pid },
      include: {
        user: { 
          select: { 
            id: true, 
            name: true, 
            username: true, 
            photo: true,
            _count: { select: { followers: true } }
          } 
        },
        _count: { select: { likes: true, comments: true, views: true } },
        likes: { where: { userId: uid } },
        repost: { 
          include: { 
            user: { 
              select: { 
                id: true, 
                name: true, 
                username: true, 
                photo: true,
                _count: { select: { followers: true } }
              } 
            }, 
            _count: { select: { likes: true, comments: true } } 
          } 
        },
        mediaItems: { orderBy: { position: 'asc' } },
      },
    });
    if (!post) {
      throw new NotFoundException('المنشور غير موجود');
    }
    return this.formatPostForFlutter(post);
  }

  async deletePost(user_id: string, post_id: string) {
    const post = await this.prisma.post.findUnique({ 
      where: { id: parseInt(post_id) },
      include: { mediaItems: true }
    });
    if (!post) throw new NotFoundException('المنشور غير موجود');
    if (post.userId !== parseInt(user_id)) throw new ForbiddenException('غير مصرح لك بحذف هذا المنشور');
    
    // Cleanup files from storage to prevent leaks
    const filesToDelete: string[] = [];
    if (post.mediaUrl) filesToDelete.push(post.mediaUrl);
    if (post.mediaItems && post.mediaItems.length > 0) {
      post.mediaItems.forEach(item => filesToDelete.push(item.url));
    }

    filesToDelete.forEach(fileUrl => {
      // url might be `/uploads/file.png`
      if (fileUrl.startsWith('/uploads/')) {
        const filePath = path.join(process.cwd(), fileUrl);
        try {
          if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
          }
        } catch (e) {
          console.error(`Failed to delete media file: ${filePath}`, e);
        }
      }
    });

    await this.prisma.post.delete({ where: { id: post.id } });
    return { message: 'تم حذف المنشور بنجاح' };
  }


  async searchPosts(user_id: string, q: string) {
    if (!user_id || isNaN(parseInt(user_id)) || !q) return [];
    const query = q.trim().toLowerCase();

    let posts: any[] = [];
    try {
      posts = await this.prisma.post.findMany({
        where: {
          content: { contains: q, mode: 'insensitive' }
        },
        take: 50,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { 
            select: { 
              id: true, 
              name: true, 
              username: true, 
              photo: true,
              _count: { select: { followers: true } }
            } 
          },
          _count: { select: { likes: true, comments: true, views: true, reposts: true } },
          likes: { where: { userId: parseInt(user_id) } },
          repost: { 
            include: { 
              user: { 
                select: { 
                  id: true, 
                  name: true, 
                  username: true, 
                  photo: true,
                  _count: { select: { followers: true } }
                } 
              }, 
              _count: { select: { likes: true, comments: true } } 
            } 
          },
          mediaItems: { orderBy: { position: 'asc' } },
        }
      });
      this.postViewsTableAvailable = true;
    } catch (error: any) {
      if (error?.code !== 'P2021') {
        throw error;
      }
      this.postViewsTableAvailable = false;
      posts = await this.prisma.post.findMany({
        where: {
          content: { contains: q, mode: 'insensitive' }
        },
        take: 50,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, name: true, username: true, photo: true } },
          _count: { select: { likes: true, comments: true, reposts: true } },
          likes: { where: { userId: parseInt(user_id) } },
          repost: { include: { user: true, _count: { select: { likes: true, comments: true } } } },
          mediaItems: { orderBy: { position: 'asc' } },
        }
      });
    }

    const ranked = posts.map((post) => {
      const content = (post.content || '').toLowerCase();
      const likes = post._count?.likes || 0;
      const comments = post._count?.comments || 0;
      const views = post._count?.views || 0;
      const createdAt = new Date(post.createdAt).getTime();
      const ageHours = Math.max((Date.now() - createdAt) / (1000 * 60 * 60), 1);

      let relevance = 0;
      if (content.startsWith(query)) relevance += 30;
      if (content.includes(` ${query}`)) relevance += 15;
      if (content.includes(query)) relevance += 10;
      relevance += (likes * 1.2) + (comments * 2.3) + (views * 0.2);
      relevance += 15 / ageHours;
      return { post, relevance };
    });

    ranked.sort((a, b) => b.relevance - a.relevance);
    return ranked.map((entry) => this.formatPostForFlutter(entry.post));
  }

  async getTrendingTags() {
    // Get posts from the last 48 hours for trending data
    const twoDaysAgo = new Date();
    twoDaysAgo.setHours(twoDaysAgo.getHours() - 48);

    const recentPosts = await this.prisma.post.findMany({
      where: {
        createdAt: { gte: twoDaysAgo },
        content: { contains: '#' }
      },
      select: { content: true }
    });

    const tagCounts = new Map<string, number>();
    
    recentPosts.forEach(post => {
      if (!post.content) return;
      // Regex to find hashtags
      const tags = post.content.match(/#(\w+)/g);
      if (tags) {
        tags.forEach(tag => {
          const cleanTag = tag.substring(1).toLowerCase();
          tagCounts.set(cleanTag, (tagCounts.get(cleanTag) || 0) + 1);
        });
      }
    });

    // Sort tags by frequency
    return Array.from(tagCounts.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(entry => ({
        tag: entry[0],
        count: entry[1]
      }));
  }

  async trackEvent(userId: string, payload: any) {
    const uid = parseInt(userId);
    if (isNaN(uid) || !payload?.name) {
      throw new BadRequestException('بيانات الحدث غير صالحة');
    }

    await this.prisma.appEvent.create({
      data: {
        userId: uid,
        name: payload.name.toString(),
        source: payload.source?.toString() ?? null,
        metadata: payload.metadata ?? null,
      },
    });

    return { success: true };
  }
}

