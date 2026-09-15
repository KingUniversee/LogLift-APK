import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { requireDbReady } from './middleware/auth.js';
import { healthRouter } from './routes/health.js';
import { authRouter } from './routes/auth.js';
import { workoutPlansRouter } from './routes/workoutPlans.js';
import { exercisesRouter } from './routes/exercises.js';
import { workoutSessionsRouter } from './routes/workoutSessions.js';
import { personalRecordsRouter } from './routes/personalRecords.js';
import { analyticsRouter } from './routes/analytics.js';
import { settingsRouter } from './routes/settings.js';

export function createApp(): Express {
  const app = express();

  // Cross-Origin Resource Sharing
  app.use(
    cors({
      origin: '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
      allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    })
  );

  // Parse JSON payloads up to 10MB (for export/import)
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Database availability check before executing any business queries
  app.use(requireDbReady);

  // Mount API Endpoints
  app.use('/api/health', healthRouter);
  app.use('/api/auth', authRouter);
  app.use('/api/workout-plans', workoutPlansRouter);
  app.use('/api/exercises', exercisesRouter);
  app.use('/api/workout-sessions', workoutSessionsRouter);
  app.use('/api/personal-records', personalRecordsRouter);
  app.use('/api', analyticsRouter);
  app.use('/api/settings', settingsRouter);
  app.use('/api/users', settingsRouter);

  // 404 Catch-all handler
  app.use((req: Request, res: Response) => {
    res.status(404).json({
      error: `Endpoint not found: ${req.method} ${req.path}`,
    });
  });

  // Global error handler
  app.use((err: any, req: Request, res: Response, next: NextFunction) => {
    console.error('[App Error]', err);
    res.status(500).json({
      error: 'An internal server error occurred.',
      message: process.env.NODE_ENV === 'development' ? err.message : undefined,
    });
  });

  return app;
}
