import { Router, Request, Response } from 'express';
import { WorkoutSession } from '../models/WorkoutSession.js';
import { PersonalRecord } from '../models/PersonalRecord.js';
import { requireAuth } from '../middleware/auth.js';

export const analyticsRouter = Router();

analyticsRouter.use(requireAuth);

// GET /api/history
analyticsRouter.get('/history', async (req: Request, res: Response) => {
  try {
    const sessions = await WorkoutSession.find({
      userId: req.userId,
      status: 'completed',
    }).sort({ started_at: -1 });

    res.json(sessions.map((s) => s.toJSON()));
  } catch (error) {
    console.error('Fetch history error:', error);
    res.status(500).json({ error: 'Failed to retrieve workout history.' });
  }
});

// GET /api/statistics
analyticsRouter.get('/statistics', async (req: Request, res: Response) => {
  try {
    const sessions = await WorkoutSession.find({
      userId: req.userId,
      status: 'completed',
    }).sort({ started_at: -1 });

    const prs = await PersonalRecord.find({ userId: req.userId });

    const totalWorkouts = sessions.length;
    let totalVolumeKg = 0;
    let totalReps = 0;
    let totalDurationSeconds = 0;

    for (const session of sessions) {
      totalDurationSeconds += session.duration_seconds || 0;
      for (const log of session.logs || []) {
        for (const set of log.sets || []) {
          if (set.completed) {
            totalReps += set.reps || 0;
            totalVolumeKg += (set.weight_kg || 0) * (set.reps || 0);
          }
        }
      }
    }

    res.json({
      totalWorkouts,
      totalVolumeKg,
      totalReps,
      totalDurationSeconds,
      totalPRs: prs.length,
      recentSessionsCount: sessions.slice(0, 10).length,
    });
  } catch (error) {
    console.error('Compute stats error:', error);
    res.status(500).json({ error: 'Failed to retrieve statistics.' });
  }
});

// GET /api/reports
analyticsRouter.get('/reports', async (req: Request, res: Response) => {
  try {
    const sessions = await WorkoutSession.find({
      userId: req.userId,
      status: 'completed',
    }).sort({ started_at: -1 });

    const prs = await PersonalRecord.find({ userId: req.userId });

    const muscleBreakdown: Record<string, number> = {};
    for (const session of sessions) {
      for (const log of session.logs || []) {
        const muscle = log.exercise_type || 'General';
        muscleBreakdown[muscle] = (muscleBreakdown[muscle] || 0) + 1;
      }
    }

    res.json({
      generatedAt: new Date().toISOString(),
      completedSessionsCount: sessions.length,
      personalRecordsCount: prs.length,
      muscleBreakdown,
    });
  } catch (error) {
    console.error('Fetch reports error:', error);
    res.status(500).json({ error: 'Failed to retrieve reports.' });
  }
});
