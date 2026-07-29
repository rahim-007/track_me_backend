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
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const prisma_service_1 = require("../prisma/prisma.service");
let AiService = class AiService {
    prisma;
    config;
    apiKey;
    constructor(prisma, config) {
        this.prisma = prisma;
        this.config = config;
        this.apiKey = config.get('GEMINI_API_KEY', '');
    }
    async getInsights(userId) {
        const [habitStats, goals] = await Promise.all([
            this.getHabitStats(userId),
            this.prisma.goal.findMany({
                where: { userId, status: 'IN_PROGRESS' },
                orderBy: { targetDate: 'asc' },
            }),
        ]);
        if (this.apiKey) {
            try {
                return await this.callGeminiApi(habitStats, goals);
            }
            catch (e) {
                console.error('Gemini API error, using fallback:', e);
            }
        }
        return this.generateFallbackInsights(habitStats);
    }
    async generateWeeklyReport(userId) {
        const habitStats = await this.getHabitStats(userId);
        const report = await this.callGeminiApi(habitStats, []);
        const weekStart = this.getWeekStart();
        const weekEnd = this.getWeekEnd();
        await this.prisma.aiReport.upsert({
            where: {
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
    async callGeminiApi(habitStats, goals) {
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
        const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${this.apiKey}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: {
                    temperature: 0.7,
                    maxOutputTokens: 1000,
                },
            }),
        });
        const data = await response.json();
        const text = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '{}';
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        return JSON.parse(jsonMatch?.[0] ?? '{}');
    }
    generateFallbackInsights(habitStats) {
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
    async getHabitStats(userId) {
        const weekStart = this.getWeekStart();
        const weekEnd = this.getWeekEnd();
        const [totalHabits, completedLogs, skippedLogs] = await Promise.all([
            this.prisma.habit.count({ where: { userId, isActive: true } }),
            this.prisma.habitLog.count({
                where: { userId, isSkipped: false, date: { gte: weekStart, lte: weekEnd } },
            }),
            this.prisma.habitLog.count({
                where: { userId, isSkipped: true, date: { gte: weekStart, lte: weekEnd } },
            }),
        ]);
        const possibleCompletions = totalHabits * 7;
        const completionRate = possibleCompletions > 0
            ? Math.round((completedLogs / possibleCompletions) * 100)
            : 0;
        return {
            totalHabits,
            completedThisWeek: completedLogs,
            skippedThisWeek: skippedLogs,
            completionRate,
        };
    }
    getWeekStart() {
        const d = new Date();
        const day = d.getDay();
        const diff = d.getDate() - day + (day === 0 ? -6 : 1);
        return new Date(d.setDate(diff));
    }
    getWeekEnd() {
        const start = this.getWeekStart();
        start.setDate(start.getDate() + 6);
        return start;
    }
};
exports.AiService = AiService;
exports.AiService = AiService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        config_1.ConfigService])
], AiService);
//# sourceMappingURL=ai.service.js.map