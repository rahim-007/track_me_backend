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
exports.HabitLogsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let HabitLogsService = class HabitLogsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async completeHabit(userId, habitId, date) {
        const parsedDate = new Date(date);
        const existing = await this.prisma.habitLog.findUnique({
            where: { habitId_date: { habitId, date: parsedDate } },
        });
        if (existing && !existing.isSkipped) {
            throw new common_1.ConflictException('Habit already completed for this date');
        }
        const log = await this.prisma.habitLog.upsert({
            where: { habitId_date: { habitId, date: parsedDate } },
            update: {
                isSkipped: false,
                skipReason: null,
                completedAt: new Date(),
            },
            create: {
                habitId,
                userId,
                date: parsedDate,
                completedAt: new Date(),
                isSkipped: false,
            },
        });
        await this.prisma.habit.update({
            where: { id: habitId },
            data: { totalCompleted: { increment: 1 } },
        });
        return log;
    }
    async skipHabit(userId, habitId, date, reason) {
        const parsedDate = new Date(date);
        return this.prisma.habitLog.upsert({
            where: { habitId_date: { habitId, date: parsedDate } },
            update: {
                isSkipped: true,
                skipReason: reason,
                completedAt: null,
            },
            create: {
                habitId,
                userId,
                date: parsedDate,
                isSkipped: true,
                skipReason: reason,
            },
        });
    }
    async uncomplete(userId, habitId, date) {
        const parsedDate = new Date(date);
        return this.prisma.habitLog.deleteMany({
            where: { habitId, userId, date: parsedDate },
        });
    }
    async getWeeklyStats(userId) {
        const weekStart = this.getWeekStart();
        const weekEnd = this.getWeekEnd();
        const [total, completed, skipped] = await Promise.all([
            this.prisma.habit.count({ where: { userId, isActive: true } }),
            this.prisma.habitLog.count({
                where: { userId, isSkipped: false, date: { gte: weekStart, lte: weekEnd } },
            }),
            this.prisma.habitLog.count({
                where: { userId, isSkipped: true, date: { gte: weekStart, lte: weekEnd } },
            }),
        ]);
        return {
            totalHabits: total,
            completedThisWeek: completed,
            skippedThisWeek: skipped,
            completionRate: total > 0 ? Math.round((completed / (total * 7)) * 100) : 0,
        };
    }
    getWeekStart() {
        const d = new Date();
        const day = d.getDay();
        const diff = d.getDate() - day + (day === 0 ? -6 : 1);
        const monday = new Date(d.setDate(diff));
        monday.setHours(0, 0, 0, 0);
        return monday;
    }
    getWeekEnd() {
        const start = this.getWeekStart();
        const end = new Date(start);
        end.setDate(start.getDate() + 6);
        end.setHours(23, 59, 59, 999);
        return end;
    }
};
exports.HabitLogsService = HabitLogsService;
exports.HabitLogsService = HabitLogsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], HabitLogsService);
//# sourceMappingURL=habit-logs.service.js.map