"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateHabitDto = void 0;
const swagger_1 = require("@nestjs/swagger");
const create_habit_dto_1 = require("./create-habit.dto");
class UpdateHabitDto extends (0, swagger_1.PartialType)(create_habit_dto_1.CreateHabitDto) {
}
exports.UpdateHabitDto = UpdateHabitDto;
//# sourceMappingURL=update-habit.dto.js.map