import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotesService {
  constructor(private prisma: PrismaService) {}

  async createNote(userId: number, content: string) {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    return this.prisma.note.upsert({
      where: { userId },
      update: {
        content,
        expiresAt,
        createdAt: new Date(),
      },
      create: {
        userId,
        content,
        expiresAt,
      },
    });
  }

  async getNotes(userId: number) {
    // Get users that the current user follows
    const following = await this.prisma.follower.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });

    const followingIds = following.map((f) => f.followingId);
    
    // Include the user's own note
    const userIds = [...followingIds, userId];

    return this.prisma.note.findMany({
      where: {
        userId: { in: userIds },
        expiresAt: { gt: new Date() },
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            username: true,
            photo: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async deleteNote(userId: number) {
    return this.prisma.note.deleteMany({
      where: { userId },
    });
  }
}
