import type { RequestWithUser } from '../auth/jwt.guard';
import { SyncTasksDto } from './dto/task.dto';
import { TasksService } from './tasks.service';
export declare class TasksController {
    private tasksService;
    constructor(tasksService: TasksService);
    getTasks(req: RequestWithUser): Promise<{
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
    }>;
    syncTasks(req: RequestWithUser, syncDto: SyncTasksDto): Promise<{
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
