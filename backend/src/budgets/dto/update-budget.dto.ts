import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, Min } from 'class-validator';

export class UpdateBudgetDto {
  @ApiProperty()
  @IsNumber()
  @Min(0.01)
  limitAmount!: number;
}
