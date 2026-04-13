import type { Request, Response } from 'express';
import { OrderStatus } from '@prisma/client';
import { asHttpError } from '../utils/httpError';
import * as orderService from '../services/order.service';

export async function myOrders(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }
    const items = await orderService.listMyOrders(userId);
    res.status(200).json({ items });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function myOrderDetail(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }
    const order = await orderService.getMyOrder(userId, req.params.id as string);
    res.status(200).json({ order });
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
    const result = await orderService.createOrder(userId, req.body as never);
    res.status(201).json(result);
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function cancel(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }
    await orderService.cancelOrder(userId, req.params.id as string);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function adminAll(_req: Request, res: Response): Promise<void> {
  try {
    const items = await orderService.adminListAllOrders();
    res.status(200).json({ items });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function adminUpdateStatus(req: Request, res: Response): Promise<void> {
  try {
    const status = (req.body as { status: OrderStatus }).status;
    await orderService.adminUpdateOrderStatus(req.params.id as string, status);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}
