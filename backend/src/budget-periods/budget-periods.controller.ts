import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { TokenPayload } from '../auth/token-payload.interface';
import { BudgetPeriodsService } from './budget-periods.service';
import { CreateBudgetPeriodDto } from './dto/create-budget-period.dto';

@ApiTags('budget-periods')
@ApiBearerAuth()
@Controller('budget-periods')
export class BudgetPeriodsController {
  constructor(private readonly budgetPeriodsService: BudgetPeriodsService) {}

  @Post()
  create(
    @CurrentUser() user: TokenPayload,
    @Body() dto: CreateBudgetPeriodDto,
  ) {
    return this.budgetPeriodsService.startNewPeriod(user.sub, dto.startedAt);
  }

  @Get()
  findAll(@CurrentUser() user: TokenPayload) {
    return this.budgetPeriodsService.findAll(user.sub);
  }

  @Get('active')
  findActive(@CurrentUser() user: TokenPayload) {
    return this.budgetPeriodsService.findActive(user.sub);
  }
}
