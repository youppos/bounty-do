import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ParseSpeechDto } from './dto/parse.dto';
import { VoiceService } from './voice.service';

@Controller('voice')
export class VoiceController {
  constructor(private voiceService: VoiceService) {}

  @Post('parse')
  @HttpCode(HttpStatus.OK)
  parseSpeech(@Body() dto: ParseSpeechDto) {
    return this.voiceService.parseSpeech(dto.text);
  }
}
