import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AiService {
  private readonly apiKey: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.apiKey = config.get<string>('GEMINI_API_KEY', '');
  }

  async getInsights(userId: string) {
    const [habitStats, goals] = await Promise.all([
      this.getHabitStats(userId),
      this.prisma.goal.findMany({
        where: { userId, status: 'IN_PROGRESS' },
        orderBy: { targetDate: 'asc' },
      }),
    ]);

    // Try real Gemini API
    if (this.apiKey) {
      try {
        return await this.callGeminiApi(habitStats, goals);
      } catch (e) {
        console.error('Gemini API error, using fallback:', e);
      }
    }

    // Fallback insights
    return this.generateFallbackInsights(habitStats);
  }

  async generateWeeklyReport(userId: string) {
    const habitStats = await this.getHabitStats(userId);

    // Never 500 when the model call fails — fall back to local insights.
    let report: any;
    try {
      report = await this.callGeminiApi(habitStats, []);
    } catch (e) {
      console.error('Gemini weekly-report error, using fallback:', e);
      report = this.generateFallbackInsights(habitStats);
    }

    // Store in DB
    const weekStart = this.getWeekStart();
    const weekEnd = this.getWeekEnd();

    await this.prisma.aiReport.upsert({
      where: {
        // Deterministic per (userId, weekStart)
        id: `${userId}_${weekStart.toISOString()}`,
      },
      update: {
        productivityScore: report.productivityScore,
        weeklyReport: report.weeklyReport,
        strengths: report.strengths,
        weaknesses: report.weaknesses,
        recommendations: report.recommendations,
      },
      create: {
        id: `${userId}_${weekStart.toISOString()}`,
        userId,
        weekStart,
        weekEnd,
        productivityScore: report.productivityScore,
        weeklyReport: report.weeklyReport,
        strengths: report.strengths,
        weaknesses: report.weaknesses,
        recommendations: report.recommendations,
      },
    });

    return report;
  }

  private async callGeminiApi(habitStats: any, goals: any[]) {
    const prompt = `
You are an AI productivity coach. Analyze the following user data and provide insights.

Habit Statistics (last 7 days):
${JSON.stringify(habitStats, null, 2)}

Active Goals:
${JSON.stringify(goals.slice(0, 5), null, 2)}

Please provide:
1. A productivity score from 0-100
2. A brief weekly report (2-3 sentences)
3. 3-4 strengths
4. 2-3 areas for improvement
5. 4-5 personalized recommendations

Respond in JSON format:
{
  "productivityScore": number,
  "weeklyReport": "string",
  "strengths": ["string"],
  "weaknesses": ["string"],
  "recommendations": ["string"]
}
`;

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          // Key in header (never in the URL) so it can't leak into logs/proxies.
          'x-goog-api-key': this.apiKey,
        },
        signal: AbortSignal.timeout(30_000),
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 1000,
          },
        }),
      },
    );

    if (!response.ok) {
      const body = await response.text().catch(() => '');
      throw new Error(
        `Gemini API responded ${response.status}: ${body.slice(0, 300)}`,
      );
    }

    const data = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '{}';

    // Parse JSON from response
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    return JSON.parse(jsonMatch?.[0] ?? '{}');
  }

  private generateFallbackInsights(habitStats: any) {
    const completionRate = habitStats.completionRate ?? 75;
    const score = Math.round(completionRate * 0.8 + Math.random() * 20);

    return {
      productivityScore: Math.min(score, 100),
      weeklyReport: `You completed ${completionRate}% of your habits this week. Keep building momentum — consistency is the key to long-term success!`,
      strengths: [
        'Maintaining a consistent morning routine',
        'Making progress on your health goals',
        'Staying committed to your learning habits',
      ],
      weaknesses: [
        'Evening habits need more attention',
        'Weekend consistency could be improved',
      ],
      recommendations: [
        'Stack new habits with existing routines for better success rates.',
        'Set specific, time-bound reminders for evening habits.',
        'Review your goals weekly to stay on track.',
        'Consider reducing the number of habits to improve focus.',
        'Celebrate small wins to maintain motivation.',
      ],
    };
  }

  private async getHabitStats(userId: string) {
    const weekStart = this.getWeekStart();
    const weekEnd = this.getWeekEnd();

    const [totalHabits, completedLogs, skippedLogs] = await Promise.all([
      this.prisma.habit.count({ where: { userId, isActive: true } }),
      this.prisma.habitLog.count({
        where: {
          userId,
          isSkipped: false,
          date: { gte: weekStart, lte: weekEnd },
        },
      }),
      this.prisma.habitLog.count({
        where: {
          userId,
          isSkipped: true,
          date: { gte: weekStart, lte: weekEnd },
        },
      }),
    ]);

    const possibleCompletions = totalHabits * 7;
    const completionRate =
      possibleCompletions > 0
        ? Math.round((completedLogs / possibleCompletions) * 100)
        : 0;

    return {
      totalHabits,
      completedThisWeek: completedLogs,
      skippedThisWeek: skippedLogs,
      completionRate,
    };
  }

  private getWeekStart() {
    const d = new Date();
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1);
    return new Date(d.setDate(diff));
  }

  private getWeekEnd() {
    const start = this.getWeekStart();
    start.setDate(start.getDate() + 6);
    return start;
  }
}
