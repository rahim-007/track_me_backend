import { AiService } from './ai.service';
export declare class AiController {
    private readonly aiService;
    constructor(aiService: AiService);
    getInsights(req: any): Promise<any>;
    generateWeeklyReport(req: any): Promise<any>;
}
