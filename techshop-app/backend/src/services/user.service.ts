import { prisma } from '../prisma/client';
import { HttpError } from '../utils/httpError';

export type MeDTO = {
  id: string;
  email: string;
  fullName: string;
  phone: string | null;
  role: 'USER' | 'ADMIN';
  createdAt: string;
};

export async function getMe(userId: string): Promise<MeDTO> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new HttpError(404, 'User not found');
  return {
    id: user.id,
    email: user.email,
    fullName: user.fullName,
    phone: user.phone,
    role: user.role === 'ADMIN' ? 'ADMIN' : 'USER',
    createdAt: user.createdAt.toISOString(),
  };
}

export async function updateMe(userId: string, input: { fullName?: string; phone?: string | null }): Promise<void> {
  await prisma.user.update({
    where: { id: userId },
    data: {
      fullName: input.fullName?.trim(),
      phone: input.phone === null ? null : input.phone?.trim(),
    },
  });
}

export async function listWishlist(userId: string): Promise<Array<{ productId: string; product: { id: string; name: string; slug: string; price: string; comparePrice: string | null; stock: number; images: string[] } }>> {
  const rows = await prisma.wishlist.findMany({
    where: { userId },
    include: {
      product: { select: { id: true, name: true, slug: true, price: true, comparePrice: true, stock: true, images: true } },
    },
  });

  return rows.map((w) => ({
    productId: w.productId,
    product: {
      id: w.product.id,
      name: w.product.name,
      slug: w.product.slug,
      price: w.product.price.toString(),
      comparePrice: w.product.comparePrice ? w.product.comparePrice.toString() : null,
      stock: w.product.stock,
      images: w.product.images,
    },
  }));
}

export async function addToWishlist(userId: string, productId: string): Promise<void> {
  await prisma.wishlist.upsert({
    where: { userId_productId: { userId, productId } },
    create: { userId, productId },
    update: {},
  });
}

export async function removeFromWishlist(userId: string, productId: string): Promise<void> {
  await prisma.wishlist.delete({ where: { userId_productId: { userId, productId } } });
}

export async function listAddresses(userId: string): Promise<Array<{ id: string; label: string; street: string; city: string; postalCode: string; isDefault: boolean }>> {
  const rows = await prisma.address.findMany({ where: { userId }, orderBy: [{ isDefault: 'desc' }, { label: 'asc' }] });
  return rows.map((a) => ({
    id: a.id,
    label: a.label,
    street: a.street,
    city: a.city,
    postalCode: a.postalCode,
    isDefault: a.isDefault,
  }));
}

export async function createAddress(userId: string, input: { label: string; street: string; city: string; postalCode: string; isDefault?: boolean }): Promise<{ id: string }>
{
  const hasAny = await prisma.address.count({ where: { userId } });
  const isDefault = input.isDefault ?? hasAny === 0;

  return prisma.$transaction(async (tx) => {
    if (isDefault) {
      await tx.address.updateMany({ where: { userId }, data: { isDefault: false } });
    }
    const created = await tx.address.create({
      data: {
        userId,
        label: input.label.trim(),
        street: input.street.trim(),
        city: input.city.trim(),
        postalCode: input.postalCode.trim(),
        isDefault,
      },
    });
    return { id: created.id };
  });
}

export async function updateAddress(userId: string, addressId: string, input: { label?: string; street?: string; city?: string; postalCode?: string; isDefault?: boolean }): Promise<void>
{
  const existing = await prisma.address.findFirst({ where: { id: addressId, userId } });
  if (!existing) throw new HttpError(404, 'Address not found');

  await prisma.$transaction(async (tx) => {
    if (input.isDefault === true) {
      await tx.address.updateMany({ where: { userId }, data: { isDefault: false } });
    }
    await tx.address.update({
      where: { id: addressId },
      data: {
        label: input.label?.trim(),
        street: input.street?.trim(),
        city: input.city?.trim(),
        postalCode: input.postalCode?.trim(),
        isDefault: input.isDefault,
      },
    });
  });
}

export async function deleteAddress(userId: string, addressId: string): Promise<void> {
  const existing = await prisma.address.findFirst({ where: { id: addressId, userId } });
  if (!existing) throw new HttpError(404, 'Address not found');

  await prisma.address.delete({ where: { id: addressId } });
}
