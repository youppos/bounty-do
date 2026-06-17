import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SyncTasksDto } from './dto/task.dto';

@Injectable()
export class TasksService {
  constructor(private prisma: PrismaService) {}

  async getTasks(userId: string) {
    return this.prisma.task.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async syncTasks(userId: string, syncDto: SyncTasksDto) {
    const { tasks, coins, level } = syncDto;

    // Update user stats if provided
    const updateData: { coins?: number; level?: number } = {};
    if (coins !== undefined) updateData.coins = coins;
    if (level !== undefined) updateData.level = level;

    if (Object.keys(updateData).length > 0) {
      await this.prisma.user.update({
        where: { id: userId },
        data: updateData,
      });
    }

    // Sync tasks
    if (tasks && tasks.length > 0) {
      // Run upserts in a sequential promise pool or transaction
      // SQLite works best with sequential executions to avoid lock/busy states
      for (const task of tasks) {
        await this.prisma.task.upsert({
          where: { id: task.id },
          update: {
            title: task.title,
            description: task.description,
            isCompleted: task.isCompleted,
            hasAlarm: task.hasAlarm,
            hasReminder: task.hasReminder,
            coinReward: task.coinReward,
            levelIndex: task.levelIndex,
            deadline: task.deadline ? new Date(task.deadline) : null,
            completedAt: task.completedAt ? new Date(task.completedAt) : null,
          },
          create: {
            id: task.id,
            title: task.title,
            description: task.description,
            isCompleted: task.isCompleted ?? false,
            hasAlarm: task.hasAlarm ?? false,
            hasReminder: task.hasReminder ?? false,
            coinReward: task.coinReward ?? 0,
            levelIndex: task.levelIndex ?? 1,
            createdAt: new Date(task.createdAt),
            deadline: task.deadline ? new Date(task.deadline) : null,
            completedAt: task.completedAt ? new Date(task.completedAt) : null,
            userId: userId,
          },
        });
      }
    }

    // Retrieve latest state
    const latestTasks = await this.getTasks(userId);
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { coins: true, level: true },
    });

    return {
      tasks: latestTasks,
      coins: user?.coins ?? 0,
      level: user?.level ?? 1,
    };
  }
}
