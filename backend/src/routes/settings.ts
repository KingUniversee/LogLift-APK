import { Router, Request, Response } from 'express';
import { AppSettings } from '../models/AppSettings.js';
import { User } from '../models/User.js';
import { WorkoutPlan } from '../models/WorkoutPlan.js';
import { Exercise } from '../models/Exercise.js';
import { WorkoutSession } from '../models/WorkoutSession.js';
import { PersonalRecord } from '../models/PersonalRecord.js';
import { requireAuth } from '../middleware/auth.js';

export const settingsRouter = Router();

settingsRouter.use(requireAuth);

// GET /api/settings
settingsRouter.get('/', async (req: Request, res: Response) => {
  try {
    let settings = await AppSettings.findOne({ userId: req.userId });
    if (!settings) {
      settings = await AppSettings.create({
        id: 'settings_default',
        userId: req.userId,
        appearance: 'dark',
        weight_unit: 'kg',
        distance_unit: 'km',
        default_rest_seconds: 60,
        notifications_enabled: 1,
        reminders_enabled: 1,
      });
    }
    res.json(settings.toJSON());
  } catch (error) {
    console.error('Fetch settings error:', error);
    res.status(500).json({ error: 'Failed to retrieve settings.' });
  }
});

// PUT /api/settings
settingsRouter.put('/', async (req: Request, res: Response) => {
  try {
    const data = req.body;
    const settings = await AppSettings.findOneAndUpdate(
      { userId: req.userId },
      {
        id: 'settings_default',
        userId: req.userId,
        appearance: data.appearance || 'dark',
        weight_unit: data.weight_unit || 'kg',
        distance_unit: data.distance_unit || 'km',
        default_rest_seconds: data.default_rest_seconds ?? 60,
        notifications_enabled: data.notifications_enabled ?? 1,
        reminders_enabled: data.reminders_enabled ?? 1,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.json(settings.toJSON());
  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({ error: 'Failed to update settings.' });
  }
});

// PUT /api/users/profile (can be mounted under /api/users or /api/settings/profile)
settingsRouter.put('/profile', async (req: Request, res: Response) => {
  try {
    const { name, avatar_url, fitness_goal } = req.body;
    const updateFields: Record<string, any> = {};
    if (name) updateFields.name = name.trim();
    if (avatar_url !== undefined) updateFields.avatarUrl = avatar_url;
    if (fitness_goal) updateFields.fitnessGoal = fitness_goal;

    const user = await User.findOneAndUpdate(
      { id: req.userId },
      { $set: updateFields },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    res.json({ user: user.toJSON() });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile.' });
  }
});

// GET /api/settings/export
settingsRouter.get('/export', async (req: Request, res: Response) => {
  try {
    const [exercises, plans, sessions, prs, settings, user] = await Promise.all([
      Exercise.find({ userId: req.userId }),
      WorkoutPlan.find({ userId: req.userId }),
      WorkoutSession.find({ userId: req.userId }),
      PersonalRecord.find({ userId: req.userId }),
      AppSettings.findOne({ userId: req.userId }),
      User.findOne({ id: req.userId }),
    ]);

    res.json({
      version: 1,
      exported_at: new Date().toISOString(),
      user: user ? user.toJSON() : null,
      exercises: exercises.map((e) => e.toJSON()),
      workout_plans: plans.map((p) => p.toJSON()),
      workout_sessions: sessions.map((s) => s.toJSON()),
      personal_records: prs.map((p) => p.toJSON()),
      app_settings: settings ? settings.toJSON() : null,
    });
  } catch (error) {
    console.error('Export error:', error);
    res.status(500).json({ error: 'Failed to export data.' });
  }
});

// POST /api/settings/import
settingsRouter.post('/import', async (req: Request, res: Response) => {
  try {
    const data = req.body;
    if (Array.isArray(data.exercises)) {
      for (const item of data.exercises) {
        await Exercise.findOneAndUpdate(
          { id: item.id, userId: req.userId },
          { ...item, userId: req.userId },
          { upsert: true }
        );
      }
    }
    if (Array.isArray(data.workout_plans)) {
      for (const item of data.workout_plans) {
        await WorkoutPlan.findOneAndUpdate(
          { id: item.id, userId: req.userId },
          { ...item, userId: req.userId },
          { upsert: true }
        );
      }
    }
    if (Array.isArray(data.workout_sessions)) {
      for (const item of data.workout_sessions) {
        await WorkoutSession.findOneAndUpdate(
          { id: item.id, userId: req.userId },
          { ...item, userId: req.userId },
          { upsert: true }
        );
      }
    }
    if (Array.isArray(data.personal_records)) {
      for (const item of data.personal_records) {
        await PersonalRecord.findOneAndUpdate(
          { id: item.id, userId: req.userId },
          { ...item, userId: req.userId },
          { upsert: true }
        );
      }
    }
    res.json({ success: true, message: 'Data imported successfully.' });
  } catch (error) {
    console.error('Import error:', error);
    res.status(500).json({ error: 'Failed to import data.' });
  }
});

// DELETE /api/settings/delete-all
settingsRouter.delete('/delete-all', async (req: Request, res: Response) => {
  try {
    await Promise.all([
      Exercise.deleteMany({ userId: req.userId }),
      WorkoutPlan.deleteMany({ userId: req.userId }),
      WorkoutSession.deleteMany({ userId: req.userId }),
      PersonalRecord.deleteMany({ userId: req.userId }),
      AppSettings.deleteOne({ userId: req.userId }),
    ]);

    res.json({ success: true, message: 'All user data erased.' });
  } catch (error) {
    console.error('Delete all error:', error);
    res.status(500).json({ error: 'Failed to erase data.' });
  }
});
