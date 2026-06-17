import {
  Body,
  Controller,
  Get,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt.guard';
import type { RequestWithUser } from '../auth/jwt.guard';
import { SyncTasksDto } from './dto/task.dto';
import { TasksService } from './tasks.service';

@Controller('tasks')
@UseGuards(JwtAuthGuard)
export class TasksController {
  constructor(private tasksService: TasksService) {}

  @Get()
  async getTasks(@Request() req: RequestWithUser) {
    const userId = req.user!.sub;
    const tasks = await this.tasksService.getTasks(userId);
    return { tasks };
  }

  @Post()
  async syncTasks(@Request() req: RequestWithUser, @Body() syncDto: SyncTasksDto) {
    const userId = req.user!.sub;
    return this.tasksService.syncTasks(userId, syncDto);
  }
}
