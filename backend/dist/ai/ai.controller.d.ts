import { JwtService } from '@nestjs/jwt';
import { AiService } from './ai.service';
import { SuggestionsDto } from './dto/suggestions.dto';
export declare class AiController {
    private aiService;
    private jwtService;
    constructor(aiService: AiService, jwtService: JwtService);
    getSuggestions(authHeader: string | undefined, dto: SuggestionsDto): Promise<{
        playerLevel: number;
        taskConsistency: number;
        activeSkills: string[];
        suggestions: string[];
        levelUpAdvice: string;
        recommendedSkills: string[];
    }>;
}
