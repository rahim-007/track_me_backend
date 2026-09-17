import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { FcmService } from './fcm.service';

describe('FcmService', () => {
  const createService = (env: Record<string, string | undefined>) => {
    const config = { get: (key: string) => env[key] } as ConfigService;
    return new FcmService(config);
  };

  describe('when FCM is not configured', () => {
    it('sendPush returns success: false without throwing', async () => {
      const service = createService({});
      await expect(
        service.sendPush({ token: 'tok', title: 't', body: 'b' }),
      ).resolves.toEqual({ success: false, isUnregistered: false });
    });

    it('returns success: false when only some vars are present', async () => {
      const service = createService({ FIREBASE_PROJECT_ID: 'p' });
      await expect(
        service.sendPush({ token: 'tok', title: 't', body: 'b' }),
      ).resolves.toEqual({ success: false, isUnregistered: false });
    });

    it('returns success: false for an empty token even when configured', async () => {
      const service = createService({
        FIREBASE_PROJECT_ID: 'p',
        FIREBASE_CLIENT_EMAIL: 'e',
        FIREBASE_PRIVATE_KEY: 'k',
      });
      await expect(
        service.sendPush({ token: '', title: 't', body: 'b' }),
      ).resolves.toEqual({ success: false, isUnregistered: false });
    });
  });
});
