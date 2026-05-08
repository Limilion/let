import { Controller, Get, Post, Body, Query, UseGuards, Req, BadRequestException, UseInterceptors, UploadedFile } from '@nestjs/common';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { mkdirSync } from 'fs';

@Controller('chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('get_conversations')
  async getConversations(@Req() req: any) {
    const result = await this.chatService.getConversations(req.user.id);
    return { success: true, data: result };
  }

  @Get('get_messages')
  async getMessages(@Req() req: any, @Query('other_id') otherId: string) {
    const result = await this.chatService.getMessages(req.user.id, parseInt(otherId));
    return { success: true, data: result };
  }

  @Post('send_message')
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: (req, file, cb) => {
        const uploadPath = join(process.cwd(), 'uploads');
        mkdirSync(uploadPath, { recursive: true });
        cb(null, uploadPath);
      },
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, uniqueSuffix + extname(file.originalname));
      },
    }),
  }))
  async sendMessage(@Req() req: any, @Body() body: any, @UploadedFile() file?: any) {
    const { receiver_id, content, message, type } = body;
    const finalContent = content || message;
    const result = await this.chatService.sendMessage(
      req.user.id, 
      parseInt(receiver_id), 
      finalContent,
      file,
      type || 'text'
    );
    return { success: true, data: result };
  }
}
