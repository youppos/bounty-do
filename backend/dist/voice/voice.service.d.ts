export declare class VoiceService {
    parseSpeech(text: string): {
        title: string;
        levelIndex: number;
        deadline?: undefined;
    } | {
        title: string;
        levelIndex: number | undefined;
        deadline: string | undefined;
    };
}
