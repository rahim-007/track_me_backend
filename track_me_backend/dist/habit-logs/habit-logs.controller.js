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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.HabitLogsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const habit_logs_service_1 = require("./habit-logs.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
let HabitLogsController = class HabitLogsController {
    habitLogsService;
    constructor(habitLogsService) {
        this.habitLogsService = habitLogsService;
    }
    complete(req, dto) {
        return this.habitLogsService.completeHabit(req.user.id, dto.habitId, dto.date);
    }
    skip(req, dto) {
        return this.habitLogsService.skipHabit(req.user.id, dto.habitId, dto.date, dto.reason);
    }
    uncomplete(req, habitId, date) {
        return this.habitLogsService.uncomplete(req.user.id, habitId, date);
    }
    getWeeklyStats(req) {
        return this.habitLogsService.getWeeklyStats(req.user.id);
    }
};
exports.HabitLogsController = HabitLogsController;
__decorate([
    (0, common_1.Post)(),
    (0, swagger_1.ApiOperation)({ summary: 'Mark habit as complete for a date' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], HabitLogsController.prototype, "complete", null);
__decorate([
    (0, common_1.Post)('skip'),
    (0, swagger_1.ApiOperation)({ summary: 'Skip a habit with reason' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], HabitLogsController.prototype, "skip", null);
__decorate([
    (0, common_1.Delete)(':habitId/:date'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Uncomplete a habit for a date' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('habitId')),
    __param(2, (0, common_1.Param)('date')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], HabitLogsController.prototype, "uncomplete", null);
__decorate([
    (0, common_1.Get)('weekly-stats'),
    (0, swagger_1.ApiOperation)({ summary: 'Get weekly habit statistics' }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], HabitLogsController.prototype, "getWeeklyStats", null);
exports.HabitLogsController = HabitLogsController = __decorate([
    (0, swagger_1.ApiTags)('Habit Logs'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('JWT-auth'),
    (0, common_1.Controller)('habit-logs'),
    __metadata("design:paramtypes", [habit_logs_service_1.HabitLogsService])
], HabitLogsController);
//# sourceMappingURL=habit-logs.controller.js.map