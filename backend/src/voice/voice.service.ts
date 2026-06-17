import { Injectable } from '@nestjs/common';

@Injectable()
export class VoiceService {
  parseSpeech(text: string) {
    if (!text) {
      return { title: 'New Task', levelIndex: 1 };
    }

    const originalText = text;
    let cleanText = text;

    // 1. Level Index Parsing (0 to 4)
    // Matches "level [1-5]", "等级 [1-5]", "priority [1-5]", "优先级 [1-5]", "重要度 [1-5]"
    let levelIndex: number | undefined = undefined;

    const levelRegex =
      /(?:level|priority|等级|优先级|重要度|重要性|重要级别)\s*([1-5])/i;
    const levelMatch = cleanText.match(levelRegex);
    if (levelMatch) {
      levelIndex = parseInt(levelMatch[1], 10) - 1;
      cleanText = cleanText.replace(levelRegex, '');
    } else {
      // Keyword based level detection
      const legendaryKeywords = [
        'legendary',
        'epic',
        '传奇',
        '极其重要',
        '非常紧急',
        '星标',
        '五星',
      ];
      const epicKeywords = [
        'important',
        'high priority',
        '重要',
        '史诗',
        '紧急',
        '高优先级',
      ];
      const hardKeywords = ['hard', 'difficulty', '困难', '挑战'];
      const normalKeywords = [
        'normal',
        'medium',
        'medium priority',
        '普通',
        '一般',
        '中等',
      ];
      const easyKeywords = ['easy', 'simple', '简单', '低优先级', '随便'];

      const checkKeywords = (keywords: string[]) => {
        return keywords.some((kw) => originalText.toLowerCase().includes(kw));
      };

      if (checkKeywords(legendaryKeywords)) levelIndex = 4;
      else if (checkKeywords(epicKeywords)) levelIndex = 3;
      else if (checkKeywords(hardKeywords)) levelIndex = 2;
      else if (checkKeywords(normalKeywords)) levelIndex = 1;
      else if (checkKeywords(easyKeywords)) levelIndex = 0;
    }

    // 2. Deadline Date & Time Parsing
    let deadlineDate: Date | null = null;
    const now = new Date();

    // Check for days: today, tomorrow, day after tomorrow
    const todayRegex = /(?:today|今天)/i;
    const tomorrowRegex = /(?:tomorrow|明天)/i;
    const dayAfterTomorrowRegex = /(?:day after tomorrow|后天)/i;

    let dateFound = false;

    if (dayAfterTomorrowRegex.test(cleanText)) {
      deadlineDate = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate() + 2,
      );
      cleanText = cleanText.replace(dayAfterTomorrowRegex, '');
      dateFound = true;
    } else if (tomorrowRegex.test(cleanText)) {
      deadlineDate = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate() + 1,
      );
      cleanText = cleanText.replace(tomorrowRegex, '');
      dateFound = true;
    } else if (todayRegex.test(cleanText)) {
      deadlineDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      cleanText = cleanText.replace(todayRegex, '');
      dateFound = true;
    }

    // Check for relative day offsets: "in 3 days", "3天后"
    const inDaysRegex = /(?:in\s+)?(\d+)\s*(?:days|天)(?:后)?/i;
    const inDaysMatch = cleanText.match(inDaysRegex);
    if (inDaysMatch && !dateFound) {
      const daysOffset = parseInt(inDaysMatch[1], 10);
      deadlineDate = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate() + daysOffset,
      );
      cleanText = cleanText.replace(inDaysRegex, '');
      dateFound = true;
    }

    // Check for day of the week (e.g. Monday, Tuesday, Friday, 周一, 星期五)
    const weekDaysEng = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
    ];
    const weekDaysZh = [
      '周日',
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
      '星期日',
      '星期一',
      '星期二',
      '星期三',
      '星期四',
      '星期五',
      '星期六',
    ];

    let weekDayIndex = -1;

    // Search English weekdays
    for (let i = 0; i < weekDaysEng.length; i++) {
      const regex = new RegExp(`\\b${weekDaysEng[i]}\\b`, 'i');
      if (regex.test(cleanText)) {
        weekDayIndex = i;
        cleanText = cleanText.replace(regex, '');
        break;
      }
    }

    // Search Chinese weekdays
    if (weekDayIndex === -1) {
      for (let i = 0; i < weekDaysZh.length; i++) {
        const regex = new RegExp(weekDaysZh[i]);
        if (regex.test(cleanText)) {
          weekDayIndex = i % 7;
          cleanText = cleanText.replace(regex, '');
          break;
        }
      }
    }

    if (weekDayIndex !== -1 && !dateFound) {
      const currentDay = now.getDay();
      let daysToAdd = weekDayIndex - currentDay;
      if (daysToAdd <= 0) {
        daysToAdd += 7; // Next week's occurrence
      }
      deadlineDate = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate() + daysToAdd,
      );
      dateFound = true;
    }

    // Time Parsing
    let hour = 18; // Default to 6:00 PM if date is set but no time
    let minute = 0;
    let timeFound = false;

    // Matches: "10:30", "15:00", "08:15", "10点30", "8点半"
    const timeFullRegex =
      /(\d{1,2})[:：](\d{2})|(\d{1,2})\s*(?:点|点钟|hour)\s*(\d{2})?(?:分)?/i;
    const timeFullMatch = cleanText.match(timeFullRegex);

    // Matches: "8点半", "eight thirty" (approx), "半"
    const halfHourRegex = /(\d{1,2})\s*点半/i;
    const halfHourMatch = cleanText.match(halfHourRegex);

    if (halfHourMatch) {
      hour = parseInt(halfHourMatch[1], 10);
      minute = 30;
      cleanText = cleanText.replace(halfHourRegex, '');
      timeFound = true;
    } else if (timeFullMatch) {
      const hStr = timeFullMatch[1] || timeFullMatch[3];
      const mStr = timeFullMatch[2] || timeFullMatch[4];
      hour = parseInt(hStr, 10);
      minute = mStr ? parseInt(mStr, 10) : 0;
      cleanText = cleanText.replace(timeFullRegex, '');
      timeFound = true;
    }

    // Matches simple hour mention: "at 9" or "9点"
    if (!timeFound) {
      const simpleHourRegex = /(?:\b(?:at|by)\s+)?(\d{1,2})\s*(?:点|o'clock)/i;
      const simpleHourMatch = cleanText.match(simpleHourRegex);
      if (simpleHourMatch) {
        hour = parseInt(simpleHourMatch[1], 10);
        cleanText = cleanText.replace(simpleHourRegex, '');
        timeFound = true;
      }
    }

    // Matches PM/AM/下午/早上/晚上
    const pmRegex = /(?:pm|下午|晚上|晚上|夜里|evening|night)/i;
    const amRegex = /(?:am|早上|上午|早晨|morning)/i;

    const isPm = pmRegex.test(cleanText);
    const isAm = amRegex.test(cleanText);

    if (isPm) {
      if (hour < 12) hour += 12;
      cleanText = cleanText.replace(pmRegex, '');
    } else if (isAm) {
      if (hour === 12) hour = 0;
      cleanText = cleanText.replace(amRegex, '');
    }

    // If a time was specified but no date, assume today (or tomorrow if the time has already passed today)
    if (timeFound && !dateFound) {
      deadlineDate = new Date();
      if (
        hour < now.getHours() ||
        (hour === now.getHours() && minute <= now.getMinutes())
      ) {
        // Time has already passed today, assume tomorrow
        deadlineDate.setDate(deadlineDate.getDate() + 1);
      }
    }

    // 3. Assemble Deadline
    let deadlineStr: string | undefined = undefined;
    if (deadlineDate) {
      deadlineDate.setHours(hour, minute, 0, 0);
      deadlineStr = deadlineDate.toISOString();
    }

    // 4. Title Cleansing
    // Remove punctuation, filler words, action words
    const actionWords = [
      /^\s*(?:remind me to|please add|add task|add|i need to|remember to|todo)\s+/i,
      /^\s*(?:提醒我|请添加|添加任务|添加|记得要|记得|我要|待办|准备)\s*/,
      /\s*(?:at|by|on|for|in|的|在|于)\s*$/i, // Trailing prepositions
    ];

    actionWords.forEach((wordRegex) => {
      cleanText = cleanText.replace(wordRegex, '');
    });

    let title = cleanText
      .replace(/[.,/#!$%^&*;:{}=\-_~()？，。！]/g, '')
      .replace(/\s+/g, ' ')
      .trim();

    // Capitalize first letter of title (if English)
    if (title.length > 0 && /^[a-zA-Z]/.test(title)) {
      title = title.charAt(0).toUpperCase() + title.slice(1);
    }

    // Final fallback if the title is empty after parsing
    if (!title) {
      title =
        originalText.length > 30
          ? originalText.slice(0, 27) + '...'
          : originalText;
    }

    return {
      title,
      levelIndex,
      deadline: deadlineStr,
    };
  }
}
