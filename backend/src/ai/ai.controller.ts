import { Body, Controller, Headers, Post } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AiService } from './ai.service';
import { SuggestionsDto } from './dto/suggestions.dto';

@Controller('ai')
export class AiController {
  constructor(
    private aiService: AiService,
    private jwtService: JwtService,
  ) {}

  @Post('suggestions')
  async getSuggestions(
    @Headers('authorization') authHeader: string | undefined,
    @Body() dto: SuggestionsDto,
  ) {
    let userId: string | null = null;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const payload: { sub: string; email: string } =
          await this.jwtService.verifyAsync<{ sub: string; email: string }>(
            token,
            {
              secret: 'bounty-do-super-secret-key-change-in-production',
            },
          );
        userId = payload.sub;
      } catch {
        // Silently fall back to unauthenticated if token is invalid or expired
      }
    }

    return this.aiService.getSuggestions(userId, dto);
  }
}
