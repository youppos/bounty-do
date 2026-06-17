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
exports.AnalyticsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let AnalyticsService = class AnalyticsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getMonthlyAnalytics(userId) {
        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
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
        const totalCreatedInMonth = tasks.filter((t) => t.createdAt >= startOfMonth && t.createdAt <= endOfMonth).length;
        const completedInMonth = tasks.filter((t) => t.isCompleted &&
            t.completedAt &&
            t.completedAt >= startOfMonth &&
            t.completedAt <= endOfMonth);
        const totalCompletedInMonth = completedInMonth.length;
        const completionRate = totalCreatedInMonth > 0 ? totalCompletedInMonth / totalCreatedInMonth : 0;
        const priorityDistribution = {
            level_0: 0,
            level_1: 0,
            level_2: 0,
            level_3: 0,
            level_4: 0,
        };
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
            }
            else if (lvl === 1) {
                priorityDistribution.level_1++;
                priorityLabels.medium++;
            }
            else if (lvl === 2) {
                priorityDistribution.level_2++;
                priorityLabels.high++;
            }
            else if (lvl === 3) {
                priorityDistribution.level_3++;
                priorityLabels.epic++;
            }
            else if (lvl === 4) {
                priorityDistribution.level_4++;
                priorityLabels.legendary++;
            }
        });
        const coinsEarned = completedInMonth.reduce((sum, task) => sum + task.coinReward, 0);
        let completedOnTime = 0;
        let completedOverdue = 0;
        completedInMonth.forEach((t) => {
            if (t.deadline && t.completedAt) {
                if (new Date(t.completedAt) > new Date(t.deadline)) {
                    completedOverdue++;
                }
                else {
                    completedOnTime++;
                }
            }
            else {
                completedOnTime++;
            }
        });
        const daysInMonth = endOfMonth.getDate();
        const dailyTrend = {};
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
};
exports.AnalyticsService = AnalyticsService;
exports.AnalyticsService = AnalyticsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AnalyticsService);
//# sourceMappingURL=analytics.service.js.map