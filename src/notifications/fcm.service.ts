import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { initializeApp, getApps, getApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

/**
 * Thin wrapper around firebase-admin's FCM (v1) API.
 *
 * Credentials come from the same env vars documented in .env.example:
 *   FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY
 * (the three fields of the service-account JSON downloaded from
 * Firebase Console → Project settings → Service accounts).
 *
 * Initialization is lazy and best-effort: if the vars are missing the service
 * simply logs once and skips sending, so the app works without push configured.
 */
@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);
  private initialized = false;
  private initAttempted = false;

  constructor(private readonly config: ConfigService) {}

  /** Initialize the Firebase Admin app once; never throws. */
  private ensureInitialized(): boolean {
    if (this.initialized) return true;
    if (this.initAttempted) return false;

    this.initAttempted = true;
    const projectId = this.config.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = this.config.get<string>('FIREBASE_CLIENT_EMAIL');
    const privateKey = this.config.get<string>('FIREBASE_PRIVATE_KEY');

    if (!projectId || !clientEmail || !privateKey) {
      this.logger.warn(
        'FCM not configured (missing FIREBASE_PROJECT_ID / FIREBASE_CLIENT_EMAIL / FIREBASE_PRIVATE_KEY) — push notifications disabled.',
      );
      return false;
    }

    try {
      // The private key arrives from .env with literal \n sequences; normalize
      // them so the PEM block is valid.
      const normalizedKey = privateKey.replace(/\n/g, '\n');
      if (getApps().length === 0) {
        initializeApp({
          credential: cert({
            projectId,
            clientEmail,
            privateKey: normalizedKey,
          }),
        });
      } else {
        getApp();
      }
      this.initialized = true;
      this.logger.log('Firebase Admin initialized for FCM');
      return true;
    } catch (e) {
      this.logger.error(`Firebase Admin init failed: ${(e as Error).message}`);
      return false;
    }
  }

  /**
   * Send a push notification to a device token.
   * @returns true if the message was accepted by FCM, false otherwise
   * (including when FCM isn't configured or the token is invalid/revoked).
   */
  async sendPush(params: {
    token: string;
    title: string;
    body: string;
    data?: Record<string, string>;
  }): Promise<boolean> {
    if (!this.ensureInitialized()) return false;
    if (!params.token) return false;

    try {
      const message = {
        token: params.token,
        notification: { title: params.title, body: params.body },
        android: { priority: 'high' as const },
        apns: { payload: { aps: { sound: 'default' } } },
        data: params.data ?? {},
      };
      await getMessaging().send(message);
      return true;
    } catch (e) {
      // UNREGISTERED / INVALID_ARGUMENT means the token is dead — the caller
      // can decide whether to clear it (handled by NotificationsService).
      const err = e as { code?: string; message?: string };
      this.logger.debug(
        `FCM send failed (${err.code ?? 'unknown'}): ${err.message ?? e}`,
      );
      return false;
    }
  }
}
