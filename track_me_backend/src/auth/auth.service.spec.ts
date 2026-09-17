import {
  UnauthorizedException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import * as bcrypt from 'bcryptjs';

describe('AuthService', () => {
  let service: AuthService;
  let prisma: any;
  let jwtService: any;
  let config: any;

  beforeEach(() => {
    prisma = {
      user: {
        findUnique: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      refreshToken: {
        findUnique: jest.fn(),
        create: jest.fn(),
        delete: jest.fn(),
        deleteMany: jest.fn(),
      },
      passwordResetToken: {
        findUnique: jest.fn(),
        create: jest.fn(),
        deleteMany: jest.fn(),
        updateMany: jest.fn(),
      },
    };

    jwtService = {
      sign: jest.fn().mockReturnValue('jwt-access-token'),
    };

    config = {
      get: jest.fn((key: string, defaultVal?: any) => {
        if (key === 'JWT_REFRESH_EXPIRES_IN_DAYS') return 7;
        return defaultVal;
      }),
    };

    service = new AuthService(prisma, jwtService, config);
  });

  describe('cleanupExpiredTokens', () => {
    it('deletes tokens where expiresAt is less than current date and returns count', async () => {
      prisma.refreshToken.deleteMany.mockResolvedValue({ count: 5 });

      const result = await service.cleanupExpiredTokens();

      expect(prisma.refreshToken.deleteMany).toHaveBeenCalledWith({
        where: {
          expiresAt: { lt: expect.any(Date) },
        },
      });
      expect(result).toBe(5);
    });
  });

  describe('refreshToken', () => {
    it('rotates valid refresh token and returns fresh token pair', async () => {
      const futureDate = new Date(Date.now() + 1000 * 60 * 60);
      prisma.refreshToken.findUnique.mockResolvedValue({
        id: 'rt-1',
        token: 'old-token',
        expiresAt: futureDate,
        user: { id: 'u1', email: 'user@example.com' },
      });
      prisma.refreshToken.delete.mockResolvedValue({});
      prisma.refreshToken.create.mockResolvedValue({});

      const tokens = await service.refreshToken('old-token');

      expect(prisma.refreshToken.delete).toHaveBeenCalledWith({
        where: { id: 'rt-1' },
      });
      expect(tokens.access_token).toBe('jwt-access-token');
      expect(tokens.refresh_token).toBeDefined();
    });

    it('throws UnauthorizedException if refresh token is expired', async () => {
      const pastDate = new Date(Date.now() - 1000 * 60);
      prisma.refreshToken.findUnique.mockResolvedValue({
        id: 'rt-1',
        token: 'expired-token',
        expiresAt: pastDate,
        user: { id: 'u1', email: 'user@example.com' },
      });

      await expect(service.refreshToken('expired-token')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('throws UnauthorizedException if refresh token does not exist', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue(null);

      await expect(service.refreshToken('non-existent')).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });

  describe('logout', () => {
    it('deletes all refresh tokens for the user', async () => {
      prisma.refreshToken.deleteMany.mockResolvedValue({ count: 2 });

      const result = await service.logout('u1');

      expect(prisma.refreshToken.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'u1' },
      });
      expect(result).toEqual({ message: 'Logged out successfully' });
    });
  });

  describe('register', () => {
    it('creates new user and returns tokens', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.findFirst.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue({
        id: 'u1',
        email: 'test@example.com',
        name: 'Test',
        avatarUrl: null,
      });
      prisma.refreshToken.create.mockResolvedValue({});

      const result = await service.register({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test',
      });

      expect(prisma.user.create).toHaveBeenCalled();
      expect(result.user.email).toBe('test@example.com');
      expect(result.access_token).toBe('jwt-access-token');
    });

    it('throws ConflictException if email already registered', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'u1',
        email: 'test@example.com',
      });

      await expect(
        service.register({
          email: 'test@example.com',
          password: 'password123',
          name: 'Test',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('login', () => {
    it('authenticates valid credentials and returns tokens', async () => {
      const passwordHash = await bcrypt.hash('secret123', 4);
      prisma.user.findUnique.mockResolvedValue({
        id: 'u1',
        email: 'test@example.com',
        name: 'Test',
        avatarUrl: null,
        passwordHash,
      });
      prisma.refreshToken.create.mockResolvedValue({});

      const result = await service.login({
        email: 'test@example.com',
        password: 'secret123',
      });

      expect(result.user.id).toBe('u1');
      expect(result.access_token).toBe('jwt-access-token');
    });

    it('throws UnauthorizedException on invalid password', async () => {
      const passwordHash = await bcrypt.hash('secret123', 4);
      prisma.user.findUnique.mockResolvedValue({
        id: 'u1',
        email: 'test@example.com',
        passwordHash,
      });

      await expect(
        service.login({
          email: 'test@example.com',
          password: 'wrongpassword',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });
});
