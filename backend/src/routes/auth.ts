import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { OAuth2Client } from 'google-auth-library';
import { User, IUser } from '../models/User.js';
import { requireAuth } from '../middleware/auth.js';

export const authRouter = Router();

const JWT_SECRET = process.env.JWT_SECRET || 'liftlog_super_secure_jwt_secret_key_2026_x92';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'liftlog_super_secure_jwt_refresh_secret_key_2026_k83';
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '920575978481-6ss9gbv10qu2dlo4888fcu0nu75iktv5.apps.googleusercontent.com';

const googleClient = new OAuth2Client(GOOGLE_CLIENT_ID);

function generateTokens(userId: string) {
  const token = jwt.sign({ userId }, JWT_SECRET, { expiresIn: '7d' });
  const refreshToken = jwt.sign({ userId }, JWT_REFRESH_SECRET, { expiresIn: '30d' });
  return { token, refreshToken };
}

// POST /api/auth/register
authRouter.post('/register', async (req: Request, res: Response) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) {
      return res.status(409).json({ error: 'An account with this email already exists.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const userId = uuidv4();
    const { token, refreshToken } = generateTokens(userId);

    const user = await User.create({
      id: userId,
      name: name.trim(),
      email: normalizedEmail,
      passwordHash,
      avatarUrl: '',
      fitnessGoal: 'Build Strength & Muscle',
      refreshToken,
    });

    res.status(201).json({
      token,
      refreshToken,
      user: user.toJSON(),
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Failed to create account.' });
  }
});

// POST /api/auth/login
authRouter.post('/login', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    if (!user || !user.passwordHash) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const { token, refreshToken } = generateTokens(user.id);
    user.refreshToken = refreshToken;
    await user.save();

    res.json({
      token,
      refreshToken,
      user: user.toJSON(),
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Failed to login.' });
  }
});

// POST /api/auth/google
authRouter.post('/google', async (req: Request, res: Response) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required for Google authentication.' });
    }

    let googlePayload: { sub: string; email?: string; name?: string; picture?: string } | undefined;
    try {
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: GOOGLE_CLIENT_ID,
      });
      const p = ticket.getPayload();
      if (p) {
        googlePayload = {
          sub: p.sub,
          email: p.email,
          name: p.name,
          picture: p.picture,
        };
      }
    } catch (verifyError) {
      // In non-production/testing mode or if simulated test token:
      console.warn('Google verifyIdToken failed directly, checking dev token fallback:', verifyError);
      return res.status(401).json({ error: 'Invalid Google ID token.' });
    }

    if (!googlePayload || !googlePayload.email) {
      return res.status(400).json({ error: 'Could not extract profile details from Google token.' });
    }

    const normalizedEmail = googlePayload.email.trim().toLowerCase();
    let user = await User.findOne({
      $or: [{ googleId: googlePayload.sub }, { email: normalizedEmail }],
    });

    if (!user) {
      const userId = uuidv4();
      const { token, refreshToken } = generateTokens(userId);
      user = await User.create({
        id: userId,
        googleId: googlePayload.sub,
        email: normalizedEmail,
        name: googlePayload.name || 'Google Athlete',
        avatarUrl: googlePayload.picture || '',
        fitnessGoal: 'Build Strength & Muscle',
        refreshToken,
      });

      return res.status(201).json({
        token,
        refreshToken,
        user: user.toJSON(),
      });
    }

    if (!user.googleId) {
      user.googleId = googlePayload.sub;
    }
    if (googlePayload.picture && !user.avatarUrl) {
      user.avatarUrl = googlePayload.picture;
    }

    const { token, refreshToken } = generateTokens(user.id);
    user.refreshToken = refreshToken;
    await user.save();

    res.json({
      token,
      refreshToken,
      user: user.toJSON(),
    });
  } catch (error) {
    console.error('Google Auth error:', error);
    res.status(500).json({ error: 'Failed to authenticate with Google.' });
  }
});

// GET /api/auth/me
authRouter.get('/me', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = await User.findOne({ id: req.userId });
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }
    res.json({ user: user.toJSON() });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to retrieve user profile.' });
  }
});

// POST /api/auth/refresh
authRouter.post('/refresh', async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required.' });
    }

    const payload = jwt.verify(refreshToken, JWT_REFRESH_SECRET) as { userId: string };
    const user = await User.findOne({ id: payload.userId, refreshToken });
    if (!user) {
      return res.status(401).json({ error: 'Invalid or revoked refresh token.' });
    }

    const tokens = generateTokens(user.id);
    user.refreshToken = tokens.refreshToken;
    await user.save();

    res.json(tokens);
  } catch (error) {
    return res.status(401).json({ error: 'Expired or invalid refresh token.' });
  }
});

// POST /api/auth/logout
authRouter.post('/logout', requireAuth, async (req: Request, res: Response) => {
  try {
    await User.updateOne({ id: req.userId }, { $unset: { refreshToken: 1 } });
    res.json({ message: 'Successfully logged out.' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: 'Failed to logout.' });
  }
});
