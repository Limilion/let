import { Injectable, ConflictException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcryptjs';
import * as jwt from 'jsonwebtoken';

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService) {}

  async register(data: any) {
    const { name, email, password, phone, photo, username } = data;
    const existingUser = await this.prisma.user.findFirst({
      where: { OR: [{ email }, { username }] }
    });
    if (existingUser) {
      throw new ConflictException('المستخدم موجود بالفعل');
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await this.prisma.user.create({
      data: {
        name,
        username: username || email.split('@')[0],
        email,
        password: hashedPassword,
        phone,
        photo,
      }
    });
    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    return {
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      photo: user.photo,
      coverPhoto: user.coverPhoto,
      bio: user.bio,
      profileLinks: user.profileLinks,
      tags: user.tags,
      musicTrack: user.musicTrack,
      token,
    };
  }

  async login(login_id: string, password: string) {
    const user = await this.prisma.user.findFirst({
      where: { OR: [{ email: login_id }, { username: login_id }] }
    });
    if (!user) {
      throw new NotFoundException('المستخدم غير موجود');
    }
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('كلمة المرور غير صحيحة');
    }
    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    return {
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      photo: user.photo,
      coverPhoto: user.coverPhoto,
      bio: user.bio,
      profileLinks: user.profileLinks,
      tags: user.tags,
      musicTrack: user.musicTrack,
      token,
    };
  }

  async updateProfile(data: any) {
    const { user_id, name, bio, phone, photo } = data;
    const user = await this.prisma.user.update({
      where: { id: parseInt(user_id) },
      data: { name, bio, phone, photo }
    });
    return {
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      bio: user.bio,
      photo: user.photo,
      coverPhoto: user.coverPhoto,
      profileLinks: user.profileLinks,
      tags: user.tags,
      musicTrack: user.musicTrack,
    };
  }

  async updateProfileV2(data: any) {
    const { user_id, name, bio, phone, photo, coverPhoto, profileLinks, tags, musicTrack, musicTitle } = data;
    const user = await this.prisma.user.update({
      where: { id: parseInt(user_id) },
      data: {
        name,
        bio,
        phone,
        photo,
        coverPhoto,
        profileLinks: Array.isArray(profileLinks) ? profileLinks : [],
        tags: Array.isArray(tags) ? tags : [],
        musicTrack,
        musicTitle,
      },
    });
    return {
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      bio: user.bio,
      photo: user.photo,
      coverPhoto: user.coverPhoto,
      profileLinks: user.profileLinks,
      tags: user.tags,
      musicTrack: user.musicTrack,
      musicTitle: user.musicTitle,
    };
  }

}
