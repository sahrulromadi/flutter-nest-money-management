import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from 'class-validator';

export class CreateDebtDto {
  @ApiProperty({ enum: ['Utang', 'Piutang'] })
  @IsIn(['Utang', 'Piutang'])
  direction!: 'Utang' | 'Piutang';

  @ApiProperty()
  @IsString()
  @MinLength(1)
  counterparty!: string;

  @ApiProperty()
  @IsNumber()
  @Min(0.01)
  amount!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  note?: string;
}
