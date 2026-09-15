import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { WorkoutSession } from '../models/WorkoutSession.js';
import { requireAuth } from '../middleware/auth.js';

export const workoutSessionsRouter = Router();

workoutSessionsRouter.use(requireAuth);

// GET /api/workout-sessions/active
workoutSessionsRouter.get('/active', async (req: Request, res: Response) => {
  try {
    const session = await WorkoutSession.findOne({
      userId: req.userId,
      status: 'inProgress',
    }).sort({ started_at: -1 });

    if (!session) {
      return res.status(204).send();
    }
    res.json(session.toJSON());
  } catch (error) {
    console.error('Fetch active session error:', error);
    res.status(500).json({ error: 'Failed to retrieve active workout session.' });
  }
});

// GET /api/workout-sessions
workoutSessionsRouter.get('/', async (req: Request, res: Response) => {
  try {
    const { status, planId, exerciseId, startDate, endDate, query, limit, offset } = req.query;

    const filter: Record<string, any> = { userId: req.userId };

    if (status && typeof status === 'string') {
      filter.status = status;
    }

    if (planId && typeof planId === 'string' && planId.length > 0) {
      filter.plan_id = planId;
    }

    if (startDate) {
      filter.started_at = { ...(filter.started_at || {}), $gte: new Date(startDate as string) };
    }

    if (endDate) {
      filter.started_at = { ...(filter.started_at || {}), $lte: new Date(endDate as string) };
    }

    if (query && typeof query === 'string' && query.trim().length > 0) {
      const q = query.trim();
      filter.$or = [
        { plan_name: { $regex: q, $options: 'i' } },
        { note: { $regex: q, $options: 'i' } },
      ];
    }

    if (exerciseId && typeof exerciseId === 'string' && exerciseId.length > 0) {
      filter['logs.exercise_id'] = exerciseId;
    }

    const queryBuilder = WorkoutSession.find(filter).sort({ started_at: -1 });

    if (offset) {
      queryBuilder.skip(parseInt(offset as string, 10));
    }

    if (limit) {
      queryBuilder.limit(parseInt(limit as string, 10));
    }

    const sessions = await queryBuilder.exec();
    res.json(sessions.map((s) => s.toJSON()));
  } catch (error) {
    console.error('Fetch workout sessions error:', error);
    res.status(500).json({ error: 'Failed to retrieve workout sessions.' });
  }
});

// GET /api/workout-sessions/:id
workoutSessionsRouter.get('/:id', async (req: Request, res: Response) => {
  try {
    const session = await WorkoutSession.findOne({ id: req.params.id, userId: req.userId });
    if (!session) {
      return res.status(404).json({ error: 'Workout session not found.' });
    }
    res.json(session.toJSON());
  } catch (error) {
    console.error('Fetch session error:', error);
    res.status(500).json({ error: 'Failed to retrieve workout session.' });
  }
});

// POST /api/workout-sessions
workoutSessionsRouter.post('/', async (req: Request, res: Response) => {
  try {
    const data = req.body;
    const sessionId = data.id || uuidv4();

    const logs = (data.logs || []).map((l: any, lIdx: number) => {
      const logId = l.id || uuidv4();
      const sets = (l.sets || []).map((s: any, sIdx: number) => ({
        id: s.id || uuidv4(),
        exercise_log_id: logId,
        set_number: s.set_number ?? sIdx + 1,
        weight_kg: Number(s.weight_kg) || 0,
        reps: Number(s.reps) || 0,
        duration_seconds: Number(s.duration_seconds) || 0,
        distance_km: Number(s.distance_km) || 0,
        completed: s.completed ? 1 : 0,
        notes: s.notes || '',
      }));

      return {
        id: logId,
        session_id: sessionId,
        exercise_id: l.exercise_id,
        exercise_name: l.exercise_name || 'Exercise',
        exercise_type: l.exercise_type || 'strength',
        sort_order: l.sort_order ?? lIdx,
        sets,
      };
    });

    const session = await WorkoutSession.findOneAndUpdate(
      { id: sessionId, userId: req.userId },
      {
        id: sessionId,
        userId: req.userId,
        plan_id: data.plan_id || null,
        plan_name: data.plan_name || 'Workout',
        started_at: data.started_at ? new Date(data.started_at) : new Date(),
        completed_at: data.completed_at ? new Date(data.completed_at) : null,
        duration_seconds: Number(data.duration_seconds) || 0,
        status: data.status || 'completed',
        note: data.note || '',
        logs,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.status(201).json(session.toJSON());
  } catch (error) {
    console.error('Save session error:', error);
    res.status(500).json({ error: 'Failed to save workout session.' });
  }
});

// PUT /api/workout-sessions/:id
workoutSessionsRouter.put('/:id', async (req: Request, res: Response) => {
  try {
    const data = req.body;
    const sessionId = req.params.id;

    const logs = (data.logs || []).map((l: any, lIdx: number) => {
      const logId = l.id || uuidv4();
      const sets = (l.sets || []).map((s: any, sIdx: number) => ({
        id: s.id || uuidv4(),
        exercise_log_id: logId,
        set_number: s.set_number ?? sIdx + 1,
        weight_kg: Number(s.weight_kg) || 0,
        reps: Number(s.reps) || 0,
        duration_seconds: Number(s.duration_seconds) || 0,
        distance_km: Number(s.distance_km) || 0,
        completed: s.completed ? 1 : 0,
        notes: s.notes || '',
      }));

      return {
        id: logId,
        session_id: sessionId,
        exercise_id: l.exercise_id,
        exercise_name: l.exercise_name || 'Exercise',
        exercise_type: l.exercise_type || 'strength',
        sort_order: l.sort_order ?? lIdx,
        sets,
      };
    });

    const session = await WorkoutSession.findOneAndUpdate(
      { id: sessionId, userId: req.userId },
      {
        plan_id: data.plan_id || null,
        plan_name: data.plan_name,
        started_at: data.started_at ? new Date(data.started_at) : undefined,
        completed_at: data.completed_at ? new Date(data.completed_at) : null,
        duration_seconds: Number(data.duration_seconds) || 0,
        status: data.status,
        note: data.note,
        logs,
      },
      { new: true }
    );

    if (!session) {
      return res.status(404).json({ error: 'Workout session not found.' });
    }

    res.json(session.toJSON());
  } catch (error) {
    console.error('Update session error:', error);
    res.status(500).json({ error: 'Failed to update workout session.' });
  }
});

// DELETE /api/workout-sessions/:id
workoutSessionsRouter.delete('/:id', async (req: Request, res: Response) => {
  try {
    const result = await WorkoutSession.findOneAndDelete({ id: req.params.id, userId: req.userId });
    if (!result) {
      return res.status(404).json({ error: 'Workout session not found or access denied.' });
    }
    res.json({ message: 'Workout session deleted successfully.' });
  } catch (error) {
    console.error('Delete session error:', error);
    res.status(500).json({ error: 'Failed to delete workout session.' });
  }
});
