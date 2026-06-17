import { PrismaService } from '../prisma/prisma.service';
import { SuggestionsDto } from './dto/suggestions.dto';
export declare class AiService {
    private prisma;
    constructor(prisma: PrismaService);
    getSuggestions(userId: string | null, dto: SuggestionsDto): Promise<{
        playerLevel: number;
        taskConsistency: number;
        activeSkills: string[];
        suggestions: string[];
        levelUpAdvice: string;
        recommendedSkills: string[];
    }>;
}
