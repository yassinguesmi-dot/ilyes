import type { Request, Response } from 'express';
import { asHttpError } from '../utils/httpError';
import * as paymentService from '../services/payment.service';

export async function createSession(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }
    const { orderId } = req.body as { orderId: string };
    const result = await paymentService.createStripeCheckoutSession(userId, orderId);
    res.status(200).json(result);
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function webhook(req: Request, res: Response): Promise<void> {
  try {
    const signature = req.header('stripe-signature');
    const rawBody = req.body as Buffer;
    await paymentService.handleStripeWebhook(rawBody, signature);
    res.status(200).json({ received: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}
