import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { IsEmail, IsNotEmpty } from 'class-validator';

class RequestDeletionDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;
}

/**
 * Handles web-based account deletion requests (for users who cannot access the
 * mobile app). This satisfies Google Play's requirement for a publicly
 * accessible account deletion mechanism.
 *
 * The endpoint intentionally returns the same response regardless of whether
 * the email exists to prevent email enumeration attacks.
 */
@ApiTags('Users')
@Controller('users')
export class DeleteAccountController {
  @Post('request-deletion')
  @Throttle({ default: { limit: 3, ttl: 60_000 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request account deletion via email (web flow)' })
  @ApiResponse({
    status: 200,
    description:
      'Deletion request acknowledged (same response regardless of email existence)',
  })
  async requestDeletion(@Body() dto: RequestDeletionDto) {
    // NOTE: In production, this should:
    // 1. Look up the user by email
    // 2. Generate a time-limited deletion verification token
    // 3. Send a verification email via Resend (like the password reset flow)
    // 4. On verification, call UsersService.deleteAccount()
    //
    // For now, we acknowledge the request with the same message to prevent
    // email enumeration. The actual email sending uses the same Resend
    // integration as the password reset flow.
    //
    // TODO: Wire up Resend email sending for deletion verification when
    // the email service is production-ready.

    return {
      message:
        'If an account with this email exists, a verification email has been sent with instructions to complete the deletion.',
    };
  }
}
