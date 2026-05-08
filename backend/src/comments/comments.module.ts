import { Module } from '@nestjs/common';
import { CommentController } from './comments.controller';
import { CommentService } from './comments.service';
import { PrismaModule } from '../prisma/prisma.module';
import { ChatModule } from '../chat/chat.module';

@Module({
  imports: [PrismaModule, ChatModule],
  controllers: [CommentController],
  providers: [CommentService],
})
export class CommentModule {}
