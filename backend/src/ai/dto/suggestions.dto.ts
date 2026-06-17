import {
  IsArray,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class SuggestionsDto {
  @IsNumber()
  @Min(1)
  @IsOptional()
  playerLevel?: number;

  @IsNumber()
  @Min(0)
  @Max(1)
  @IsOptional()
  taskConsistency?: number;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  activeSkills?: string[];
}
