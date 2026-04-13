import { Prisma } from '@prisma/client';

import { prisma } from '../prisma/client';
import { redis } from '../redis/client';
import { HttpError } from '../utils/httpError';
import { deleteProductFromIndex, indexProduct, searchProductIds } from './search.service';

function slugify(input: string): string {
  return input
    .trim()
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)+/g, '');
}

type ListQuery = {
  cursor?: string;
  limit: number;
  category?: string;
  minPrice?: number;
  maxPrice?: number;
  inStock?: boolean;
  sort?: 'newest' | 'price_asc' | 'price_desc' | 'rating_desc';
};

export type ProductListItem = {
  id: string;
  name: string;
  slug: string;
  description: string;
  price: string;
  comparePrice: string | null;
  stock: number;
  images: string[];
  category: { id: string; name: string; slug: string; icon: string };
  avgRating: number;
  reviewCount: number;
  createdAt: string;
};

export async function listProducts(query: ListQuery): Promise<{ items: ProductListItem[]; nextCursor: string | null }> {
  const where: Prisma.ProductWhereInput = {};

  const priceFilter: Prisma.DecimalFilter<'Product'> = {};

  if (query.inStock === true) where.stock = { gt: 0 };
  if (typeof query.minPrice === 'number') priceFilter.gte = new Prisma.Decimal(query.minPrice);
  if (typeof query.maxPrice === 'number') priceFilter.lte = new Prisma.Decimal(query.maxPrice);
  if (Object.keys(priceFilter).length > 0) where.price = priceFilter;

  if (query.category) {
    where.category = {
      OR: [{ id: query.category }, { slug: query.category }],
    };
  }

  const orderBy: Prisma.ProductOrderByWithRelationInput =
    query.sort === 'price_asc'
      ? { price: 'asc' }
      : query.sort === 'price_desc'
        ? { price: 'desc' }
        : query.sort === 'rating_desc'
          ? { reviews: { _count: 'desc' } }
          : { createdAt: 'desc' };

  const take = Math.min(Math.max(query.limit, 1), 50);

  const products = await prisma.product.findMany({
    where,
    take: take + 1,
    ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
    orderBy,
    include: {
      category: true,
    },
  });

  const hasMore = products.length > take;
  const page = hasMore ? products.slice(0, take) : products;
  const ids = page.map((p) => p.id);

  const grouped = await prisma.review.groupBy({
    by: ['productId'],
    where: { productId: { in: ids } },
    _avg: { rating: true },
    _count: { _all: true },
  });

  const ratingById = new Map<string, { avg: number; count: number }>();
  for (const g of grouped) {
    ratingById.set(g.productId, { avg: g._avg.rating ?? 0, count: g._count._all });
  }

  const items: ProductListItem[] = page.map((p) => {
    const stats = ratingById.get(p.id) ?? { avg: 0, count: 0 };
    return {
      id: p.id,
      name: p.name,
      slug: p.slug,
      description: p.description,
      price: p.price.toString(),
      comparePrice: p.comparePrice ? p.comparePrice.toString() : null,
      stock: p.stock,
      images: p.images,
      category: { id: p.category.id, name: p.category.name, slug: p.category.slug, icon: p.category.icon },
      avgRating: Number(stats.avg.toFixed(2)),
      reviewCount: stats.count,
      createdAt: p.createdAt.toISOString(),
    };
  });

  return {
    items,
    nextCursor: hasMore ? page[page.length - 1]?.id ?? null : null,
  };
}

export type ProductDetail = {
  id: string;
  name: string;
  slug: string;
  description: string;
  price: string;
  comparePrice: string | null;
  stock: number;
  images: string[];
  specs: unknown;
  category: { id: string; name: string; slug: string; icon: string };
  avgRating: number;
  reviewCount: number;
  ratingHistogram: Record<'1' | '2' | '3' | '4' | '5', number>;
  reviews: Array<{ id: string; rating: number; comment: string | null; createdAt: string; user: { id: string; fullName: string } }>;
  createdAt: string;
};

export async function getProductBySlug(slug: string): Promise<ProductDetail> {
  const cacheKey = `product:slug:${slug}`;
  const cached = await redis.get(cacheKey);
  if (cached) {
    try {
      return JSON.parse(cached) as ProductDetail;
    } catch {
      await redis.del(cacheKey);
    }
  }

  const product = await prisma.product.findUnique({
    where: { slug },
    include: { category: true },
  });

  if (!product) throw new HttpError(404, 'Product not found');

  const [stats, histogram, reviews] = await Promise.all([
    prisma.review.aggregate({
      where: { productId: product.id },
      _avg: { rating: true },
      _count: { _all: true },
    }),
    prisma.review.groupBy({
      by: ['rating'],
      where: { productId: product.id },
      _count: { _all: true },
    }),
    prisma.review.findMany({
      where: { productId: product.id },
      orderBy: { createdAt: 'desc' },
      take: 20,
      include: { user: { select: { id: true, fullName: true } } },
    }),
  ]);

  const ratingHistogram: Record<'1' | '2' | '3' | '4' | '5', number> = { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 };
  for (const g of histogram) {
    const key = String(g.rating) as '1' | '2' | '3' | '4' | '5';
    if (key in ratingHistogram) ratingHistogram[key] = g._count._all;
  }

  const detail: ProductDetail = {
    id: product.id,
    name: product.name,
    slug: product.slug,
    description: product.description,
    price: product.price.toString(),
    comparePrice: product.comparePrice ? product.comparePrice.toString() : null,
    stock: product.stock,
    images: product.images,
    specs: product.specs,
    category: {
      id: product.category.id,
      name: product.category.name,
      slug: product.category.slug,
      icon: product.category.icon,
    },
    avgRating: Number((stats._avg.rating ?? 0).toFixed(2)),
    reviewCount: stats._count._all,
    ratingHistogram,
    reviews: reviews.map((r) => ({
      id: r.id,
      rating: r.rating,
      comment: r.comment,
      createdAt: r.createdAt.toISOString(),
      user: r.user,
    })),
    createdAt: product.createdAt.toISOString(),
  };

  await redis.set(cacheKey, JSON.stringify(detail), 'EX', 120);
  return detail;
}

export async function featuredProducts(): Promise<ProductListItem[]> {
  const cacheKey = 'products:featured';
  const cached = await redis.get(cacheKey);
  if (cached) {
    try {
      return JSON.parse(cached) as ProductListItem[];
    } catch {
      await redis.del(cacheKey);
    }
  }

  const result = await listProducts({ limit: 10, sort: 'newest' });
  await redis.set(cacheKey, JSON.stringify(result.items), 'EX', 300);
  return result.items;
}

export async function searchProducts(q: string, limit: number): Promise<ProductListItem[]> {
  const ids = await searchProductIds(q, Math.min(Math.max(limit, 1), 50));
  if (ids.length === 0) return [];

  const products = await prisma.product.findMany({
    where: { id: { in: ids } },
    include: { category: true },
  });

  const grouped = await prisma.review.groupBy({
    by: ['productId'],
    where: { productId: { in: ids } },
    _avg: { rating: true },
    _count: { _all: true },
  });
  const ratingById = new Map<string, { avg: number; count: number }>();
  for (const g of grouped) ratingById.set(g.productId, { avg: g._avg.rating ?? 0, count: g._count._all });

  const byId = new Map(products.map((p) => [p.id, p]));
  const ordered = ids.map((id) => byId.get(id)).filter((p): p is NonNullable<typeof p> => Boolean(p));

  return ordered.map((p) => {
    const stats = ratingById.get(p.id) ?? { avg: 0, count: 0 };
    return {
      id: p.id,
      name: p.name,
      slug: p.slug,
      description: p.description,
      price: p.price.toString(),
      comparePrice: p.comparePrice ? p.comparePrice.toString() : null,
      stock: p.stock,
      images: p.images,
      category: { id: p.category.id, name: p.category.name, slug: p.category.slug, icon: p.category.icon },
      avgRating: Number(stats.avg.toFixed(2)),
      reviewCount: stats.count,
      createdAt: p.createdAt.toISOString(),
    };
  });
}

export async function createProduct(input: {
  name: string;
  description: string;
  price: number;
  comparePrice?: number;
  stock: number;
  images?: string[];
  specs: unknown;
  categoryId: string;
}): Promise<{ id: string }>
{
  const baseSlug = slugify(input.name);
  if (!baseSlug) throw new HttpError(400, 'Invalid product name');

  let slug = baseSlug;
  for (let i = 0; i < 5; i += 1) {
    const exists = await prisma.product.findUnique({ where: { slug } });
    if (!exists) break;
    slug = `${baseSlug}-${i + 1}`;
  }

  const product = await prisma.product.create({
    data: {
      name: input.name,
      slug,
      description: input.description,
      price: new Prisma.Decimal(input.price),
      comparePrice: typeof input.comparePrice === 'number' ? new Prisma.Decimal(input.comparePrice) : null,
      stock: input.stock,
      images: input.images ?? [],
      specs: input.specs as Prisma.InputJsonValue,
      categoryId: input.categoryId,
    },
  });

  await indexProduct({
    id: product.id,
    name: product.name,
    description: product.description,
    slug: product.slug,
    categoryId: product.categoryId,
    createdAt: product.createdAt.toISOString(),
  });

  await redis.del('products:featured');
  return { id: product.id };
}

export async function updateProduct(id: string, input: {
  name?: string;
  description?: string;
  price?: number;
  comparePrice?: number | null;
  stock?: number;
  specs?: unknown;
  categoryId?: string;
}): Promise<void>
{
  const existing = await prisma.product.findUnique({ where: { id } });
  if (!existing) throw new HttpError(404, 'Product not found');

  const updated = await prisma.product.update({
    where: { id },
    data: {
      name: input.name,
      description: input.description,
      price: typeof input.price === 'number' ? new Prisma.Decimal(input.price) : undefined,
      comparePrice: typeof input.comparePrice === 'number' ? new Prisma.Decimal(input.comparePrice) : input.comparePrice === null ? null : undefined,
      stock: input.stock,
      specs: input.specs ? (input.specs as Prisma.InputJsonValue) : undefined,
      categoryId: input.categoryId,
    },
  });

  await indexProduct({
    id: updated.id,
    name: updated.name,
    description: updated.description,
    slug: updated.slug,
    categoryId: updated.categoryId,
    createdAt: updated.createdAt.toISOString(),
  });

  await redis.del(`product:slug:${updated.slug}`);
  await redis.del('products:featured');
}

export async function deleteProduct(id: string): Promise<void> {
  const existing = await prisma.product.findUnique({ where: { id } });
  if (!existing) throw new HttpError(404, 'Product not found');

  await prisma.product.delete({ where: { id } });
  await deleteProductFromIndex(id);

  await redis.del(`product:slug:${existing.slug}`);
  await redis.del('products:featured');
}

export async function addProductImages(id: string, imageUrls: string[]): Promise<{ images: string[] }>
{
  const product = await prisma.product.findUnique({ where: { id } });
  if (!product) throw new HttpError(404, 'Product not found');

  const updated = await prisma.product.update({
    where: { id },
    data: { images: { push: imageUrls } },
    select: { images: true, slug: true },
  });

  await redis.del(`product:slug:${updated.slug}`);
  return { images: updated.images };
}
