import { Injectable, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMissedReasonDto } from './dto/create-missed-reason.dto';

@Injectable()
export class MissedReasonsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Save one or many missed habit reasons in a single transaction.
   * Skips duplicates (same userId + habitId + missedDate) gracefully via upsert.
   */
  async createMany(userId: string, dtos: CreateMissedReasonDto[]) {
    const results = await Promise.all(
      dtos.map((dto) => {
        const missedDate = new Date(dto.missedDate);
        return this.prisma.missedHabitReason.upsert({
          where: {
            userId_habitId_missedDate: {
              userId,
              habitId: dto.habitId,
              missedDate,
            },
          },
          update: { reason: dto.reason },
          create: {
            userId,
            habitId: dto.habitId,
            missedDate,
            reason: dto.reason,
          },
          select: {
            id: true,
            habitId: true,
            missedDate: true,
            reason: true,
            createdAt: true,
          },
        });
      }),
    );
    return results;
  }

  /**
   * Get all missed reasons for a user, optionally filtered by date.
   * Used by AI analytics in future.
   */
  async findAll(userId: string, missedDate?: string) {
    return this.prisma.missedHabitReason.findMany({
      where: {
        userId,
        ...(missedDate ? { missedDate: new Date(missedDate) } : {}),
      },
      select: {
        id: true,
        habitId: true,
        habit: { select: { name: true, emoji: true } },
        missedDate: true,
        reason: true,
        createdAt: true,
      },
      orderBy: { missedDate: 'desc' },
    });
  }

  /**
   * Check if reasons have already been submitted for a given date.
   * Used by the Flutter app to skip showing the popup.
   */
  async hasSubmittedForDate(
    userId: string,
    missedDate: string,
  ): Promise<boolean> {
    const count = await this.prisma.missedHabitReason.count({
      where: { userId, missedDate: new Date(missedDate) },
    });
    return count > 0;
  }
}
