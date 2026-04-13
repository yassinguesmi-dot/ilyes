import express, { Router } from 'express';
import { z } from 'zod';

import { authenticate } from '../middlewares/authenticate';
import { validate } from '../middlewares/validate';
import * as paymentController from '../controllers/payment.controller';

const router = Router();

const createSessionSchema = z.object({
  orderId: z.string().uuid(),
});

router.post('/create-session', authenticate, validate({ body: createSessionSchema }), paymentController.createSession);

router.post('/webhook', express.raw({ type: 'application/json' }), paymentController.webhook);

export default router;
