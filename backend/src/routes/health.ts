import { Router, Request, Response } from 'express';
import { isDbReady, getDbState } from '../db/connection.js';

export const healthRouter = Router();

healthRouter.get('/', (req: Request, res: Response) => {
  const ready = isDbReady();
  const dbState = getDbState();

  const statusCode = ready ? 200 : 503;
  res.status(statusCode).json({
    status: ready ? 'ok' : 'degraded',
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.floor(process.uptime()),
    database: {
      connected: ready,
      state: dbState,
      provider: 'MongoDB Atlas',
    },
  });
});
