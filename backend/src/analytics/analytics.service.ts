import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AnalyticsService {
  constructor(private prisma: PrismaService) {}

  async getMonthlyAnalytics(userId: string) {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(
      now.getFullYear(),
      now.getMonth() + 1,
      0,
      23,
      59,
      59,
      999,
    );

    // Fetch tasks created or completed in the current month
    const tasks = await this.prisma.task.findMany({
      where: {
        userId,
        OR: [
          {
            createdAt: {
              gte: startOfMonth,
              lte: endOfMonth,
            },
          },
          {
            completedAt: {
              gte: startOfMonth,
              lte: endOfMonth,
            },
          },
        ],
      },
    });

    const totalCreatedInMonth = tasks.filter(
      (t) => t.createdAt >= startOfMonth && t.createdAt <= endOfMonth,
    ).length;

    const completedInMonth = tasks.filter(
      (t) =>
        t.isCompleted &&
        t.completedAt &&
        t.completedAt >= startOfMonth &&
        t.completedAt <= endOfMonth,
    );
    const totalCompletedInMonth = completedInMonth.length;

    // Completion Rate
    const completionRate =
      totalCreatedInMonth > 0 ? totalCompletedInMonth / totalCreatedInMonth : 0;

    // Priority Distribution (levelIndex: 0 to 4)
    const priorityDistribution = {
      level_0: 0, // Low
      level_1: 0, // Medium
      level_2: 0, // High
      level_3: 0, // Epic
      level_4: 0, // Legendary
    };

    // Human-readable labels
    const priorityLabels = {
      low: 0,
      medium: 0,
      high: 0,
      epic: 0,
      legendary: 0,
    };

    tasks.forEach((task) => {
      const lvl = task.levelIndex;
      if (lvl === 0) {
        priorityDistribution.level_0++;
        priorityLabels.low++;
      } else if (lvl === 1) {
        priorityDistribution.level_1++;
        priorityLabels.medium++;
      } else if (lvl === 2) {
        priorityDistribution.level_2++;
        priorityLabels.high++;
      } else if (lvl === 3) {
        priorityDistribution.level_3++;
        priorityLabels.epic++;
      } else if (lvl === 4) {
        priorityDistribution.level_4++;
        priorityLabels.legendary++;
      }
    });

    // Coins Earned
    const coinsEarned = completedInMonth.reduce(
      (sum, task) => sum + task.coinReward,
      0,
    );

    // On-Time vs Overdue completion count
    let completedOnTime = 0;
    let completedOverdue = 0;

    completedInMonth.forEach((t) => {
      if (t.deadline && t.completedAt) {
        if (new Date(t.completedAt) > new Date(t.deadline)) {
          completedOverdue++;
        } else {
          completedOnTime++;
        }
      } else {
        // No deadline means it's on time by default
        completedOnTime++;
      }
    });

    // Daily Completion Trend (for rendering charts)
    const daysInMonth = endOfMonth.getDate();
    const dailyTrend: { [key: number]: number } = {};
    for (let i = 1; i <= daysInMonth; i++) {
      dailyTrend[i] = 0;
    }

    completedInMonth.forEach((t) => {
      if (t.completedAt) {
        const completedDay = new Date(t.completedAt).getDate();
        if (dailyTrend[completedDay] !== undefined) {
          dailyTrend[completedDay]++;
        }
      }
    });

    const dailyTrendArray = Object.keys(dailyTrend).map((day) => ({
      day: parseInt(day, 10),
      count: dailyTrend[parseInt(day, 10)],
    }));

    // Fetch user details for current level/coins
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { coins: true, level: true },
    });

    return {
      month: now.toLocaleString('default', { month: 'long' }),
      year: now.getFullYear(),
      totalCreated: totalCreatedInMonth,
      totalCompleted: totalCompletedInMonth,
      completionRate: parseFloat(completionRate.toFixed(2)),
      coinsEarned,
      completedOnTime,
      completedOverdue,
      priorityDistribution,
      priorityLabels,
      dailyTrend: dailyTrendArray,
      userLevel: user?.level ?? 1,
      totalCoins: user?.coins ?? 0,
    };
  }
}
