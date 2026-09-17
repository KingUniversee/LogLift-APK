import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { WorkoutPlan } from '../models/WorkoutPlan.js';
import { requireAuth } from '../middleware/auth.js';

export const workoutPlansRouter = Router();

workoutPlansRouter.use(requireAuth);

// GET /api/workout-plans
workoutPlansRouter.get('/', async (req: Request, res: Response) => {
  try {
    const { query } = req.query;
    const filter: Record<string, any> = { userId: req.userId };

    if (query && typeof query === 'string' && query.trim().length > 0) {
      const q = query.trim();
      filter.$or = [
        { name: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
      ];
    }

    const plans = await WorkoutPlan.find(filter).sort({ created_at: -1 });
    res.json(plans.map((p) => p.toJSON()));
  } catch (error) {
    console.error('Fetch workout plans error:', error);
    res.status(500).json({ error: 'Failed to retrieve workout plans.' });
  }
});

// GET /api/workout-plans/:id
workoutPlansRouter.get('/:id', async (req: Request, res: Response) => {
  try {
    const plan = await WorkoutPlan.findOne({ id: req.params.id, userId: req.userId });
    if (!plan) {
      return res.status(404).json({ error: 'Workout plan not found.' });
    }
    res.json(plan.toJSON());
  } catch (error) {
    console.error('Fetch plan error:', error);
    res.status(500).json({ error: 'Failed to retrieve workout plan.' });
  }
});

// POST /api/workout-plans
workoutPlansRouter.post('/', async (req: Request, res: Response) => {
  try {
    const data = req.body;
    const planId = data.id || uuidv4();
    const now = new Date();

    const exercises = (data.exercises || []).map((e: any, idx: number) => ({
      id: e.id || uuidv4(),
      plan_id: planId,
      exercise_id: e.exercise_id,
      exercise_name: e.exercise_name,
      exercise_muscle: e.exercise_muscle || 'fullBody',
      exercise_type: e.exercise_type || 'strength',
      sort_order: e.sort_order ?? idx,
      day_of_week: e.day_of_week !== undefined ? e.day_of_week : null,
      target_sets: e.target_sets ?? 3,
      target_reps: e.target_reps ?? 10,
      target_weight: e.target_weight ?? 0,
      target_duration_seconds: e.target_duration_seconds ?? 0,
      target_distance_km: e.target_distance_km ?? 0,
      rest_seconds: e.rest_seconds ?? 60,
    }));

    const plan = await WorkoutPlan.findOneAndUpdate(
      { id: planId, userId: req.userId },
      {
        id: planId,
        userId: req.userId,
        name: data.name || 'Custom Plan',
        description: data.description || '',
        color_index: data.color_index ?? 0,
        days_of_week: data.days_of_week || [],
        exercises,
        created_at: data.created_at ? new Date(data.created_at) : now,
        updated_at: now,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.status(201).json(plan.toJSON());
  } catch (error) {
    console.error('Create plan error:', error);
    res.status(500).json({ error: 'Failed to save workout plan.' });
  }
});

// PUT /api/workout-plans/:id
workoutPlansRouter.put('/:id', async (req: Request, res: Response) => {
  try {
    const data = req.body;
    const planId = req.params.id;
    const now = new Date();

    const exercises = (data.exercises || []).map((e: any, idx: number) => ({
      id: e.id || uuidv4(),
      plan_id: planId,
      exercise_id: e.exercise_id,
      exercise_name: e.exercise_name,
      exercise_muscle: e.exercise_muscle || 'fullBody',
      exercise_type: e.exercise_type || 'strength',
      sort_order: e.sort_order ?? idx,
      day_of_week: e.day_of_week !== undefined ? e.day_of_week : null,
      target_sets: e.target_sets ?? 3,
      target_reps: e.target_reps ?? 10,
      target_weight: e.target_weight ?? 0,
      target_duration_seconds: e.target_duration_seconds ?? 0,
      target_distance_km: e.target_distance_km ?? 0,
      rest_seconds: e.rest_seconds ?? 60,
    }));

    const plan = await WorkoutPlan.findOneAndUpdate(
      { id: planId, userId: req.userId },
      {
        id: planId,
        userId: req.userId,
        name: data.name,
        description: data.description,
        color_index: data.color_index,
        days_of_week: data.days_of_week,
        exercises,
        updated_at: now,
      },
      { new: true, upsert: true }
    );

    res.json(plan.toJSON());
  } catch (error) {
    console.error('Update plan error:', error);
    res.status(500).json({ error: 'Failed to update workout plan.' });
  }
});

// DELETE /api/workout-plans/:id
workoutPlansRouter.delete('/:id', async (req: Request, res: Response) => {
  try {
    const result = await WorkoutPlan.findOneAndDelete({ id: req.params.id, userId: req.userId });
    if (!result) {
      return res.status(404).json({ error: 'Workout plan not found or access denied.' });
    }
    res.json({ message: 'Workout plan deleted successfully.' });
  } catch (error) {
    console.error('Delete plan error:', error);
    res.status(500).json({ error: 'Failed to delete workout plan.' });
  }
});

// POST /api/workout-plans/:id/duplicate
workoutPlansRouter.post('/:id/duplicate', async (req: Request, res: Response) => {
  try {
    const original = await WorkoutPlan.findOne({ id: req.params.id, userId: req.userId });
    if (!original) {
      return res.status(404).json({ error: 'Original workout plan not found.' });
    }

    const newId = uuidv4();
    const now = new Date();
    const newExercises = original.exercises.map((e) => ({
      ...e,
      id: uuidv4(),
      plan_id: newId,
    }));

    const duplicated = await WorkoutPlan.create({
      id: newId,
      userId: req.userId,
      name: `${original.name} (Copy)`,
      description: original.description,
      color_index: (original.color_index + 1) % 4,
      days_of_week: [...original.days_of_week],
      exercises: newExercises,
      created_at: now,
      updated_at: now,
    });

    res.status(201).json(duplicated.toJSON());
  } catch (error) {
    console.error('Duplicate plan error:', error);
    res.status(500).json({ error: 'Failed to duplicate workout plan.' });
  }
});
