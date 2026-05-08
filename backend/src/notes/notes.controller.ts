import { Controller, Get, Post, Delete, Body, UseGuards, Req } from '@nestjs/common';
import { NotesService } from './notes.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('notes')
@UseGuards(JwtAuthGuard)
export class NotesController {
  constructor(private readonly notesService: NotesService) {}

  @Post()
  async createNote(@Req() req, @Body('content') content: string) {
    const userId = req.user.id;
    const note = await this.notesService.createNote(userId, content);
    return { success: true, data: note };
  }

  @Get()
  async getNotes(@Req() req) {
    const userId = req.user.id;
    const notes = await this.notesService.getNotes(userId);
    return { success: true, data: notes };
  }

  @Delete()
  async deleteNote(@Req() req) {
    const userId = req.user.id;
    await this.notesService.deleteNote(userId);
    return { success: true, message: 'تم حذف الملاحظة بنجاح' };
  }
}
