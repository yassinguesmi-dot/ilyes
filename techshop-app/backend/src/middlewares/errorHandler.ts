import type { NextFunction, Request, Response } from 'express';
import { Prisma } from '@prisma/client';
import { ZodError } from 'zod';

function isErrorWithMessage(err: unknown): err is { message: string } {
  return typeof err === 'object' && err !== null && 'message' in err && typeof (err as { message?: unknown }).message === 'string';
}

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction): void {
  if (err instanceof ZodError) {
    res.status(400).json({ message: 'Validation error', issues: err.issues });
    return;
  }

  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2002') {
      res.status(409).json({ message: 'Unique constraint violation' });
      return;
    }

    res.status(400).json({ message: 'Database error', code: err.code });
    return;
  }

  if (isErrorWithMessage(err)) {
    res.status(500).json({ message: err.message });
    return;
  }

  res.status(500).json({ message: 'Unexpected server error' });
}
