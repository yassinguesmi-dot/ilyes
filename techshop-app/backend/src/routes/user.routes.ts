import { Router } from 'express';
import { z } from 'zod';

import { authenticate } from '../middlewares/authenticate';
import { validate } from '../middlewares/validate';
import * as userController from '../controllers/user.controller';

const router = Router();

const updateMeSchema = z.object({
  fullName: z.string().min(2).optional(),
  phone: z.string().min(6).nullable().optional(),
});

const createAddressSchema = z.object({
  label: z.string().min(1),
  street: z.string().min(1),
  city: z.string().min(1),
  postalCode: z.string().min(1),
  isDefault: z.boolean().optional(),
});

const updateAddressSchema = z.object({
  label: z.string().min(1).optional(),
  street: z.string().min(1).optional(),
  city: z.string().min(1).optional(),
  postalCode: z.string().min(1).optional(),
  isDefault: z.boolean().optional(),
});

router.get('/me', authenticate, userController.me);
router.put('/me', authenticate, validate({ body: updateMeSchema }), userController.updateMe);

router.get('/me/wishlist', authenticate, userController.wishlist);
router.post('/me/wishlist/:productId', authenticate, userController.addWishlist);
router.delete('/me/wishlist/:productId', authenticate, userController.removeWishlist);

router.get('/me/addresses', authenticate, userController.addresses);
router.post('/me/addresses', authenticate, validate({ body: createAddressSchema }), userController.createAddress);
router.put('/me/addresses/:id', authenticate, validate({ body: updateAddressSchema }), userController.updateAddress);
router.delete('/me/addresses/:id', authenticate, userController.deleteAddress);

export default router;
