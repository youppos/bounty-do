export declare class TaskDto {
    id: string;
    title: string;
    description?: string;
    isCompleted?: boolean;
    hasAlarm?: boolean;
    hasReminder?: boolean;
    coinReward?: number;
    levelIndex?: number;
    createdAt: string;
    deadline?: string;
    completedAt?: string;
}
export declare class SyncTasksDto {
    tasks?: TaskDto[];
    coins?: number;
    level?: number;
}
