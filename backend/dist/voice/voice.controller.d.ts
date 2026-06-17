import { ParseSpeechDto } from './dto/parse.dto';
import { VoiceService } from './voice.service';
export declare class VoiceController {
    private voiceService;
    constructor(voiceService: VoiceService);
    parseSpeech(dto: ParseSpeechDto): {
        title: string;
        levelIndex: number;
        deadline?: undefined;
    } | {
        title: string;
        levelIndex: number | undefined;
        deadline: string | undefined;
    };
}
