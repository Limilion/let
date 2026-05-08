import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ChatGateway } from './chat.gateway';

@Injectable()
export class ChatService {
  constructor(
    private prisma: PrismaService,
    private chatGateway: ChatGateway,
  ) {}

  async getConversations(userId: number) {
    // ... (rest of the code)
    const conversations = await this.prisma.conversation.findMany({
      where: {
        OR: [{ user1Id: userId }, { user2Id: userId }],
      },
      include: {
        user1: { select: { id: true, name: true, photo: true, username: true } },
        user2: { select: { id: true, name: true, photo: true, username: true } },
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    return conversations.map((conv) => {
      const otherUser = conv.user1Id === userId ? conv.user2 : conv.user1;
      const lastMessage = conv.messages[0];
      let lastText = '';
      if (lastMessage) {
        if (lastMessage.type === 'voice') lastText = '🎤 رسالة صوتية';
        else if (lastMessage.type === 'image') lastText = '📷 صورة';
        else lastText = lastMessage.content || '';
      }
      return {
        id: conv.id.toString(),
        otherUser: {
          id: otherUser.id.toString(),
          name: otherUser.name,
          username: otherUser.username,
          photo: otherUser.photo,
        },
        lastMessage: lastText,
        time: lastMessage ? lastMessage.createdAt.toISOString() : conv.updatedAt.toISOString(),
        unreadCount: 0,
      };
    });
  }

  async getMessages(userId: number, otherId: number) {
    let conversation = await this.prisma.conversation.findFirst({
      where: {
        OR: [
          { user1Id: userId, user2Id: otherId },
          { user1Id: otherId, user2Id: userId },
        ],
      },
    });

    if (!conversation) return [];

    const messages = await this.prisma.message.findMany({
      where: { conversationId: conversation.id },
      orderBy: { createdAt: 'asc' },
    });

    return messages.map((m) => ({
      id: m.id.toString(),
      senderId: m.senderId.toString(),
      receiverId: m.receiverId.toString(),
      message: m.content,
      mediaUrl: m.mediaUrl,
      type: m.type,
      createdAt: m.createdAt,
      time: m.createdAt.toISOString(),
      isMe: m.senderId === userId,
    }));
  }

  async sendMessage(senderId: number, receiverId: number, content: string, file?: any, type: string = 'text') {
    let conversation = await this.prisma.conversation.findFirst({
      where: {
        OR: [
          { user1Id: senderId, user2Id: receiverId },
          { user1Id: receiverId, user2Id: senderId },
        ],
      },
    });

    if (!conversation) {
      conversation = await this.prisma.conversation.create({
        data: {
          user1Id: Math.min(senderId, receiverId),
          user2Id: Math.max(senderId, receiverId),
        },
      });
    }

    const message = await this.prisma.message.create({
      data: {
        conversationId: conversation.id,
        senderId,
        receiverId,
        content: content || null,
        mediaUrl: file ? `/uploads/${file.filename}` : null,
        type,
      },
    });

    await this.prisma.conversation.update({
      where: { id: conversation.id },
      data: { updatedAt: new Date() },
    });

    const response = {
      id: message.id.toString(),
      senderId: message.senderId.toString(),
      receiverId: message.receiverId.toString(),
      message: message.content,
      mediaUrl: message.mediaUrl,
      type: message.type,
      createdAt: message.createdAt,
      time: message.createdAt.toISOString(),
      isMe: false, // For the receiver
    };

    // Broadcast real-time
    this.chatGateway.emitMessage(receiverId.toString(), response);

    return { ...response, isMe: true }; // For the sender
  }
}
