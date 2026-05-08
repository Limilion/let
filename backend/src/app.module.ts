import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { PostModule } from './posts/post.module';
import { UserModule } from './users/user.module';
import { StoryModule } from './stories/stories.module';
import { ChatModule } from './chat/chat.module';
import { CommentModule } from './comments/comments.module';
import { MulterModule } from '@nestjs/platform-express';
import { AIModule } from './ai/ai.module';
import { NotesModule } from './notes/notes.module';

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    PostModule,
    UserModule,
    StoryModule,
    ChatModule,
    CommentModule,
    AIModule,
    NotesModule,
    MulterModule.register({
      dest: './uploads',
    }),
  ],
  controllers: [AppController],
})
export class AppModule {}
