import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { PersonalRecord } from '../models/PersonalRecord.js';
import { requireAuth } from '../middleware/auth.js';

export const personalRecordsRouter = Router();

personalRecordsRouter.use(requireAuth);

// GET /api/personal-records
personalRecordsRouter.get('/', async (req: Request, res: Response) => {
  try {
    const { exerciseId, recordType, best } = req.query;
    const filter: Record<string, any> = { userId: req.userId };

    if (exerciseId && typeof exerciseId === 'string') {
      filter.exercise_id = exerciseId;
    }

    if (recordType && typeof recordType === 'string') {
      filter.record_type = recordType;
    }

    if (best === 'true' && exerciseId && recordType) {
      const bestRecord = await PersonalRecord.findOne(filter).sort({ value: -1 });
      if (!bestRecord) {
        return res.status(204).send();
      }
      return res.json(bestRecord.toJSON());
    }

    const prs = await PersonalRecord.find(filter).sort({ achieved_at: -1 });
    res.json(prs.map((p) => p.toJSON()));
  } catch (error) {
    console.error('Fetch PRs error:', error);
    res.status(500).json({ error: 'Failed to retrieve personal records.' });
  }
});

// POST /api/personal-records
personalRecordsRouter.post('/', async (req: Request, res: Response) => {
  try {
    const data = req.body;
    const prId = data.id || uuidv4();

    const pr = await PersonalRecord.findOneAndUpdate(
      { id: prId, userId: req.userId },
      {
        id: prId,
        userId: req.userId,
        exercise_id: data.exercise_id,
        exercise_name: data.exercise_name || 'Exercise',
        record_type: data.record_type,
        value: Number(data.value) || 0,
        session_id: data.session_id,
        achieved_at: data.achieved_at ? new Date(data.achieved_at) : new Date(),
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.status(201).json(pr.toJSON());
  } catch (error) {
    console.error('Save PR error:', error);
    res.status(500).json({ error: 'Failed to save personal record.' });
  }
});

// DELETE /api/personal-records/:id
personalRecordsRouter.delete('/:id', async (req: Request, res: Response) => {
  try {
    const result = await PersonalRecord.findOneAndDelete({ id: req.params.id, userId: req.userId });
    if (!result) {
      return res.status(404).json({ error: 'Personal record not found.' });
    }
    res.json({ message: 'Personal record deleted.' });
  } catch (error) {
    console.error('Delete PR error:', error);
    res.status(500).json({ error: 'Failed to delete personal record.' });
  }
});

// DELETE /api/personal-records/session/:sessionId
personalRecordsRouter.delete('/session/:sessionId', async (req: Request, res: Response) => {
  try {
    await PersonalRecord.deleteMany({ session_id: req.params.sessionId, userId: req.userId });
    res.json({ message: 'Session personal records deleted.' });
  } catch (error) {
    console.error('Delete session PRs error:', error);
    res.status(500).json({ error: 'Failed to delete session records.' });
  }
});
