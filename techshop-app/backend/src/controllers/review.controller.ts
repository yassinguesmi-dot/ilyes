import type { Request, Response } from 'express';
import { asHttpError } from '../utils/httpError';
import * as reviewService from '../services/review.service';

export async function list(req: Request, res: Response): Promise<void> {
  try {
    const items = await reviewService.listReviews(req.params.id as string);
    res.status(200).json({ items });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function create(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }
    const result = await reviewService.addReview(userId, req.params.id as string, req.body as never);
    res.status(201).json(result);
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function remove(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.userId;
    const role = req.user?.role;
    if (!userId || !role) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }
    await reviewService.deleteReview({ userId, role }, req.params.id as string);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}
