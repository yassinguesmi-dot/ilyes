import { Router } from 'express';
import { z } from 'zod';

import { authenticate } from '../middlewares/authenticate';
import { isAdmin } from '../middlewares/isAdmin';
import { validate } from '../middlewares/validate';
import * as categoryController from '../controllers/category.controller';

const router = Router();

const createSchema = z.object({
  name: z.string().min(2),
  slug: z.string().min(1).optional(),
  icon: z.string().min(1),
  parentId: z.string().uuid().nullable().optional(),
});

const updateSchema = z.object({
  name: z.string().min(2).optional(),
  slug: z.string().min(1).optional(),
  icon: z.string().min(1).optional(),
  parentId: z.string().uuid().nullable().optional(),
});

router.get('/', categoryController.list);
router.post('/', authenticate, isAdmin, validate({ body: createSchema }), categoryController.create);
router.put('/:id', authenticate, isAdmin, validate({ body: updateSchema }), categoryController.update);
router.delete('/:id', authenticate, isAdmin, categoryController.remove);

export default router;
