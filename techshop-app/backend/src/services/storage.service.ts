import crypto from 'node:crypto';

import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';

import { HttpError } from '../utils/httpError';

function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v) throw new HttpError(500, `Server misconfiguration: ${name} is not set`);
  return v;
}

function getS3Client(): S3Client {
  const region = requireEnv('AWS_REGION');
  const accessKeyId = requireEnv('AWS_ACCESS_KEY_ID');
  const secretAccessKey = requireEnv('AWS_SECRET_ACCESS_KEY');

  return new S3Client({
    region,
    credentials: { accessKeyId, secretAccessKey },
  });
}

export async function uploadProductImage(args: {
  productId: string;
  buffer: Buffer;
  contentType: string;
}): Promise<{ key: string; url: string }>
{
  const bucket = requireEnv('AWS_S3_BUCKET');
  const cloudfrontBaseUrl = requireEnv('CLOUDFRONT_BASE_URL').replace(/\/$/, '');

  const random = crypto.randomUUID();
  const key = `products/${args.productId}/${random}.webp`;

  const s3 = getS3Client();
  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: args.buffer,
      ContentType: args.contentType,
      CacheControl: 'public, max-age=31536000, immutable',
    }),
  );

  return { key, url: `${cloudfrontBaseUrl}/${key}` };
}
