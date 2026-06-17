import { IsNotEmpty, IsString } from 'class-validator';

export class ParseSpeechDto {
  @IsString()
  @IsNotEmpty({ message: 'Speech text is required' })
  text: string;
}
