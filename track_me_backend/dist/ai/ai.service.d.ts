import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
export declare class AiService {
    private readonly prisma;
    private readonly config;
    private readonly apiKey;
    constructor(prisma: PrismaService, config: ConfigService);
    getInsights(userId: string): Promise<any>;
    generateWeeklyReport(userId: string): Promise<any>;
    private callGeminiApi;
    private generateFallbackInsights;
    private getHabitStats;
    private getWeekStart;
    private getWeekEnd;
}
