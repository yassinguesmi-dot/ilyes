import type { Request, Response } from 'express';

import { asHttpError } from '../utils/httpError';
import * as authService from '../services/auth.service';

export async function register(req: Request, res: Response): Promise<void> {
  try {
    const result = await authService.register(req.body as { email: string; password: string; fullName: string; phone?: string });
    res.status(201).json(result);
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function login(req: Request, res: Response): Promise<void> {
  try {
    const result = await authService.login(req.body as { email: string; password: string });
    res.status(200).json(result);
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function refreshToken(req: Request, res: Response): Promise<void> {
  try {
    const tokens = await authService.refreshTokens(req.body as { refreshToken: string });
    res.status(200).json({ tokens });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function logout(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }
    await authService.logout(userId);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function forgotPassword(req: Request, res: Response): Promise<void> {
  try {
    await authService.forgotPassword((req.body as { email: string }).email);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function resetPassword(req: Request, res: Response): Promise<void> {
  try {
    const body = req.body as { token: string; newPassword: string };
    await authService.resetPassword({ token: body.token, newPassword: body.newPassword });
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}
