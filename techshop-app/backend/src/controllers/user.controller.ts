import type { Request, Response } from 'express';
import { asHttpError } from '../utils/httpError';
import * as userService from '../services/user.service';

function requireUserId(req: Request, res: Response): string | null {
  const userId = req.user?.userId;
  if (!userId) {
    res.status(401).json({ message: 'Unauthorized' });
    return null;
  }
  return userId;
}

export async function me(req: Request, res: Response): Promise<void> {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;
    const user = await userService.getMe(userId);
    res.status(200).json({ user });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function updateMe(req: Request, res: Response): Promise<void> {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;
    await userService.updateMe(userId, req.body as never);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function wishlist(req: Request, res: Response): Promise<void> {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;
    const items = await userService.listWishlist(userId);
    res.status(200).json({ items });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function addWishlist(req: Request, res: Response): Promise<void> {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;
    await userService.addToWishlist(userId, req.params.productId as string);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function removeWishlist(req: Request, res: Response): Promise<void> {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;
    await userService.removeFromWishlist(userId, req.params.productId as string);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function addresses(req: Request, res: Response): Promise<void> {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;
    const items = await userService.listAddresses(userId);
    res.status(200).json({ items });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function createAddress(req: Request, res: Response): Promise<void> {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;
    const result = await userService.createAddress(userId, req.body as never);
    res.status(201).json(result);
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function updateAddress(req: Request, res: Response): Promise<void> {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;
    await userService.updateAddress(userId, req.params.id as string, req.body as never);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function deleteAddress(req: Request, res: Response): Promise<void> {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;
    await userService.deleteAddress(userId, req.params.id as string);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}
