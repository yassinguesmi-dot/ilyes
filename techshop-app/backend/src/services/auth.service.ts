import bcrypt from 'bcrypt';
import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';

import { prisma } from '../prisma/client';
import { redis } from '../redis/client';
import { HttpError } from '../utils/httpError';
import { sendPasswordResetEmail } from './email.service';
import { sendSms } from './sms.service';

export type PublicUser = {
  id: string;
  email: string;
  fullName: string;
  phone: string | null;
  role: 'USER' | 'ADMIN';
  createdAt: string;
};

export type AuthTokens = {
  accessToken: string;
  refreshToken: string;
};

export type AuthResult = {
  user: PublicUser;
  tokens: AuthTokens;
};

type JwtAccessPayload = {
  sub: string;
  role: 'USER' | 'ADMIN';
  type: 'access';
};

type JwtRefreshPayload = {
  sub: string;
  type: 'refresh';
};

function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v) throw new HttpError(500, `Server misconfiguration: ${name} is not set`);
  return v;
}

function ttlMinutes(): number {
  const raw = process.env.ACCESS_TOKEN_TTL_MINUTES ?? '15';
  const n = Number(raw);
  return Number.isFinite(n) && n > 0 ? n : 15;
}

function ttlDays(): number {
  const raw = process.env.REFRESH_TOKEN_TTL_DAYS ?? '7';
  const n = Number(raw);
  return Number.isFinite(n) && n > 0 ? n : 7;
}

function sha256(value: string): string {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function toPublicUser(user: {
  id: string;
  email: string;
  fullName: string;
  phone: string | null;
  role: string;
  createdAt: Date;
}): PublicUser {
  const role = user.role === 'ADMIN' ? 'ADMIN' : 'USER';
  return {
    id: user.id,
    email: user.email,
    fullName: user.fullName,
    phone: user.phone,
    role,
    createdAt: user.createdAt.toISOString(),
  };
}

function signAccessToken(user: { id: string; role: 'USER' | 'ADMIN' }): string {
  const secret = requireEnv('JWT_ACCESS_TOKEN_SECRET');
  const payload: JwtAccessPayload = { sub: user.id, role: user.role, type: 'access' };
  return jwt.sign(payload, secret, { expiresIn: `${ttlMinutes()}m` });
}

function signRefreshToken(user: { id: string }): string {
  const secret = requireEnv('JWT_REFRESH_TOKEN_SECRET');
  const payload: JwtRefreshPayload = { sub: user.id, type: 'refresh' };
  return jwt.sign(payload, secret, { expiresIn: `${ttlDays()}d` });
}

async function saveRefreshTokenHash(userId: string, refreshToken: string): Promise<void> {
  await prisma.user.update({
    where: { id: userId },
    data: { refreshToken: sha256(refreshToken) },
  });
}

export async function register(input: {
  email: string;
  password: string;
  fullName: string;
  phone?: string;
}): Promise<AuthResult> {
  const email = input.email.trim().toLowerCase();
  const fullName = input.fullName.trim();
  const phone = input.phone?.trim() ? input.phone.trim() : null;

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) throw new HttpError(409, 'Email already registered');

  const passwordHash = await bcrypt.hash(input.password, 12);

  const user = await prisma.user.create({
    data: {
      email,
      passwordHash,
      fullName,
      phone,
    },
  });

  const publicUser = toPublicUser(user);
  const accessToken = signAccessToken({ id: user.id, role: publicUser.role });
  const refreshToken = signRefreshToken({ id: user.id });
  await saveRefreshTokenHash(user.id, refreshToken);

  return { user: publicUser, tokens: { accessToken, refreshToken } };
}

export async function login(input: { email: string; password: string }): Promise<AuthResult> {
  const email = input.email.trim().toLowerCase();

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) throw new HttpError(401, 'Invalid credentials');

  const ok = await bcrypt.compare(input.password, user.passwordHash);
  if (!ok) throw new HttpError(401, 'Invalid credentials');

  const publicUser = toPublicUser(user);
  const accessToken = signAccessToken({ id: user.id, role: publicUser.role });
  const refreshToken = signRefreshToken({ id: user.id });
  await saveRefreshTokenHash(user.id, refreshToken);

  return { user: publicUser, tokens: { accessToken, refreshToken } };
}

export async function refreshTokens(input: { refreshToken: string }): Promise<AuthTokens> {
  const secret = requireEnv('JWT_REFRESH_TOKEN_SECRET');

  let decoded: unknown;
  try {
    decoded = jwt.verify(input.refreshToken, secret);
  } catch {
    throw new HttpError(401, 'Invalid refresh token');
  }

  if (!decoded || typeof decoded !== 'object') throw new HttpError(401, 'Invalid refresh token');
  const payload = decoded as Partial<JwtRefreshPayload>;

  if (payload.type !== 'refresh' || typeof payload.sub !== 'string' || !payload.sub) {
    throw new HttpError(401, 'Invalid refresh token');
  }

  const user = await prisma.user.findUnique({ where: { id: payload.sub } });
  if (!user || !user.refreshToken) throw new HttpError(401, 'Refresh token revoked');

  const incomingHash = sha256(input.refreshToken);
  if (incomingHash !== user.refreshToken) throw new HttpError(401, 'Refresh token revoked');

  const publicUser = toPublicUser(user);
  const accessToken = signAccessToken({ id: user.id, role: publicUser.role });
  const newRefreshToken = signRefreshToken({ id: user.id });
  await saveRefreshTokenHash(user.id, newRefreshToken);

  return { accessToken, refreshToken: newRefreshToken };
}

export async function logout(userId: string): Promise<void> {
  await prisma.user.update({ where: { id: userId }, data: { refreshToken: null } });
}

export async function forgotPassword(emailInput: string): Promise<void> {
  const email = emailInput.trim().toLowerCase();
  const user = await prisma.user.findUnique({ where: { email } });

  if (!user) return;

  const token = crypto.randomBytes(32).toString('hex');
  const key = `pwdreset:${token}`;
  await redis.set(key, user.id, 'EX', 15 * 60);

  const baseUrl = process.env.RESET_PASSWORD_URL ?? 'http://localhost:19006/reset-password';
  const resetUrl = `${baseUrl}${baseUrl.includes('?') ? '&' : '?'}token=${encodeURIComponent(token)}`;

  await sendPasswordResetEmail(user.email, resetUrl);
  if (user.phone) {
    await sendSms(user.phone, `TechShop: réinitialisez votre mot de passe ici: ${resetUrl}`);
  }
}

export async function resetPassword(input: { token: string; newPassword: string }): Promise<void> {
  const key = `pwdreset:${input.token}`;
  const userId = await redis.get(key);
  if (!userId) throw new HttpError(400, 'Invalid or expired reset token');

  const passwordHash = await bcrypt.hash(input.newPassword, 12);
  await prisma.user.update({
    where: { id: userId },
    data: { passwordHash, refreshToken: null },
  });
  await redis.del(key);
}
