import { Client } from '@elastic/elasticsearch';

import { HttpError } from '../utils/httpError';

const INDEX = 'products';

function getClient(): Client {
  const node = process.env.ELASTICSEARCH_NODE ?? '';
  if (!node) throw new HttpError(500, 'ELASTICSEARCH_NODE is not set');
  return new Client({ node });
}

export async function ensureProductsIndex(): Promise<void> {
  const client = getClient();
  const exists = await client.indices.exists({ index: INDEX });
  if (exists) return;

  await client.indices.create({
    index: INDEX,
    mappings: {
      properties: {
        id: { type: 'keyword' },
        name: { type: 'text' },
        description: { type: 'text' },
        slug: { type: 'keyword' },
        categoryId: { type: 'keyword' },
        createdAt: { type: 'date' },
      },
    },
  });
}

export async function indexProduct(doc: {
  id: string;
  name: string;
  description: string;
  slug: string;
  categoryId: string;
  createdAt: string;
}): Promise<void> {
  await ensureProductsIndex();
  const client = getClient();

  await client.index({
    index: INDEX,
    id: doc.id,
    document: doc,
    refresh: true,
  });
}

export async function deleteProductFromIndex(productId: string): Promise<void> {
  try {
    const client = getClient();
    await client.delete({ index: INDEX, id: productId, refresh: true });
  } catch {
    // ignore indexing errors
  }
}

export async function searchProductIds(q: string, limit: number): Promise<string[]> {
  await ensureProductsIndex();
  const client = getClient();

  const result = await client.search<{ id: string }>({
    index: INDEX,
    size: limit,
    query: {
      multi_match: {
        query: q,
        fields: ['name^3', 'description'],
        fuzziness: 'AUTO',
      },
    },
    _source: ['id'],
  });

  const hits = result.hits.hits;
  return hits
    .map((h) => h._id)
    .filter((id): id is string => typeof id === 'string' && id.length > 0);
}
