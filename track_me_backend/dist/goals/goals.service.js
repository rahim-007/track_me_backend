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
exports.GoalsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let GoalsService = class GoalsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(userId) {
        return this.prisma.goal.findMany({
            where: { userId },
            orderBy: [{ status: 'asc' }, { targetDate: 'asc' }],
        });
    }
    async findOne(userId, id) {
        return this.prisma.goal.findFirst({
            where: { id, userId },
            include: {
                progressHistory: { orderBy: { recordedAt: 'desc' }, take: 10 },
            },
        });
    }
    async create(userId, dto) {
        return this.prisma.goal.create({
            data: { ...dto, userId },
        });
    }
    async update(userId, id, dto) {
        return this.prisma.goal.updateMany({
            where: { id, userId },
            data: dto,
        });
    }
    async updateProgress(userId, id, progress, notes) {
        const goal = await this.prisma.goal.updateMany({
            where: { id, userId },
            data: {
                progress,
                status: progress >= 1.0 ? 'COMPLETED' : 'IN_PROGRESS',
            },
        });
        await this.prisma.goalProgress.create({
            data: { goalId: id, progress, notes },
        });
        return goal;
    }
    async remove(userId, id) {
        return this.prisma.goal.deleteMany({ where: { id, userId } });
    }
};
exports.GoalsService = GoalsService;
exports.GoalsService = GoalsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], GoalsService);
//# sourceMappingURL=goals.service.js.map