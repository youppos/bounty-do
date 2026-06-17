import { PrismaService } from '../prisma/prisma.service';
import { SyncTasksDto } from './dto/task.dto';
export declare class TasksService {
    private prisma;
    constructor(prisma: PrismaService);
    getTasks(userId: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        title: string;
        description: string | null;
        isCompleted: boolean;
        hasAlarm: boolean;
        hasReminder: boolean;
        coinReward: number;
        levelIndex: number;
        deadline: Date | null;
        completedAt: Date | null;
        userId: string;
    }[]>;
    syncTasks(userId: string, syncDto: SyncTasksDto): Promise<{
        tasks: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            title: string;
            description: string | null;
            isCompleted: boolean;
            hasAlarm: boolean;
            hasReminder: boolean;
            coinReward: number;
            levelIndex: number;
            deadline: Date | null;
            completedAt: Date | null;
            userId: string;
        }[];
        coins: number;
        level: number;
    }>;
}
