import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsNumber, IsString, Min, MinLength } from 'class-validator';

const ACCOUNT_TYPES = ['Bank', 'Ewallet', 'Cash'] as const;

export class CreateAccountDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  name!: string;

  @ApiProperty({ enum: ACCOUNT_TYPES })
  @IsIn(ACCOUNT_TYPES)
  type!: (typeof ACCOUNT_TYPES)[number];

  @ApiProperty()
  @IsNumber()
  @Min(0)
  initialBalance!: number;
}
