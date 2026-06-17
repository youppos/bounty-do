"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TasksService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let TasksService = class TasksService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getTasks(userId) {
        return this.prisma.task.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
    }
    async syncTasks(userId, syncDto) {
        const { tasks, coins, level } = syncDto;
        const updateData = {};
        if (coins !== undefined)
            updateData.coins = coins;
        if (level !== undefined)
            updateData.level = level;
        if (Object.keys(updateData).length > 0) {
            await this.prisma.user.update({
                where: { id: userId },
                data: updateData,
            });
        }
        if (tasks && tasks.length > 0) {
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
};
exports.TasksService = TasksService;
exports.TasksService = TasksService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], TasksService);
//# sourceMappingURL=tasks.service.js.map