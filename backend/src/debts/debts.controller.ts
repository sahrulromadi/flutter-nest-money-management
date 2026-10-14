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
import { DebtsService } from './debts.service';
import { CreateDebtDto } from './dto/create-debt.dto';
import { UpdateDebtDto } from './dto/update-debt.dto';

@ApiTags('debts')
@ApiBearerAuth()
@Controller('debts')
export class DebtsController {
  constructor(private readonly debtsService: DebtsService) {}

  @Post()
  create(@CurrentUser() user: TokenPayload, @Body() dto: CreateDebtDto) {
    return this.debtsService.create(user.sub, dto);
  }

  @Get()
  findAll(@CurrentUser() user: TokenPayload) {
    return this.debtsService.findAll(user.sub);
  }

  @Get(':id')
  findOne(@CurrentUser() user: TokenPayload, @Param('id') id: string) {
    return this.debtsService.findOne(user.sub, id);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: TokenPayload,
    @Param('id') id: string,
    @Body() dto: UpdateDebtDto,
  ) {
    return this.debtsService.update(user.sub, id, dto);
  }

  @HttpCode(HttpStatus.NO_CONTENT)
  @Delete(':id')
  remove(@CurrentUser() user: TokenPayload, @Param('id') id: string) {
    return this.debtsService.remove(user.sub, id);
  }
}
