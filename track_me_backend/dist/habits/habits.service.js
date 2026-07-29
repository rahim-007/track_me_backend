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
exports.HabitsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let HabitsService = class HabitsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(userId) {
        const habits = await this.prisma.habit.findMany({
            where: { userId, isActive: true },
            include: {
                logs: {
                    where: {
                        date: {
                            gte: this.getWeekStart(),
                            lte: this.getWeekEnd(),
                        },
                    },
                    orderBy: { date: 'asc' },
                },
            },
            orderBy: { createdAt: 'asc' },
        });
        return habits.map((habit) => this.formatHabitWithDates(habit));
    }
    async findOne(userId, id) {
        return this.prisma.habit.findFirst({
            where: { id, userId, isActive: true },
            include: {
                logs: {
                    orderBy: { date: 'desc' },
                    take: 30,
                },
            },
        });
    }
    async create(userId, dto) {
        return this.prisma.habit.create({
            data: {
                ...dto,
                userId,
            },
        });
    }
    async update(userId, id, dto) {
        return this.prisma.habit.updateMany({
            where: { id, userId },
            data: dto,
        });
    }
    async remove(userId, id) {
        return this.prisma.habit.updateMany({
            where: { id, userId },
            data: { isActive: false },
        });
    }
    async getStreak(userId, habitId) {
        const logs = await this.prisma.habitLog.findMany({
            where: { habitId, userId, isSkipped: false },
            orderBy: { date: 'desc' },
        });
        let streak = 0;
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        for (let i = 0; i < logs.length; i++) {
            const logDate = new Date(logs[i].date);
            logDate.setHours(0, 0, 0, 0);
            const expectedDate = new Date(today);
            expectedDate.setDate(today.getDate() - i);
            if (logDate.getTime() === expectedDate.getTime()) {
                streak++;
            }
            else {
                break;
            }
        }
        return { currentStreak: streak };
    }
    formatHabitWithDates(habit) {
        const completedDates = habit.logs
            .filter((l) => !l.isSkipped)
            .map((l) => l.date.toISOString().split('T')[0]);
        const skippedDates = habit.logs
            .filter((l) => l.isSkipped)
            .map((l) => l.date.toISOString().split('T')[0]);
        return {
            ...habit,
            completedDates,
            skippedDates,
            logs: undefined,
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
exports.HabitsService = HabitsService;
exports.HabitsService = HabitsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], HabitsService);
//# sourceMappingURL=habits.service.js.map