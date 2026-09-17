import { Router, Request, Response } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { AppSettings } from '../models/AppSettings.js';
import { User } from '../models/User.js';
import { WorkoutPlan } from '../models/WorkoutPlan.js';
import { Exercise } from '../models/Exercise.js';
import { WorkoutSession } from '../models/WorkoutSession.js';
import { PersonalRecord } from '../models/PersonalRecord.js';
import { requireAuth } from '../middleware/auth.js';

export const settingsRouter = Router();

settingsRouter.use(requireAuth);

// Configure local storage for user uploaded avatars
const avatarUploadDir = path.join(process.cwd(), 'uploads', 'avatars');

const avatarStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    if (!fs.existsSync(avatarUploadDir)) {
      fs.mkdirSync(avatarUploadDir, { recursive: true });
    }
    cb(null, avatarUploadDir);
  },
  filename: (req: Request, file, cb) => {
    let ext = path.extname(file.originalname).toLowerCase();
    if (!ext || ext === '') {
      if (file.mimetype === 'image/png') ext = '.png';
      else if (file.mimetype === 'image/webp') ext = '.webp';
      else ext = '.jpg';
    }
    const safeExt = ['.jpg', '.jpeg', '.png', '.webp'].includes(ext) ? ext : '.jpg';
    const filename = `${req.userId}-${Date.now()}-${uuidv4().substring(0, 8)}${safeExt}`;
    cb(null, filename);
  },
});

const avatarUpload = multer({
  storage: avatarStorage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
  fileFilter: (_req, file, cb) => {
    const allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
    const ext = path.extname(file.originalname).toLowerCase();
    const allowedExts = ['.jpg', '.jpeg', '.png', '.webp'];
    if (allowedMimes.includes(file.mimetype) || (file.mimetype === 'application/octet-stream' && allowedExts.includes(ext))) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG, PNG, and WebP images are allowed.'));
    }
  },
});

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
        haptics_enabled: 1,
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
        haptics_enabled: data.haptics_enabled ?? 1,
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

// POST /api/users/avatar
settingsRouter.post('/avatar', (req: Request, res: Response) => {
  avatarUpload.single('avatar')(req, res, async (err: any) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ error: 'Image size exceeds maximum allowed size of 5MB.' });
      }
      return res.status(400).json({ error: err.message });
    } else if (err) {
      return res.status(400).json({ error: err.message || 'Failed to upload image.' });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided in "avatar" field.' });
    }

    try {
      const user = await User.findOne({ id: req.userId });
      if (!user) {
        try {
          fs.unlinkSync(req.file.path);
        } catch (_) {}
        return res.status(404).json({ error: 'User not found.' });
      }

      // Safely remove previous local avatar file if it was uploaded to this server
      if (user.avatarUrl && user.avatarUrl.includes('/uploads/avatars/')) {
        const oldFilename = path.basename(user.avatarUrl);
        if (oldFilename && !oldFilename.includes('..') && oldFilename.startsWith(`${req.userId}-`)) {
          const oldFilePath = path.join(avatarUploadDir, oldFilename);
          if (fs.existsSync(oldFilePath)) {
            try {
              fs.unlinkSync(oldFilePath);
            } catch (unlinkErr) {
              console.warn('Could not remove previous avatar file:', unlinkErr);
            }
          }
        }
      }

      const protocol = req.headers['x-forwarded-proto'] || req.protocol;
      const host = req.get('host');
      const avatarUrl = `${protocol}://${host}/uploads/avatars/${req.file.filename}`;

      user.avatarUrl = avatarUrl;
      await user.save();

      res.status(200).json({
        avatar_url: avatarUrl,
        user: user.toJSON(),
      });
    } catch (error) {
      console.error('Avatar upload error:', error);
      res.status(500).json({ error: 'Failed to process avatar upload.' });
    }
  });
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
