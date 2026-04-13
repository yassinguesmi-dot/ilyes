import { Router } from 'express';
import { z } from 'zod';

import { authenticate } from '../middlewares/authenticate';
import { isAdmin } from '../middlewares/isAdmin';
import { validate } from '../middlewares/validate';
import * as productController from '../controllers/product.controller';

const router = Router();

const createSchema = z.object({
  name: z.string().min(2),
  description: z.string().min(10),
  price: z.number().positive(),
  comparePrice: z.number().positive().optional(),
  stock: z.number().int().nonnegative(),
  images: z.array(z.string().url()).optional(),
  specs: z.record(z.unknown()),
  categoryId: z.string().uuid(),
});

const updateSchema = z.object({
  name: z.string().min(2).optional(),
  description: z.string().min(10).optional(),
  price: z.number().positive().optional(),
  comparePrice: z.number().positive().nullable().optional(),
  stock: z.number().int().nonnegative().optional(),
  specs: z.record(z.unknown()).optional(),
  categoryId: z.string().uuid().optional(),
});

router.get('/', productController.list);
router.get('/featured', productController.featured);
router.get('/search', productController.search);
router.get('/:slug', productController.detail);

router.post('/', authenticate, isAdmin, validate({ body: createSchema }), productController.create);
router.put('/:id', authenticate, isAdmin, validate({ body: updateSchema }), productController.update);
router.delete('/:id', authenticate, isAdmin, productController.remove);
router.post(
  '/:id/images',
  authenticate,
  isAdmin,
  productController.uploadImagesMiddleware,
  productController.uploadImages,
);

export default router;
