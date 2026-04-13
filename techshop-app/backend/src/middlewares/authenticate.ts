import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

export type AuthenticatedUser = {
  userId: string;
  role: 'USER' | 'ADMIN';
};

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    // eslint-disable-next-line @typescript-eslint/consistent-type-definitions
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

type AccessTokenPayload = {
  sub: string;
  role: 'USER' | 'ADMIN';
  type: 'access';
  iat: number;
  exp: number;
};

export function authenticate(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.header('authorization') ?? '';
  const [scheme, token] = authHeader.split(' ');

  if (scheme !== 'Bearer' || !token) {
    res.status(401).json({ message: 'Missing or invalid Authorization header' });
    return;
  }

  const secret = process.env.JWT_ACCESS_TOKEN_SECRET;
  if (!secret) {
    res.status(500).json({ message: 'Server misconfiguration: JWT secret not set' });
    return;
  }

  try {
    const decoded = jwt.verify(token, secret) as unknown;

    if (!decoded || typeof decoded !== 'object') {
      res.status(401).json({ message: 'Invalid token' });
      return;
    }

    const payload = decoded as Partial<AccessTokenPayload>;

    if (payload.type !== 'access' || typeof payload.sub !== 'string' || !payload.sub) {
      res.status(401).json({ message: 'Invalid access token' });
      return;
    }

    const role = payload.role === 'ADMIN' ? 'ADMIN' : 'USER';
    req.user = { userId: payload.sub, role };

    next();
  } catch {
    res.status(401).json({ message: 'Token expired or invalid' });
  }
}
