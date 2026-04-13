import { prisma } from '../prisma/client';
import { HttpError } from '../utils/httpError';

function slugify(input: string): string {
  return input
    .trim()
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)+/g, '');
}

export type CategoryDTO = {
  id: string;
  name: string;
  slug: string;
  icon: string;
  parentId: string | null;
};

export async function listCategories(): Promise<CategoryDTO[]> {
  const categories = await prisma.category.findMany({ orderBy: { name: 'asc' } });
  return categories.map((c) => ({
    id: c.id,
    name: c.name,
    slug: c.slug,
    icon: c.icon,
    parentId: c.parentId,
  }));
}

export async function createCategory(input: { name: string; slug?: string; icon: string; parentId?: string | null }): Promise<{ id: string }>
{
  const name = input.name.trim();
  const slug = input.slug?.trim() ? slugify(input.slug) : slugify(name);
  if (!slug) throw new HttpError(400, 'Invalid slug');

  const created = await prisma.category.create({
    data: {
      name,
      slug,
      icon: input.icon,
      parentId: input.parentId ?? null,
    },
  });
  return { id: created.id };
}

export async function updateCategory(id: string, input: { name?: string; slug?: string; icon?: string; parentId?: string | null }): Promise<void>
{
  const existing = await prisma.category.findUnique({ where: { id } });
  if (!existing) throw new HttpError(404, 'Category not found');

  const slug = input.slug?.trim() ? slugify(input.slug) : undefined;

  await prisma.category.update({
    where: { id },
    data: {
      name: input.name?.trim(),
      slug,
      icon: input.icon,
      parentId: input.parentId ?? undefined,
    },
  });
}

export async function deleteCategory(id: string): Promise<void> {
  const productsCount = await prisma.product.count({ where: { categoryId: id } });
  if (productsCount > 0) throw new HttpError(409, 'Category has products and cannot be deleted');

  await prisma.category.delete({ where: { id } });
}
