import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { TokenPayload } from '../auth/token-payload.interface';
import { BudgetsService } from './budgets.service';
import { CreateBudgetDto } from './dto/create-budget.dto';
import { UpdateBudgetDto } from './dto/update-budget.dto';

@ApiTags('budgets')
@ApiBearerAuth()
@Controller('budgets')
export class BudgetsController {
  constructor(private readonly budgetsService: BudgetsService) {}

  @Post()
  create(
    @CurrentUser() user: TokenPayload,
    @Query('periodId') periodId: string | undefined,
    @Body() dto: CreateBudgetDto,
  ) {
    return this.budgetsService.create(user.sub, periodId, dto);
  }

  @Get()
  findAll(
    @CurrentUser() user: TokenPayload,
    @Query('periodId') periodId?: string,
  ) {
    return this.budgetsService.findAll(user.sub, periodId);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: TokenPayload,
    @Query('periodId') periodId: string | undefined,
    @Param('id') id: string,
    @Body() dto: UpdateBudgetDto,
  ) {
    return this.budgetsService.update(user.sub, periodId, id, dto);
  }

  @HttpCode(HttpStatus.NO_CONTENT)
  @Delete(':id')
  remove(
    @CurrentUser() user: TokenPayload,
    @Query('periodId') periodId: string | undefined,
    @Param('id') id: string,
  ) {
    return this.budgetsService.remove(user.sub, periodId, id);
  }
}
