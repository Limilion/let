import { Module } from '@nestjs/common';
import { UserController } from './user.controller';
import { UserService } from './user.service';
import { ChatModule } from '../chat/chat.module';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule, ChatModule],
  controllers: [UserController],
  providers: [UserService],
})
export class UserModule {}
