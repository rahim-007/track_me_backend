import { ConfigService } from '@nestjs/config';

/**
 * Single source of truth for the JWT secret.
 *
 * Both the signer (AuthModule) and the verifier (JwtStrategy) must use this
 * exact function — previously they fell back to *different* hardcoded strings
 * ('secret' vs 'fallback-secret'), which made every token fail verification
 * whenever JWT_SECRET was missing from the environment.
 *
 * In production the secret is mandatory; the app refuses to boot without it.
 */
export function getJwtSecret(config: ConfigService): string {
  const secret = config.get<string>('JWT_SECRET');
  if (secret && secret.trim().length > 0) {
    return secret.trim();
  }
  if (config.get<string>('NODE_ENV') === 'production') {
    throw new Error(
      'JWT_SECRET is not set. Refusing to boot in production without a JWT secret.',
    );
  }
  return 'dev-only-insecure-secret-change-me';
}

/** Access-token lifetime (default 15 minutes). */
export function getJwtExpiresIn(config: ConfigService): string {
  return config.get<string>('JWT_EXPIRES_IN', '15m');
}

/** Refresh-token lifetime in days (default 30). */
export function getJwtRefreshExpiresInDays(config: ConfigService): number {
  const raw = config.get<string>('JWT_REFRESH_EXPIRES_IN', '30');
  const days = Number.parseInt(raw, 10);
  return Number.isFinite(days) && days > 0 ? days : 30;
}
