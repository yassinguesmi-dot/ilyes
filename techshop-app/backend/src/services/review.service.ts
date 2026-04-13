import { prisma } from '../prisma/client';
import { HttpError } from '../utils/httpError';

export type ReviewDTO = {
  id: string;
  rating: number;
  comment: string | null;
  createdAt: string;
  user: { id: string; fullName: string };
};

export async function listReviews(productId: string): Promise<ReviewDTO[]> {
  const rows = await prisma.review.findMany({
    where: { productId },
    orderBy: { createdAt: 'desc' },
    include: { user: { select: { id: true, fullName: true } } },
  });
  return rows.map((r) => ({
    id: r.id,
    rating: r.rating,
    comment: r.comment,
    createdAt: r.createdAt.toISOString(),
    user: r.user,
  }));
}

export async function addReview(userId: string, productId: string, input: { rating: number; comment?: string }): Promise<{ id: string }>
{
  const product = await prisma.product.findUnique({ where: { id: productId } });
  if (!product) throw new HttpError(404, 'Product not found');

  const existing = await prisma.review.findFirst({ where: { userId, productId } });
  if (existing) throw new HttpError(409, 'You already reviewed this product');

  const created = await prisma.review.create({
    data: {
      userId,
      productId,
      rating: input.rating,
      comment: input.comment?.trim() ? input.comment.trim() : null,
    },
  });
  return { id: created.id };
}

export async function deleteReview(requester: { userId: string; role: 'USER' | 'ADMIN' }, reviewId: string): Promise<void> {
  const review = await prisma.review.findUnique({ where: { id: reviewId } });
  if (!review) throw new HttpError(404, 'Review not found');

  if (requester.role !== 'ADMIN' && review.userId !== requester.userId) {
    throw new HttpError(403, 'Forbidden');
  }

  await prisma.review.delete({ where: { id: reviewId } });
}
