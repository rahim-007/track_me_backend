"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.HabitLogsModule = void 0;
const common_1 = require("@nestjs/common");
const habit_logs_controller_1 = require("./habit-logs.controller");
const habit_logs_service_1 = require("./habit-logs.service");
let HabitLogsModule = class HabitLogsModule {
};
exports.HabitLogsModule = HabitLogsModule;
exports.HabitLogsModule = HabitLogsModule = __decorate([
    (0, common_1.Module)({
        controllers: [habit_logs_controller_1.HabitLogsController],
        providers: [habit_logs_service_1.HabitLogsService],
    })
], HabitLogsModule);
//# sourceMappingURL=habit-logs.module.js.map