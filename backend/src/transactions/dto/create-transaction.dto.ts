import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateIf,
} from 'class-validator';

const TRANSACTION_TYPES = ['Income', 'Expense', 'Transfer'] as const;

export class CreateTransactionDto {
  @ApiProperty()
  @IsUUID()
  accountId!: string;

  @ApiProperty({ enum: TRANSACTION_TYPES })
  @IsIn(TRANSACTION_TYPES)
  type!: (typeof TRANSACTION_TYPES)[number];

  @ApiProperty()
  @IsNumber()
  @Min(0.01)
  amount!: number;

  @ApiProperty()
  @IsDateString()
  occurredAt!: string;

  @ApiPropertyOptional({ description: 'Wajib diisi kalau type bukan Transfer' })
  @ValidateIf((o: CreateTransactionDto) => o.type !== 'Transfer')
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional({ description: 'Wajib diisi kalau type = Transfer' })
  @ValidateIf((o: CreateTransactionDto) => o.type === 'Transfer')
  @IsUUID()
  transferToAccountId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  note?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  goalId?: string;
}
