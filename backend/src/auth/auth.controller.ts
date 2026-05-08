import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  async register(@Body() body: any) {
    const result = await this.authService.register(body);
    return { success: true, data: result };
  }

  @Post('login')
  async login(@Body() body: any) {
    const { login_id, password } = body;
    const result = await this.authService.login(login_id, password);
    return { success: true, data: result };
  }

  @Post('update_profile')
  @UseGuards(JwtAuthGuard)
  async updateProfile(@Req() req: any, @Body() body: any) {
    body.user_id = req.user.id.toString();
    const result = await this.authService.updateProfile(body);
    return { success: true, data: result };
  }

  @Post('update_profile_v2')
  @UseGuards(JwtAuthGuard)
  async updateProfileV2(@Req() req: any, @Body() body: any) {
    body.user_id = req.user.id.toString();
    const result = await this.authService.updateProfileV2(body);
    return { success: true, data: result };
  }

}
