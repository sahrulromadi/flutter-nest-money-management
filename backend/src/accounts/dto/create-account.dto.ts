import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsString, Min, MinLength } from 'class-validator';

export class CreateAccountDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  name!: string;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  initialBalance!: number;
}
