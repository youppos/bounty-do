import { Controller, Get, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt.guard';
import type { RequestWithUser } from '../auth/jwt.guard';
import { AnalyticsService } from './analytics.service';

@Controller('analytics')
@UseGuards(JwtAuthGuard)
export class AnalyticsController {
  constructor(private analyticsService: AnalyticsService) {}

  @Get('monthly')
  async getMonthlyAnalytics(@Request() req: RequestWithUser) {
    const userId = req.user!.sub;
    return this.analyticsService.getMonthlyAnalytics(userId);
  }
}
