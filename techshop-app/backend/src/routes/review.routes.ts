import { Router } from 'express';
import { z } from 'zod';

import { authenticate } from '../middlewares/authenticate';
import { validate } from '../middlewares/validate';
import * as reviewController from '../controllers/review.controller';

const router = Router();

const createSchema = z.object({
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(1000).optional(),
});

router.get('/products/:id/reviews', reviewController.list);
router.post('/products/:id/reviews', authenticate, validate({ body: createSchema }), reviewController.create);
router.delete('/reviews/:id', authenticate, reviewController.remove);

export default router;
