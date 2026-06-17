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
exports.AiService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let AiService = class AiService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getSuggestions(userId, dto) {
        let playerLevel = dto.playerLevel;
        let taskConsistency = dto.taskConsistency;
        const activeSkills = dto.activeSkills || [];
        if (userId) {
            const user = await this.prisma.user.findUnique({
                where: { id: userId },
                include: { tasks: true },
            });
            if (user) {
                if (playerLevel === undefined) {
                    playerLevel = user.level;
                }
                if (taskConsistency === undefined) {
                    const recentTasks = user.tasks.filter((t) => {
                        const sevenDaysAgo = new Date();
                        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
                        return t.createdAt >= sevenDaysAgo;
                    });
                    if (recentTasks.length === 0) {
                        taskConsistency = 1.0;
                    }
                    else {
                        const completedCount = recentTasks.filter((t) => t.isCompleted).length;
                        taskConsistency = completedCount / recentTasks.length;
                    }
                }
            }
        }
        playerLevel = playerLevel ?? 1;
        taskConsistency = taskConsistency ?? 0.5;
        const suggestions = [];
        let levelUpAdvice = '';
        const recommendedSkills = [];
        if (playerLevel < 3) {
            levelUpAdvice = `Rookie adventurer (Level ${playerLevel})! Tackle 3 easy (level-1) tasks daily to establish a steady routine and rank up.`;
        }
        else if (playerLevel < 10) {
            levelUpAdvice = `Awakened Warrior (Level ${playerLevel})! Elevate your productivity. Complete medium (level-2) and hard (level-3) tasks to earn larger coin bounties!`;
        }
        else {
            levelUpAdvice = `Master Gamer (Level ${playerLevel})! Your daily task limit is high (${Math.min(3 + (playerLevel - 1), 20)} tasks). Automate your routine for optimal efficiency.`;
        }
        const pct = Math.round(taskConsistency * 100);
        if (taskConsistency < 0.4) {
            suggestions.push(`Warning: Your weekly task completion rate is only ${pct}%. Divide larger items into sub-tasks and prioritize high-value tasks first.`);
            suggestions.push(`Consider activating 'Shield of Discipline' to prevent coin penalties on overdue tasks.`);
            recommendedSkills.push('Shield of Discipline');
        }
        else if (taskConsistency < 0.7) {
            suggestions.push(`Your completion rate is a decent ${pct}%. Keep it up! Try to bundle similar tasks together to boost focus and efficiency.`);
            suggestions.push(`A quick use of the 'Time Sandglass' can extend your deadlines, giving you breathing room to finish active tasks.`);
            recommendedSkills.push('Time Sandglass');
        }
        else {
            suggestions.push(`Outstanding! You have a stellar ${pct}% completion rate. You are in deep flow state.`);
            suggestions.push(`Now is the best time to purchase 'Midas Touch' to double your coin rewards on upcoming completions!`);
            recommendedSkills.push('Midas Touch');
        }
        if (activeSkills.length === 0) {
            suggestions.push('No active buffs detected. Activating shop skills will help you manage task stress and optimize your coin gain.');
        }
        else {
            if (activeSkills.includes('Midas Touch')) {
                suggestions.push('Midas Touch is active! Complete your highest coin-yielding tasks next to maximize your double-gold earnings.');
            }
            if (activeSkills.includes('Shield of Discipline')) {
                suggestions.push('Shield of Discipline is active! Your coins are protected from late penalties, so take your time and deliver high quality.');
            }
            if (activeSkills.includes('Time Sandglass')) {
                suggestions.push('Time Sandglass has extended your deadlines. Use this extra window to clear out any lingering complex tasks.');
            }
        }
        suggestions.push(`Tip: Feeling lucky? Spend 50 coins on the Jackpot Wheel. You stand a chance to win up to 300 coins!`);
        return {
            playerLevel,
            taskConsistency,
            activeSkills,
            suggestions,
            levelUpAdvice,
            recommendedSkills,
        };
    }
};
exports.AiService = AiService;
exports.AiService = AiService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AiService);
//# sourceMappingURL=ai.service.js.map