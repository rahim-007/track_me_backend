import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Request, Response } from 'express';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  /**
   * Translate common Prisma errors into meaningful HTTP responses instead of
   * leaking a 500 (and the raw driver error) to the client.
   */
  private mapPrismaError(exception: unknown): {
    status: HttpStatus;
    message: string;
  } | null {
    if (!(exception instanceof Prisma.PrismaClientKnownRequestError)) {
      return null;
    }
    switch (exception.code) {
      case 'P2002': // Unique constraint failed
        return {
          status: HttpStatus.CONFLICT,
          message: 'A record with this value already exists',
        };
      case 'P2025': // Record not found
        return {
          status: HttpStatus.NOT_FOUND,
          message: 'The requested record was not found',
        };
      case 'P2003': // Foreign key constraint failed
      case 'P2014': // Relation violation
      case 'P2000': // Value too long
      case 'P2007': // Data validation error
      case 'P2011': // Null constraint violation
        return {
          status: HttpStatus.BAD_REQUEST,
          message: 'Invalid request data',
        };
      default:
        return null;
    }
  }

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const prismaError = this.mapPrismaError(exception);

    const status = prismaError
      ? prismaError.status
      : exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    let message = prismaError?.message ?? 'Internal server error';
    let errors: string[] | undefined;

    if (exception instanceof HttpException) {
      const exResponse = exception.getResponse();
      if (typeof exResponse === 'string') {
        message = exResponse;
      } else if (typeof exResponse === 'object' && exResponse !== null) {
        const res = exResponse as any;
        message = res.message ?? message;
        if (Array.isArray(res.message)) {
          errors = res.message;
          message = 'Validation failed';
        }
      }
    }

    this.logger.error(
      `${request.method} ${request.url} → ${status}: ${message}`,
    );

    response.status(status).json({
      success: false,
      statusCode: status,
      message,
      errors,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
