import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { TokenPayload } from '../auth/token-payload.interface';
import { SyncService } from './sync.service';
import { SyncPushDto } from './dto/sync-push.dto';

@ApiTags('sync')
@ApiBearerAuth()
@Controller('sync')
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('push')
  async push(@CurrentUser() user: TokenPayload, @Body() dto: SyncPushDto) {
    await this.syncService.push(user.sub, dto.changes);
    return { status: 'ok' };
  }

  @Get('pull')
  pull(@CurrentUser() user: TokenPayload, @Query('since') since?: string) {
    return this.syncService.pull(user.sub, since ?? null);
  }
}
