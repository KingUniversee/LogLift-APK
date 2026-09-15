import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { Exercise } from '../models/Exercise.js';
import { requireAuth } from '../middleware/auth.js';

export const exercisesRouter = Router();

exercisesRouter.use(requireAuth);

const STANDARD_EXERCISES = [
  { id: 'bench-press', name: 'Barbell Bench Press', muscle_group: 'chest', equipment: 'Barbell', exercise_type: 'strength', instructions: 'Lie on flat bench, grip bar slightly wider than shoulders, lower to mid-chest and press up.' },
  { id: 'squat', name: 'Barbell Back Squat', muscle_group: 'legs', equipment: 'Barbell', exercise_type: 'strength', instructions: 'Rest bar on upper traps, descend until thighs are parallel to ground, drive through heels.' },
  { id: 'deadlift', name: 'Conventional Deadlift', muscle_group: 'back', equipment: 'Barbell', exercise_type: 'strength', instructions: 'Hinge hips, grasp bar, keep neutral spine, stand upright locking hips and knees.' },
  { id: 'overhead-press', name: 'Overhead Shoulder Press', muscle_group: 'shoulders', equipment: 'Barbell', exercise_type: 'strength', instructions: 'Stand tall with bar at collarbone, press overhead to full lockout without hyperextending back.' },
  { id: 'barbell-row', name: 'Bent-Over Barbell Row', muscle_group: 'back', equipment: 'Barbell', exercise_type: 'strength', instructions: 'Hinge forward at 45 degrees, pull bar towards lower chest, squeezing shoulder blades.' },
  { id: 'pull-up', name: 'Pull-Up', muscle_group: 'back', equipment: 'Bodyweight', exercise_type: 'bodyweight', instructions: 'Pronated grip, pull body up until chin clears the bar, control descent.' },
  { id: 'push-up', name: 'Push-Up', muscle_group: 'chest', equipment: 'Bodyweight', exercise_type: 'bodyweight', instructions: 'Plank posture, lower chest to floor, push back up while keeping core tight.' },
  { id: 'dumbbell-curl', name: 'Dumbbell Bicep Curl', muscle_group: 'arms', equipment: 'Dumbbell', exercise_type: 'strength', instructions: 'Curl dumbbells upward with elbows pinned at sides, squeeze biceps at peak.' },
  { id: 'tricep-pushdown', name: 'Tricep Rope Pushdown', muscle_group: 'arms', equipment: 'Cable', exercise_type: 'strength', instructions: 'Push rope downward, spreading ends at full extension.' },
  { id: 'lat-pulldown', name: 'Lat Pulldown', muscle_group: 'back', equipment: 'Cable', exercise_type: 'strength', instructions: 'Pull bar smoothly to upper chest, retracting scapulae.' },
  { id: 'leg-press', name: 'Leg Press', muscle_group: 'legs', equipment: 'Machine', exercise_type: 'strength', instructions: 'Feet hip-width on sled, lower knees to 90 degrees, press without locking knees.' },
  { id: 'plank', name: 'Core Plank', muscle_group: 'core', equipment: 'Bodyweight', exercise_type: 'duration', instructions: 'Maintain rigid straight line from head to heels on forearms and toes.' },
  { id: 'running', name: 'Running / Jogging', muscle_group: 'cardio', equipment: 'None', exercise_type: 'distance', instructions: 'Maintain steady cadence and upright posture.' },
];

export async function seedStandardExercisesIfNeeded() {
  const count = await Exercise.countDocuments({ userId: null });
  if (count === 0) {
    const now = new Date();
    await Exercise.insertMany(
      STANDARD_EXERCISES.map((e) => ({
        ...e,
        userId: null,
        is_custom: 0,
        notes: '',
        created_at: now,
      }))
    );
    console.log('[MongoDB] Seeded default exercise library.');
  }
}

// GET /api/exercises
exercisesRouter.get('/', async (req: Request, res: Response) => {
  try {
    const { query, muscleGroup, exerciseType } = req.query;

    const filter: Record<string, any> = {
      $or: [{ userId: null }, { userId: req.userId }],
    };

    if (muscleGroup && typeof muscleGroup === 'string') {
      filter.muscle_group = { $regex: `^${muscleGroup}$`, $options: 'i' };
    }

    if (exerciseType && typeof exerciseType === 'string') {
      filter.exercise_type = { $regex: `^${exerciseType}$`, $options: 'i' };
    }

    if (query && typeof query === 'string' && query.trim().length > 0) {
      const q = query.trim();
      filter.$and = [
        {
          $or: [
            { name: { $regex: q, $options: 'i' } },
            { equipment: { $regex: q, $options: 'i' } },
            { instructions: { $regex: q, $options: 'i' } },
          ],
        },
      ];
    }

    const exercises = await Exercise.find(filter).sort({ name: 1 });
    res.json(exercises.map((e) => e.toJSON()));
  } catch (error) {
    console.error('Fetch exercises error:', error);
    res.status(500).json({ error: 'Failed to retrieve exercises.' });
  }
});

// GET /api/exercises/:id
exercisesRouter.get('/:id', async (req: Request, res: Response) => {
  try {
    const exercise = await Exercise.findOne({
      id: req.params.id,
      $or: [{ userId: null }, { userId: req.userId }],
    });
    if (!exercise) {
      return res.status(404).json({ error: 'Exercise not found.' });
    }
    res.json(exercise.toJSON());
  } catch (error) {
    console.error('Fetch exercise error:', error);
    res.status(500).json({ error: 'Failed to retrieve exercise.' });
  }
});

// POST /api/exercises
exercisesRouter.post('/', async (req: Request, res: Response) => {
  try {
    const data = req.body;
    const exerciseId = data.id || uuidv4();

    const exercise = await Exercise.findOneAndUpdate(
      { id: exerciseId, userId: req.userId },
      {
        id: exerciseId,
        userId: req.userId,
        name: data.name,
        muscle_group: data.muscle_group,
        equipment: data.equipment || 'Barbell',
        exercise_type: data.exercise_type || 'strength',
        instructions: data.instructions || '',
        notes: data.notes || '',
        is_custom: 1,
        created_at: data.created_at ? new Date(data.created_at) : new Date(),
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.status(201).json(exercise.toJSON());
  } catch (error) {
    console.error('Create exercise error:', error);
    res.status(500).json({ error: 'Failed to save exercise.' });
  }
});

// PUT /api/exercises/:id
exercisesRouter.put('/:id', async (req: Request, res: Response) => {
  try {
    const data = req.body;
    const exercise = await Exercise.findOneAndUpdate(
      { id: req.params.id, userId: req.userId },
      {
        name: data.name,
        muscle_group: data.muscle_group,
        equipment: data.equipment,
        exercise_type: data.exercise_type,
        instructions: data.instructions,
        notes: data.notes,
      },
      { new: true }
    );

    if (!exercise) {
      return res.status(404).json({ error: 'Custom exercise not found or cannot modify standard exercises.' });
    }

    res.json(exercise.toJSON());
  } catch (error) {
    console.error('Update exercise error:', error);
    res.status(500).json({ error: 'Failed to update exercise.' });
  }
});

// DELETE /api/exercises/:id
exercisesRouter.delete('/:id', async (req: Request, res: Response) => {
  try {
    const result = await Exercise.findOneAndDelete({ id: req.params.id, userId: req.userId });
    if (!result) {
      return res.status(404).json({ error: 'Custom exercise not found or cannot delete standard exercises.' });
    }
    res.json({ message: 'Exercise deleted successfully.' });
  } catch (error) {
    console.error('Delete exercise error:', error);
    res.status(500).json({ error: 'Failed to delete exercise.' });
  }
});
