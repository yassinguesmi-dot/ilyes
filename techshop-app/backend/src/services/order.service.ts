import { OrderStatus, PaymentMethod, Prisma } from '@prisma/client';

import { prisma } from '../prisma/client';
import { HttpError } from '../utils/httpError';
import { sendSms } from './sms.service';

export type OrderListItem = {
  id: string;
  status: string;
  totalAmount: string;
  paymentMethod: string;
  createdAt: string;
};

export type OrderDetail = {
  id: string;
  status: string;
  totalAmount: string;
  paymentMethod: string;
  paymentRef: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
  address: {
    id: string;
    label: string;
    street: string;
    city: string;
    postalCode: string;
  };
  items: Array<{
    id: string;
    quantity: number;
    unitPrice: string;
    product: { id: string; name: string; slug: string; images: string[] };
  }>;
};

type CreateOrderInput = {
  items: Array<{ productId: string; quantity: number }>;
  addressId: string;
  paymentMethod: PaymentMethod;
  notes?: string;
};

function toListItem(order: { id: string; status: string; totalAmount: Prisma.Decimal; paymentMethod: string; createdAt: Date }): OrderListItem {
  return {
    id: order.id,
    status: order.status,
    totalAmount: order.totalAmount.toString(),
    paymentMethod: order.paymentMethod,
    createdAt: order.createdAt.toISOString(),
  };
}

function toDetail(order: {
  id: string;
  status: string;
  totalAmount: Prisma.Decimal;
  paymentMethod: string;
  paymentRef: string | null;
  notes: string | null;
  createdAt: Date;
  updatedAt: Date;
  address: { id: string; label: string; street: string; city: string; postalCode: string };
  items: Array<{
    id: string;
    quantity: number;
    unitPrice: Prisma.Decimal;
    product: { id: string; name: string; slug: string; images: string[] };
  }>;
}): OrderDetail {
  return {
    id: order.id,
    status: order.status,
    totalAmount: order.totalAmount.toString(),
    paymentMethod: order.paymentMethod,
    paymentRef: order.paymentRef,
    notes: order.notes,
    createdAt: order.createdAt.toISOString(),
    updatedAt: order.updatedAt.toISOString(),
    address: order.address,
    items: order.items.map((i) => ({
      id: i.id,
      quantity: i.quantity,
      unitPrice: i.unitPrice.toString(),
      product: i.product,
    })),
  };
}

export async function listMyOrders(userId: string): Promise<OrderListItem[]> {
  const orders = await prisma.order.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    select: {
      id: true,
      status: true,
      totalAmount: true,
      paymentMethod: true,
      createdAt: true,
    },
  });
  return orders.map(toListItem);
}

export async function getMyOrder(userId: string, orderId: string): Promise<OrderDetail> {
  const order = await prisma.order.findFirst({
    where: { id: orderId, userId },
    include: {
      address: { select: { id: true, label: true, street: true, city: true, postalCode: true } },
      items: {
        include: {
          product: { select: { id: true, name: true, slug: true, images: true } },
        },
      },
    },
  });
  if (!order) throw new HttpError(404, 'Order not found');
  return toDetail(order);
}

export async function createOrder(userId: string, input: CreateOrderInput): Promise<{ id: string; status: string }>
{
  if (input.items.length === 0) throw new HttpError(400, 'Cart is empty');

  const order = await prisma.$transaction(async (tx) => {
    const address = await tx.address.findFirst({ where: { id: input.addressId, userId } });
    if (!address) throw new HttpError(400, 'Invalid address');

    const productIds = Array.from(new Set(input.items.map((i) => i.productId)));
    const products = await tx.product.findMany({ where: { id: { in: productIds } } });
    if (products.length !== productIds.length) throw new HttpError(400, 'Some products were not found');

    const productById = new Map(products.map((p) => [p.id, p]));

    const itemsData: Array<{ productId: string; quantity: number; unitPrice: Prisma.Decimal }> = [];
    let totalAmount = new Prisma.Decimal(0);

    for (const item of input.items) {
      const product = productById.get(item.productId);
      if (!product) throw new HttpError(400, 'Some products were not found');

      if (item.quantity <= 0) throw new HttpError(400, 'Invalid quantity');

      itemsData.push({ productId: product.id, quantity: item.quantity, unitPrice: product.price });
      totalAmount = totalAmount.plus(product.price.mul(item.quantity));
    }

    for (const item of input.items) {
      const updated = await tx.product.updateMany({
        where: { id: item.productId, stock: { gte: item.quantity } },
        data: { stock: { decrement: item.quantity } },
      });
      if (updated.count !== 1) throw new HttpError(409, 'Insufficient stock for one or more items');
    }

    const status: OrderStatus = input.paymentMethod === 'CARD' ? OrderStatus.PENDING : OrderStatus.CONFIRMED;

    const created = await tx.order.create({
      data: {
        userId,
        status,
        totalAmount,
        addressId: input.addressId,
        paymentMethod: input.paymentMethod,
        notes: input.notes?.trim() ? input.notes.trim() : null,
        items: {
          create: itemsData.map((i) => ({
            productId: i.productId,
            quantity: i.quantity,
            unitPrice: i.unitPrice,
          })),
        },
      },
      include: { user: { select: { phone: true } } },
    });

    return created;
  });

  if (order.status === 'CONFIRMED') {
    if (order.user.phone) {
      await sendSms(order.user.phone, `TechShop: votre commande ${order.id} a été confirmée.`);
    }
  }

  return { id: order.id, status: order.status };
}

export async function cancelOrder(userId: string, orderId: string): Promise<void> {
  await prisma.$transaction(async (tx) => {
    const order = await tx.order.findFirst({
      where: { id: orderId, userId },
      include: { items: true },
    });
    if (!order) throw new HttpError(404, 'Order not found');
    if (order.status === 'CANCELLED') return;
    if (order.status === 'SHIPPED' || order.status === 'DELIVERED') {
      throw new HttpError(400, 'Order cannot be cancelled at this stage');
    }

    await tx.order.update({ where: { id: orderId }, data: { status: OrderStatus.CANCELLED } });
    for (const item of order.items) {
      await tx.product.update({
        where: { id: item.productId },
        data: { stock: { increment: item.quantity } },
      });
    }
  });
}

export async function adminListAllOrders(): Promise<Array<{ id: string; status: string; totalAmount: string; createdAt: string; user: { id: string; email: string; fullName: string } }>> {
  const orders = await prisma.order.findMany({
    orderBy: { createdAt: 'desc' },
    include: {
      user: { select: { id: true, email: true, fullName: true } },
    },
  });
  return orders.map((o) => ({
    id: o.id,
    status: o.status,
    totalAmount: o.totalAmount.toString(),
    createdAt: o.createdAt.toISOString(),
    user: o.user,
  }));
}

export async function adminUpdateOrderStatus(orderId: string, status: OrderStatus): Promise<void>
{
  const order = await prisma.order.update({
    where: { id: orderId },
    data: { status },
    include: { user: { select: { phone: true } } },
  });

  if (order.user.phone) {
    const msg =
      status === OrderStatus.SHIPPED
        ? `TechShop: votre commande ${order.id} a été expédiée.`
        : status === OrderStatus.DELIVERED
          ? `TechShop: votre commande ${order.id} a été livrée.`
          : status === OrderStatus.CANCELLED
            ? `TechShop: votre commande ${order.id} a été annulée.`
            : null;
    if (msg) await sendSms(order.user.phone, msg);
  }
}
