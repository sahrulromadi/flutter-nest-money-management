import { ApiProperty } from '@nestjs/swagger';
import { IsDateString } from 'class-validator';

export class CreateBudgetPeriodDto {
  @ApiProperty({ description: 'Tanggal mulai periode baru (gajian cair)' })
  @IsDateString()
  startedAt!: string;
}
