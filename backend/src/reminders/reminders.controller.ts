import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { TokenPayload } from '../auth/token-payload.interface';
import { RemindersService } from './reminders.service';

@ApiTags('reminders')
@ApiBearerAuth()
@Controller('reminders')
export class RemindersController {
  constructor(private readonly remindersService: RemindersService) {}

  @Get('upcoming-bills')
  upcomingBills(
    @CurrentUser() user: TokenPayload,
    @Query('withinDays') withinDays?: string,
  ) {
    const days = withinDays ? Number(withinDays) : 3;
    return this.remindersService.upcomingBills(user.sub, days);
  }

  @Get('daily-check')
  dailyCheck(@CurrentUser() user: TokenPayload) {
    return this.remindersService.dailyCheck(user.sub);
  }
}
