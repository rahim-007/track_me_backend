import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import * as crypto from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { getJwtRefreshExpiresInDays } from '../common/config/jwt.config';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';

const RESET_TOKEN_TTL_MS = 60 * 60 * 1000; // 1 hour

/** Shape of Google's tokeninfo response (the fields we rely on). */
interface GoogleTokenInfo {
  sub?: string;
  email?: string;
  email_verified?: string | boolean;
  name?: string;
  picture?: string;
  aud?: string;
  azp?: string;
  exp?: string;
  error_description?: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
  ) {}

  /** Emails are stored + matched case-insensitively. */
  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  /**
   * Find a user by email. New accounts are stored lowercased; this also
   * matches accounts created before normalization existed (mixed case).
   */
  private async findUserByEmail(email: string) {
    const normalized = this.normalizeEmail(email);
    const exact = await this.prisma.user.findUnique({
      where: { email: normalized },
    });
    if (exact) return exact;
    return this.prisma.user.findFirst({
      where: { email: { equals: normalized, mode: 'insensitive' } },
    });
  }

  async register(dto: RegisterDto) {
    const email = this.normalizeEmail(dto.email);
    const existing = await this.findUserByEmail(email);

    if (existing) {
      throw new ConflictException('Email already in use');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);

    const user = await this.prisma.user.create({
      data: {
        email,
        name: dto.name,
        passwordHash,
      },
      select: { id: true, email: true, name: true, avatarUrl: true },
    });

    const tokens = await this.generateTokens(user.id, user.email);
    return { user, ...tokens };
  }

  async login(dto: LoginDto) {
    const user = await this.findUserByEmail(dto.email);

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const tokens = await this.generateTokens(user.id, user.email);
    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl,
      },
      ...tokens,
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Google sign-in
  // ───────────────────────────────────────────────────────────────────────────

  /**
   * Verify a Google ID token with Google's tokeninfo endpoint.
   *
   * The client-supplied googleId/email/name are NEVER trusted on their own —
   * this closes the account-takeover hole where an attacker could call
   * /auth/google with any victim email + a made-up googleId.
   */
  private async verifyGoogleIdToken(idToken: string) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10_000);
    try {
      // POST the token in the body: Google's tokeninfo endpoint rejects
      // tokens longer than ~2048 chars when passed as a GET query param.
      const response = await fetch('https://oauth2.googleapis.com/tokeninfo', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: `id_token=${encodeURIComponent(idToken)}`,
        signal: controller.signal,
      });
      if (!response.ok) {
        throw new UnauthorizedException('Invalid Google ID token');
      }
      const claims = (await response.json()) as GoogleTokenInfo;

      if (!claims || claims.error_description) {
        throw new UnauthorizedException('Invalid Google ID token');
      }
      // Google returns email_verified as the string "true" (or absent when
      // unverified); only accept confirmed emails.
      if (String(claims.email_verified) !== 'true' || !claims.email) {
        throw new UnauthorizedException('Google account email is not verified');
      }
      if (!claims.sub) {
        throw new UnauthorizedException('Invalid Google ID token');
      }

      // If the backend is configured with a Google client id, reject tokens
      // minted for a different application.
      const expectedAud = this.config.get<string>('GOOGLE_CLIENT_ID');
      if (expectedAud && claims.aud && claims.aud !== expectedAud) {
        throw new UnauthorizedException(
          'Google token was issued for a different application',
        );
      }

      return claims;
    } catch (e: unknown) {
      if (e instanceof UnauthorizedException) throw e;
      throw new UnauthorizedException('Unable to verify Google ID token');
    } finally {
      clearTimeout(timeout);
    }
  }

  async loginWithGoogle(dto: GoogleAuthDto) {
    if (!dto.id_token) {
      throw new UnauthorizedException('Google ID token is required');
    }

    const claims = await this.verifyGoogleIdToken(dto.id_token);

    // Only data returned by Google's verified token is used for identity.
    if (!claims.sub || !claims.email) {
      throw new UnauthorizedException(
        'Google account is missing required details',
      );
    }
    const googleId = claims.sub;
    const email = this.normalizeEmail(claims.email);
    const name =
      typeof claims.name === 'string' && claims.name.trim().length > 0
        ? claims.name
        : dto.name || 'Google User';
    const avatarUrl =
      typeof claims.picture === 'string' ? claims.picture : dto.avatarUrl;

    let user = await this.prisma.user.findFirst({
      where: { OR: [{ googleId }, { email }] },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: { googleId, email, name, avatarUrl, isEmailVerified: true },
      });
    } else if (!user.googleId) {
      // Verified Google login for an existing email/password account → link it.
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: { googleId, isEmailVerified: true },
      });
    } else if (user.googleId !== googleId) {
      // The email is already linked to a *different* Google account.
      throw new ConflictException(
        'This email is linked to a different Google account',
      );
    }

    const tokens = await this.generateTokens(user.id, user.email);
    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl,
      },
      ...tokens,
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tokens
  // ───────────────────────────────────────────────────────────────────────────

  async refreshToken(token: string) {
    const record = await this.prisma.refreshToken.findUnique({
      where: { token },
      include: { user: true },
    });

    if (!record || record.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    // Rotate: invalidate the old token, issue a fresh pair.
    await this.prisma.refreshToken.delete({ where: { id: record.id } });

    const tokens = await this.generateTokens(record.user.id, record.user.email);
    return tokens;
  }

  async logout(userId: string) {
    await this.prisma.refreshToken.deleteMany({ where: { userId } });
    return { message: 'Logged out successfully' };
  }

  /**
   * Delete expired refresh tokens from the database.
   * Utilizes the @@index([expiresAt]) index on refresh_tokens.
   */
  async cleanupExpiredTokens(): Promise<number> {
    const result = await this.prisma.refreshToken.deleteMany({
      where: {
        expiresAt: { lt: new Date() },
      },
    });
    return result.count;
  }

  private async generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };

    const accessToken = this.jwtService.sign(payload);

    const refreshTokenValue = crypto.randomUUID();
    const refreshDays = getJwtRefreshExpiresInDays(this.config);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + refreshDays);

    await this.prisma.refreshToken.create({
      data: {
        token: refreshTokenValue,
        userId,
        expiresAt,
      },
    });

    return {
      access_token: accessToken,
      refresh_token: refreshTokenValue,
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Password reset
  // ───────────────────────────────────────────────────────────────────────────

  async forgotPassword(email: string) {
    const user = await this.findUserByEmail(email);

    // Always return the same message to avoid email enumeration.
    const successMessage = 'If this email exists, a reset link will be sent.';

    if (!user || !user.passwordHash) {
      return { message: successMessage };
    }

    // Invalidate any previous outstanding tokens for this user.
    await this.prisma.passwordResetToken.deleteMany({
      where: { userId: user.id, usedAt: null },
    });

    const rawToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto
      .createHash('sha256')
      .update(rawToken)
      .digest('hex');

    await this.prisma.passwordResetToken.create({
      data: {
        tokenHash,
        userId: user.id,
        expiresAt: new Date(Date.now() + RESET_TOKEN_TTL_MS),
      },
    });

    await this.sendResetEmail(user.email, user.name, rawToken);

    return { message: successMessage };
  }

  async resetPassword(token: string, newPassword: string) {
    if (!token || !newPassword) {
      throw new BadRequestException('Token and new password are required');
    }
    if (newPassword.length < 8) {
      throw new BadRequestException('Password must be at least 8 characters');
    }

    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    // Atomically consume the token so two concurrent requests with the same
    // token can't both reset the password (last write would win).
    const consumed = await this.prisma.passwordResetToken.updateMany({
      where: { tokenHash, usedAt: null, expiresAt: { gt: new Date() } },
      data: { usedAt: new Date() },
    });

    if (consumed.count === 0) {
      const stale = await this.prisma.passwordResetToken.findUnique({
        where: { tokenHash },
      });
      if (stale && stale.expiresAt < new Date()) {
        throw new BadRequestException('Reset token has expired');
      }
      throw new BadRequestException('Invalid or already-used reset token');
    }

    const record = await this.prisma.passwordResetToken.findUnique({
      where: { tokenHash },
    });
    if (!record) {
      throw new BadRequestException('Invalid reset token');
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);

    await this.prisma.user.update({
      where: { id: record.userId },
      data: { passwordHash },
    });

    // New password means old refresh tokens must die.
    await this.prisma.refreshToken.deleteMany({
      where: { userId: record.userId },
    });

    return { message: 'Password has been reset successfully' };
  }

  private async sendResetEmail(to: string, name: string, rawToken: string) {
    const apiKey = this.config.get<string>('RESEND_API_KEY');
    const baseUrl = this.config.get<string>(
      'FRONTEND_URL',
      'http://localhost:3000',
    );
    const resetUrl = `${baseUrl.replace(/\/$/, '')}/reset-password?token=${rawToken}`;

    if (!apiKey) {
      if (this.config.get<string>('NODE_ENV') === 'production') {
        console.error(
          'RESEND_API_KEY is not configured — password reset emails cannot be sent',
        );
      } else {
        // Dev mode: surface the link so the flow is still testable end-to-end.
        console.log(
          `[dev] Password reset for ${to} (${name ?? 'user'}): ${resetUrl}`,
        );
      }
      return;
    }
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10_000);
    try {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        signal: controller.signal,
        body: JSON.stringify({
          from: this.config.get<string>(
            'RESEND_FROM_EMAIL',
            'UrDay <noreply@urday.app>',
          ),
          to: [to],
          subject: 'Reset your UrDay password',
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
              <h2>Reset your password</h2>
              <p>Hi ${name ?? 'there'},</p>
              <p>We received a request to reset your UrDay password. This link is valid for 1 hour:</p>
              <p><a href="${resetUrl}" style="display:inline-block;padding:12px 20px;background:#4F46E5;color:#fff;text-decoration:none;border-radius:8px;">Reset password</a></p>
              <p>If you didn't request this, you can safely ignore this email.</p>
            </div>
          `,
        }),
      });
      if (!response.ok) {
        console.error(
          `Failed to send reset email via Resend (${response.status}): ${await response.text()}`,
        );
      }
    } catch (e) {
      console.error('Error sending reset email:', e);
    } finally {
      clearTimeout(timeout);
    }
  }
}
