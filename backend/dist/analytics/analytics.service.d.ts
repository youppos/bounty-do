import { PrismaService } from '../prisma/prisma.service';
export declare class AnalyticsService {
    private prisma;
    constructor(prisma: PrismaService);
    getMonthlyAnalytics(userId: string): Promise<{
        month: string;
        year: number;
        totalCreated: number;
        totalCompleted: number;
        completionRate: number;
        coinsEarned: number;
        completedOnTime: number;
        completedOverdue: number;
        priorityDistribution: {
            level_0: number;
            level_1: number;
            level_2: number;
            level_3: number;
            level_4: number;
        };
        priorityLabels: {
            low: number;
            medium: number;
            high: number;
            epic: number;
            legendary: number;
        };
        dailyTrend: {
            day: number;
            count: number;
        }[];
        userLevel: number;
        totalCoins: number;
    }>;
}
