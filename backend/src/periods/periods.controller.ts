import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { TokenPayload } from '../auth/token-payload.interface';
import { PeriodsService } from './periods.service';
import { CreatePeriodDto } from './dto/create-period.dto';

@ApiTags('periods')
@ApiBearerAuth()
@Controller('periods')
export class PeriodsController {
  constructor(private readonly periodsService: PeriodsService) {}

  @Post()
  create(@CurrentUser() user: TokenPayload, @Body() dto: CreatePeriodDto) {
    return this.periodsService.startNewPeriod(user.sub, dto.startedAt);
  }

  @Get()
  findAll(@CurrentUser() user: TokenPayload) {
    return this.periodsService.findAll(user.sub);
  }

  @Get('active')
  findActive(@CurrentUser() user: TokenPayload) {
    return this.periodsService.findActive(user.sub);
  }
}
