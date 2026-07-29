"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateGoalDto = void 0;
const swagger_1 = require("@nestjs/swagger");
const create_goal_dto_1 = require("./create-goal.dto");
class UpdateGoalDto extends (0, swagger_1.PartialType)(create_goal_dto_1.CreateGoalDto) {
}
exports.UpdateGoalDto = UpdateGoalDto;
//# sourceMappingURL=update-goal.dto.js.map