import Stripe from 'stripe';

import { prisma } from '../prisma/client';
import { HttpError } from '../utils/httpError';
import { OrderStatus } from '@prisma/client';

function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v) throw new HttpError(500, `Server misconfiguration: ${name} is not set`);
  return v;
}

function minorUnitMultiplier(): number {
  const raw = process.env.CURRENCY_MINOR_UNIT ?? '100';
  const n = Number(raw);
  return Number.isFinite(n) && n > 0 ? n : 100;
}

function stripeClient(): Stripe {
  const key = requireEnv('STRIPE_SECRET_KEY');
  return new Stripe(key, { apiVersion: '2024-04-10' });
}

export async function createStripeCheckoutSession(userId: string, orderId: string): Promise<{ url: string; sessionId: string }>
{
  const currency = (process.env.STRIPE_CURRENCY ?? 'tnd').toLowerCase();
  const successUrl = requireEnv('STRIPE_SUCCESS_URL');
  const cancelUrl = requireEnv('STRIPE_CANCEL_URL');

  const order = await prisma.order.findFirst({
    where: { id: orderId, userId },
    include: {
      items: { include: { product: true } },
    },
  });
  if (!order) throw new HttpError(404, 'Order not found');
  if (order.paymentMethod !== 'CARD') throw new HttpError(400, 'Order is not payable by card');

  const multiplier = minorUnitMultiplier();
  const lineItems: Stripe.Checkout.SessionCreateParams.LineItem[] = order.items.map((i) => {
    const unitAmount = Math.round(parseFloat(i.unitPrice.toString()) * multiplier);
    return {
      quantity: i.quantity,
      price_data: {
        currency,
        unit_amount: unitAmount,
        product_data: {
          name: i.product.name,
          images: i.product.images.slice(0, 1),
        },
      },
    };
  });

  const stripe = stripeClient();
  const session = await stripe.checkout.sessions.create({
    mode: 'payment',
    payment_method_types: ['card'],
    line_items: lineItems,
    success_url: successUrl,
    cancel_url: cancelUrl,
    metadata: { orderId: order.id },
  });

  if (!session.url) throw new HttpError(500, 'Stripe session creation failed');
  return { url: session.url, sessionId: session.id };
}

export async function handleStripeWebhook(rawBody: Buffer, signatureHeader: string | undefined): Promise<void> {
  const webhookSecret = requireEnv('STRIPE_WEBHOOK_SECRET');
  if (!signatureHeader) throw new HttpError(400, 'Missing Stripe signature');

  const stripe = stripeClient();
  const event = stripe.webhooks.constructEvent(rawBody, signatureHeader, webhookSecret);

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;
    const orderId = session.metadata?.orderId;
    if (!orderId) return;

    await prisma.order.update({
      where: { id: orderId },
      data: {
        status: OrderStatus.CONFIRMED,
        paymentRef: session.id,
      },
    });
  }
}
