import type { Request, Response } from 'express';
import multer from 'multer';
import sharp from 'sharp';

import { asHttpError } from '../utils/httpError';
import * as productService from '../services/product.service';
import { uploadProductImage } from '../services/storage.service';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 6 * 1024 * 1024 },
});

export const uploadImagesMiddleware = upload.array('images', 8);

export async function list(req: Request, res: Response): Promise<void> {
  try {
    const limit = Number(req.query.limit ?? 20);
    const cursor = typeof req.query.cursor === 'string' ? req.query.cursor : undefined;
    const category = typeof req.query.category === 'string' ? req.query.category : undefined;
    const minPrice = typeof req.query.minPrice === 'string' ? Number(req.query.minPrice) : undefined;
    const maxPrice = typeof req.query.maxPrice === 'string' ? Number(req.query.maxPrice) : undefined;
    const inStock = typeof req.query.inStock === 'string' ? req.query.inStock === 'true' : undefined;
    const sort = typeof req.query.sort === 'string' ? (req.query.sort as 'newest' | 'price_asc' | 'price_desc' | 'rating_desc') : undefined;

    const result = await productService.listProducts({
      limit: Number.isFinite(limit) ? limit : 20,
      cursor,
      category,
      minPrice: Number.isFinite(minPrice ?? Number.NaN) ? minPrice : undefined,
      maxPrice: Number.isFinite(maxPrice ?? Number.NaN) ? maxPrice : undefined,
      inStock,
      sort,
    });
    res.status(200).json(result);
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function featured(_req: Request, res: Response): Promise<void> {
  try {
    const items = await productService.featuredProducts();
    res.status(200).json({ items });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function detail(req: Request, res: Response): Promise<void> {
  try {
    const product = await productService.getProductBySlug(req.params.slug as string);
    res.status(200).json({ product });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function search(req: Request, res: Response): Promise<void> {
  try {
    const q = String(req.query.q ?? '').trim();
    const limit = Number(req.query.limit ?? 20);
    if (!q) {
      res.status(200).json({ items: [] });
      return;
    }
    const items = await productService.searchProducts(q, Number.isFinite(limit) ? limit : 20);
    res.status(200).json({ items });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function create(req: Request, res: Response): Promise<void> {
  try {
    const body = req.body as {
      name: string;
      description: string;
      price: number;
      comparePrice?: number;
      stock: number;
      images?: string[];
      specs: unknown;
      categoryId: string;
    };
    const result = await productService.createProduct(body);
    res.status(201).json(result);
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function update(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const body = req.body as {
      name?: string;
      description?: string;
      price?: number;
      comparePrice?: number | null;
      stock?: number;
      specs?: unknown;
      categoryId?: string;
    };
    await productService.updateProduct(id, body);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function remove(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    await productService.deleteProduct(id);
    res.status(200).json({ ok: true });
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}

export async function uploadImages(req: Request, res: Response): Promise<void> {
  try {
    const productId = req.params.id as string;
    const files = (req.files ?? []) as Express.Multer.File[];
    if (!files || files.length === 0) {
      res.status(400).json({ message: 'No images uploaded' });
      return;
    }

    const uploadedUrls: string[] = [];
    for (const file of files) {
      const processed = await sharp(file.buffer)
        .rotate()
        .resize({ width: 1200, withoutEnlargement: true })
        .webp({ quality: 82 })
        .toBuffer();

      const { url } = await uploadProductImage({
        productId,
        buffer: processed,
        contentType: 'image/webp',
      });
      uploadedUrls.push(url);
    }

    const updated = await productService.addProductImages(productId, uploadedUrls);
    res.status(200).json(updated);
  } catch (err) {
    const e = asHttpError(err);
    res.status(e.status).json({ message: e.message, details: e.details });
  }
}
