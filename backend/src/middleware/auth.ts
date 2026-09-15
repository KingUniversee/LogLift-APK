import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { isDbReady } from '../db/connection.js';

declare global {
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

const JWT_SECRET = process.env.JWT_SECRET || 'liftlog_super_secure_jwt_secret_key_2026_x92';

export function requireDbReady(req: Request, res: Response, next: NextFunction) {
  if (req.path === '/api/health') {
    return next();
  }
  if (!isDbReady()) {
    return res.status(503).json({
      error: 'Database connection is not ready. Please retry shortly.',
    });
  }
  next();
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorized: Missing or invalid authorization token.',
    });
  }

  const token = authHeader.split(' ')[1];
  try {
    const payload = jwt.verify(token, JWT_SECRET) as { userId: string };
    if (!payload.userId) {
      return res.status(401).json({
        error: 'Unauthorized: Malformed token payload.',
      });
    }
    req.userId = payload.userId;
    next();
  } catch (err) {
    return res.status(401).json({
      error: 'Unauthorized: Token expired or invalid.',
    });
  }
}
