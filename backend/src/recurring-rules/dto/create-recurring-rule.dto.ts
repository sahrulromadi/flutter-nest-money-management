import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

const RULE_TYPES = ['Income', 'Expense'] as const;
const INTERVAL_UNITS = ['Day', 'Week', 'Month'] as const;

export class CreateRecurringRuleDto {
  @ApiProperty()
  @IsUUID()
  accountId!: string;

  @ApiProperty()
  @IsUUID()
  categoryId!: string;

  @ApiProperty({ enum: RULE_TYPES })
  @IsIn(RULE_TYPES)
  type!: (typeof RULE_TYPES)[number];

  @ApiProperty()
  @IsNumber()
  @Min(0.01)
  amount!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  note?: string;

  @ApiProperty({ enum: INTERVAL_UNITS })
  @IsIn(INTERVAL_UNITS)
  intervalUnit!: (typeof INTERVAL_UNITS)[number];

  @ApiProperty()
  @IsInt()
  @Min(1)
  intervalValue!: number;

  @ApiProperty()
  @IsDateString()
  startDate!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  endDate?: string;
}
