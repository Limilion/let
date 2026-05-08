import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ChatGateway } from '../chat/chat.gateway';

@Injectable()
export class UserService {
  constructor(
    private prisma: PrismaService,
    private chatGateway: ChatGateway
  ) {}

  async getUserProfile(profile_id: string, current_user_id: string) {
    const profileId = parseInt(profile_id);
    const currentUserId = parseInt(current_user_id);
    const user = await this.prisma.user.findUnique({
      where: { id: parseInt(profile_id) },
      include: {
        _count: { select: { posts: true, followers: true, following: true } }
      }
    });
    if (!user) {
      throw new NotFoundException('المستخدم غير موجود');
    }
    const isFollowing = await this.prisma.follower.findUnique({
      where: {
        followerId_followingId: {
          followerId: currentUserId,
          followingId: profileId
        }
      }
    });

    const isFollowedBy = await this.prisma.follower.findUnique({
      where: {
        followerId_followingId: {
          followerId: profileId,
          followingId: currentUserId
        }
      }
    });

    const posts = await this.prisma.post.findMany({
      where: { userId: profileId },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { id: true, name: true, username: true, photo: true } },
        _count: { select: { likes: true, comments: true, views: true } },
        likes: { where: { userId: currentUserId } },
      },
      take: 100,
    });

    return {
      user: {
        id: user.id.toString(),
        name: user.name,
        username: user.username,
        email: user.email,
        photo: user.photo,
        coverPhoto: user.coverPhoto,
        bio: user.bio,
        profileLinks: user.profileLinks,
        tags: user.tags,
        musicTrack: user.musicTrack,
        stats: {
          posts: user._count.posts,
          followers: user._count.followers,
          following: user._count.following
        },
        followersCount: user._count.followers,
        followingCount: user._count.following,
        isCelebrity: user._count.followers >= 10000,
        isFollowing: !!isFollowing,
        isFollowedBy: !!isFollowedBy
      },
      posts: posts.map((post) => ({
        id: post.id.toString(),
        user_id: post.userId.toString(),
        name: post.user?.name || user.name,
        username: post.user?.username || user.username,
        photo: post.user?.photo || user.photo,
        content: post.content,
        image_url: post.mediaUrl,
        media_type: post.mediaType,
        likes: post._count?.likes || 0,
        comments_count: post._count?.comments || 0,
        views_count: post._count?.views || 0,
        engagement_score:
          (post._count?.likes || 0) * 2.5 +
          (post._count?.comments || 0) * 3.5 +
          (post._count?.views || 0) * 0.7,
        created_at: post.createdAt,
        time: post.createdAt?.toISOString(),
        isLiked: (post.likes?.length || 0) > 0,
      })),
    };
  }

  async toggleFollow(user_id: string, profile_id: string) {
    const uid = parseInt(user_id);
    const pid = parseInt(profile_id);
    const existingFollow = await this.prisma.follower.findUnique({
      where: { followerId_followingId: { followerId: uid, followingId: pid } }
    });
    if (existingFollow) {
      await this.prisma.follower.delete({ where: { id: existingFollow.id } });
      return { message: 'Unfollowed' };
    } else {
      await this.prisma.follower.create({ data: { followerId: uid, followingId: pid } });
      if (uid !== pid) {
        const notification = await this.prisma.notification.create({
          data: {
            userId: pid,
            actorId: uid,
            type: 'follow',
            title: 'متابع جديد',
            body: 'قام أحد المستخدمين بمتابعتك',
          },
          include: {
            user: { select: { id: true, name: true, photo: true } }
          }
        });

        // Fetch actor details for the notification
        const actor = await this.prisma.user.findUnique({
          where: { id: uid },
          select: { id: true, name: true, photo: true }
        });

        this.chatGateway.emitNotification(pid.toString(), {
          ...notification,
          id: notification.id.toString(),
          actor
        });
      }
      return { message: 'Followed' };
    }
  }

  async getNotifications(userId: string) {
    const uid = parseInt(userId);
    const notifications = await this.prisma.notification.findMany({
      where: { userId: uid },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    const actorIds = [...new Set(notifications.map((n) => n.actorId))];
    const actors = await this.prisma.user.findMany({
      where: { id: { in: actorIds } },
      select: { id: true, name: true, photo: true },
    });
    const actorMap = new Map(actors.map((a) => [a.id, a]));

    const typePriority: Record<string, number> = {
      mention: 100,
      reply: 90,
      follow: 80,
      comment: 70,
      like: 50,
    };

    const grouped: Map<string, any[]> = new Map();
    for (const n of notifications) {
      const bucket = `${n.type}:${n.actorId}:${n.postId ?? 0}`;
      const list = grouped.get(bucket) ?? [];
      list.push(n);
      grouped.set(bucket, list);
    }

    const merged = Array.from(grouped.values()).map((group) => {
      const sorted = group.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
      const latest = sorted[0];
      const withinWindow = sorted.filter(
        (item) => latest.createdAt.getTime() - item.createdAt.getTime() <= 1000 * 60 * 30,
      );
      const extraCount = Math.max(withinWindow.length - 1, 0);
      return {
        ...latest,
        body: extraCount > 0 ? `${latest.body} (+${extraCount})` : latest.body,
        _priority: typePriority[latest.type] ?? 40,
      };
    });

    merged.sort((a, b) => {
      if (b._priority !== a._priority) return b._priority - a._priority;
      return b.createdAt.getTime() - a.createdAt.getTime();
    });

    return merged.map((n) => ({
      id: n.id.toString(),
      type: n.type,
      title: n.title,
      body: n.body,
      isRead: n.isRead,
      createdAt: n.createdAt,
      postId: n.postId?.toString(),
      commentId: n.commentId?.toString(),
      actor: actorMap.get(n.actorId)
        ? {
            id: (actorMap.get(n.actorId) as any).id.toString(),
            name: (actorMap.get(n.actorId) as any).name,
            photo: (actorMap.get(n.actorId) as any).photo,
          }
        : null,
    }));
  }

  async markNotificationRead(userId: string, notificationId: string) {
    const uid = parseInt(userId);
    const nid = parseInt(notificationId);
    await this.prisma.notification.updateMany({
      where: { id: nid, userId: uid },
      data: { isRead: true },
    });
    return { success: true };
  }

  async markAllNotificationsRead(userId: string) {
    const uid = parseInt(userId);
    await this.prisma.notification.updateMany({
      where: { userId: uid, isRead: false },
      data: { isRead: true },
    });
    return { success: true };
  }

  async searchUsers(q: string, current_user_id: string) {
    const query = q.trim().toLowerCase();
    const currentUserId = parseInt(current_user_id);
    const following = await this.prisma.follower.findMany({
      where: { followerId: currentUserId },
      select: { followingId: true },
    });
    const followingIds = new Set(following.map((f) => f.followingId));

    const users = await this.prisma.user.findMany({
      where: {
        OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { username: { contains: q, mode: 'insensitive' } }
        ],
        NOT: { id: currentUserId }
      },
      include: {
        _count: { select: { followers: true } }
      },
      take: 20
    });

    const scored = users.map((u) => {
      const username = (u.username || '').toLowerCase();
      const name = (u.name || '').toLowerCase();
      let score = 0;
      if (username === query) score += 120;
      if (name === query) score += 100;
      if (username.startsWith(query)) score += 60;
      if (name.startsWith(query)) score += 50;
      if (username.includes(query)) score += 30;
      if (name.includes(query)) score += 25;
      if (followingIds.has(u.id)) score += 15;
      score += Math.min(u._count.followers / 200, 20);
      return { user: u, score };
    });

    scored.sort((a, b) => b.score - a.score);
    return scored.map((entry) => {
      const u = entry.user;
      return {
        ...u,
        id: u.id.toString(),
        isCelebrity: u._count.followers >= 10000,
      };
    });
  }

  async getSuggestedUsers(current_user_id: string) {
    const uid = parseInt(current_user_id);
    if (isNaN(uid)) return [];

    // 1. Get people the user already follows to exclude them
    const following = await this.prisma.follower.findMany({
      where: { followerId: uid },
      select: { followingId: true }
    });
    const followedIds = following.map(f => f.followingId);
    followedIds.push(uid); // Exclude self

    const suggestionScores = new Map<number, number>();

    // 2. Mutual Follows Logic: People followed by the people you follow
    if (followedIds.length > 1) { // 1 is just the self ID
      const friendsOfFriends = await this.prisma.follower.findMany({
        where: {
          followerId: { in: followedIds.filter(id => id !== uid) },
          followingId: { notIn: followedIds }
        },
        select: { followingId: true },
        take: 50
      });

      friendsOfFriends.forEach(mf => {
        const currentScore = suggestionScores.get(mf.followingId) || 0;
        suggestionScores.set(mf.followingId, currentScore + 10); // 10 points per mutual friend
      });
    }

    // 3. Tag Matching Logic: Users with similar interest tags
    const currentUser = await this.prisma.user.findUnique({
      where: { id: uid },
      select: { tags: true }
    });

    if (currentUser && currentUser.tags && currentUser.tags.length > 0) {
      const usersWithSimilarTags = await this.prisma.user.findMany({
        where: {
          id: { notIn: followedIds },
          tags: { hasSome: currentUser.tags }
        },
        select: { id: true, tags: true },
        take: 50
      });

      usersWithSimilarTags.forEach(u => {
        const matchingTagsCount = u.tags.filter(t => currentUser.tags.includes(t)).length;
        const currentScore = suggestionScores.get(u.id) || 0;
        suggestionScores.set(u.id, currentScore + (matchingTagsCount * 5)); // 5 points per matching tag
      });
    }

    // Activity Bonus
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const activeUsers = await this.prisma.post.findMany({
      where: { createdAt: { gte: sevenDaysAgo }, userId: { notIn: followedIds } },
      select: { userId: true },
      distinct: ['userId'],
      take: 50
    });
    activeUsers.forEach(au => {
      suggestionScores.set(au.userId, (suggestionScores.get(au.userId) || 0) + 15);
    });

    // 4. Fetch the actual user objects for the top scored suggestions
    const topSuggestionIds = Array.from(suggestionScores.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(entry => entry[0]);

    let suggestedUsers = await this.prisma.user.findMany({
      where: { id: { in: topSuggestionIds } },
      select: { id: true, name: true, username: true, photo: true, tags: true, _count: { select: { followers: true } } }
    });

    // 5. Fill with trending/popular users if needed
    if (suggestedUsers.length < 5) {
      const popularUsers = await this.prisma.user.findMany({
        where: { 
          id: { notIn: [...followedIds, ...topSuggestionIds] } 
        },
        orderBy: { followers: { _count: 'desc' } },
        take: 10 - suggestedUsers.length,
        select: { id: true, name: true, username: true, photo: true, tags: true, _count: { select: { followers: true } } }
      });
      suggestedUsers = [...suggestedUsers, ...popularUsers];
    }

    // Shuffle slightly to give variety
    suggestedUsers.sort(() => Math.random() - 0.5);

    return suggestedUsers.slice(0, 10).map(u => ({
      ...u,
      id: u.id.toString(),
      isFollowing: false,
      isCelebrity: (u as any)._count?.followers >= 10000
    }));
  }

  async getUserStats(userId: string) {
    const uid = parseInt(userId);
    const postsCount = await this.prisma.post.count({ where: { userId: uid } });
    const followersCount = await this.prisma.follower.count({ where: { followingId: uid } });
    const followingCount = await this.prisma.follower.count({ where: { followerId: uid } });
    
    // Count total likes on user's posts
    const likesCount = await this.prisma.like.count({
      where: { post: { userId: uid } }
    });

    // Count total comments on user's posts
    const commentsCount = await this.prisma.comment.count({
      where: { post: { userId: uid } }
    });

    // Count saved posts by user
    const savedCount = await this.prisma.savedPost.count({ where: { userId: uid } });

    return {
      posts: postsCount,
      followers: followersCount,
      following: followingCount,
      isCelebrity: followersCount >= 10000,
      likes: likesCount,
      comments: commentsCount,
      saved: savedCount,
      engagementRate: postsCount > 0 ? ((likesCount + commentsCount) / postsCount).toFixed(1) : '0.0'
    };
  }

  async changePassword(userId: string, currentPass: string, newPass: string) {
    const uid = parseInt(userId);
    const user = await this.prisma.user.findUnique({ where: { id: uid } });
    if (!user) throw new NotFoundException('المستخدم غير موجود');
    
    const bcrypt = require('bcryptjs');
    const isMatch = await bcrypt.compare(currentPass, user.password);
    if (!isMatch) throw new Error('كلمة المرور الحالية غير صحيحة');
    
    const hashedPassword = await bcrypt.hash(newPass, 10);
    await this.prisma.user.update({
      where: { id: uid },
      data: { password: hashedPassword }
    });
    return { success: true, message: 'تم تغيير كلمة المرور بنجاح' };
  }
}
