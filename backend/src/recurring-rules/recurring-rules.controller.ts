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
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { TokenPayload } from '../auth/token-payload.interface';
import { RecurringRulesService } from './recurring-rules.service';
import { CreateRecurringRuleDto } from './dto/create-recurring-rule.dto';
import { UpdateRecurringRuleDto } from './dto/update-recurring-rule.dto';

@ApiTags('recurring-rules')
@ApiBearerAuth()
@Controller('recurring-rules')
export class RecurringRulesController {
  constructor(
    private readonly recurringRulesService: RecurringRulesService,
  ) {}

  @Post()
  create(
    @CurrentUser() user: TokenPayload,
    @Body() dto: CreateRecurringRuleDto,
  ) {
    return this.recurringRulesService.create(user.sub, dto);
  }

  @Get()
  findAll(@CurrentUser() user: TokenPayload) {
    return this.recurringRulesService.findAll(user.sub);
  }

  @Get(':id')
  findOne(@CurrentUser() user: TokenPayload, @Param('id') id: string) {
    return this.recurringRulesService.findOne(user.sub, id);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: TokenPayload,
    @Param('id') id: string,
    @Body() dto: UpdateRecurringRuleDto,
  ) {
    return this.recurringRulesService.update(user.sub, id, dto);
  }

  @HttpCode(HttpStatus.NO_CONTENT)
  @Delete(':id')
  remove(@CurrentUser() user: TokenPayload, @Param('id') id: string) {
    return this.recurringRulesService.remove(user.sub, id);
  }
}
