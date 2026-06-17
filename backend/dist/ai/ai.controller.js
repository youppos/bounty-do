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
exports.AiController = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const ai_service_1 = require("./ai.service");
const suggestions_dto_1 = require("./dto/suggestions.dto");
let AiController = class AiController {
    aiService;
    jwtService;
    constructor(aiService, jwtService) {
        this.aiService = aiService;
        this.jwtService = jwtService;
    }
    async getSuggestions(authHeader, dto) {
        let userId = null;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.split(' ')[1];
            try {
                const payload = await this.jwtService.verifyAsync(token, {
                    secret: 'bounty-do-super-secret-key-change-in-production',
                });
                userId = payload.sub;
            }
            catch {
            }
        }
        return this.aiService.getSuggestions(userId, dto);
    }
};
exports.AiController = AiController;
__decorate([
    (0, common_1.Post)('suggestions'),
    __param(0, (0, common_1.Headers)('authorization')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, suggestions_dto_1.SuggestionsDto]),
    __metadata("design:returntype", Promise)
], AiController.prototype, "getSuggestions", null);
exports.AiController = AiController = __decorate([
    (0, common_1.Controller)('ai'),
    __metadata("design:paramtypes", [ai_service_1.AiService,
        jwt_1.JwtService])
], AiController);
//# sourceMappingURL=ai.controller.js.map