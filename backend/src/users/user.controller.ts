import { Controller, Get, Post, Body, Query, UseGuards, Req } from '@nestjs/common';
import { UserService } from './user.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UserController {
  constructor(private userService: UserService) {}

  @Get('get_user_profile')
  async getUserProfile(@Req() req: any, @Query('profile_id') profile_id: string) {
    const result = await this.userService.getUserProfile(profile_id, req.user.id.toString());
    return { success: true, data: result };
  }

  @Post('toggle_follow')
  async toggleFollow(@Req() req: any, @Body() body: any) {
    const { profile_id } = body;
    const result = await this.userService.toggleFollow(req.user.id.toString(), profile_id);
    return { success: true, ...result };
  }

  @Get('search_users')
  async searchUsers(@Req() req: any, @Query('q') q: string) {
    const result = await this.userService.searchUsers(q, req.user.id.toString());
    return { success: true, data: result };
  }

  @Get('get_suggested_users')
  async getSuggestedUsers(@Req() req: any) {
    const result = await this.userService.getSuggestedUsers(req.user.id.toString());
    return { success: true, data: result };
  }

  @Get('get_user_stats')
  async getUserStats(@Req() req: any) {
    const result = await this.userService.getUserStats(req.user.id.toString());
    return { success: true, data: result };
  }

  @Get('get_notifications')
  async getNotifications(@Req() req: any) {
    const result = await this.userService.getNotifications(req.user.id.toString());
    return { success: true, data: result };
  }

  @Post('mark_notification_read')
  async markNotificationRead(@Req() req: any, @Body() body: any) {
    const { notification_id } = body;
    const result = await this.userService.markNotificationRead(
      req.user.id.toString(),
      notification_id,
    );
    return result;
  }

  @Post('mark_all_notifications_read')
  async markAllNotificationsRead(@Req() req: any) {
    const result = await this.userService.markAllNotificationsRead(req.user.id.toString());
    return result;
  }

  @Post('change_password')
  async changePassword(@Req() req: any, @Body() body: any) {
    try {
      const { currentPassword, newPassword } = body;
      const result = await this.userService.changePassword(
        req.user.id.toString(),
        currentPassword,
        newPassword
      );
      return result;
    } catch (e: any) {
      return { success: false, message: e.message };
    }
  }
}
