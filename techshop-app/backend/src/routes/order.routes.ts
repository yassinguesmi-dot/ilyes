import { Router } from 'express';
import { z } from 'zod';

import { authenticate } from '../middlewares/authenticate';
import { isAdmin } from '../middlewares/isAdmin';
import { validate } from '../middlewares/validate';
import * as orderController from '../controllers/order.controller';

const router = Router();

const createSchema = z.object({
  items: z
    .array(
      z.object({
        productId: z.string().uuid(),
        quantity: z.number().int().positive(),
      }),
    )
    .min(1),
  addressId: z.string().uuid(),
  paymentMethod: z.enum(['CARD', 'CASH_ON_DELIVERY', 'BANK_TRANSFER']),
  notes: z.string().max(500).optional(),
});

const updateStatusSchema = z.object({
  status: z.enum(['PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED']),
});

router.get('/', authenticate, orderController.myOrders);
router.get('/admin/all', authenticate, isAdmin, orderController.adminAll);
router.put('/:id/status', authenticate, isAdmin, validate({ body: updateStatusSchema }), orderController.adminUpdateStatus);
router.get('/:id', authenticate, orderController.myOrderDetail);
router.post('/', authenticate, validate({ body: createSchema }), orderController.create);
router.put('/:id/cancel', authenticate, orderController.cancel);

export default router;
