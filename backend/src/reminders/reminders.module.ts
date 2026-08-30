import { Module } from '@nestjs/common';
import { RemindersController } from './reminders.controller';
import { RemindersService } from './reminders.service';
import { RemindersRepository } from './reminders.repository';

@Module({
  controllers: [RemindersController],
  providers: [RemindersService, RemindersRepository],
})
export class RemindersModule {}
