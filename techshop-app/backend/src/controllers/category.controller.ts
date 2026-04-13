import type { Request, Response } from 'express';
import { asHttpError } from '../utils/httpError';
import * as categoryService from '../services/category.service';

export async function list(_req: Request, res: Response): Promise<void> {
  try {
    const items = await categoryService.listCategories();
    res.status(200).json({ items });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function create(req: Request, res: Response): Promise<void> {
  try {
    const result = await categoryService.createCategory(req.body as never);
    res.status(201).json(result);
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function update(req: Request, res: Response): Promise<void> {
  try {
    await categoryService.updateCategory(req.params.id as string, req.body as never);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function remove(req: Request, res: Response): Promise<void> {
  try {
    await categoryService.deleteCategory(req.params.id as string);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}
