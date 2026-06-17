import {
  IsBoolean,
  IsDateString,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class TaskDto {
  @IsString()
  @IsNotEmpty()
  id: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsBoolean()
  @IsOptional()
  isCompleted?: boolean;

  @IsBoolean()
  @IsOptional()
  hasAlarm?: boolean;

  @IsBoolean()
  @IsOptional()
  hasReminder?: boolean;

  @IsInt()
  @IsOptional()
  coinReward?: number;

  @IsInt()
  @Min(0)
  @Max(4)
  @IsOptional()
  levelIndex?: number;

  @IsDateString()
  @IsNotEmpty()
  createdAt: string;

  @IsDateString()
  @IsOptional()
  deadline?: string;

  @IsDateString()
  @IsOptional()
  completedAt?: string;
}

export class SyncTasksDto {
  @IsOptional()
  tasks?: TaskDto[];

  @IsInt()
  @Min(0)
  @IsOptional()
  coins?: number;

  @IsInt()
  @Min(1)
  @IsOptional()
  level?: number;
}
