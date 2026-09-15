import mongoose, { Schema, Document } from 'mongoose';

export interface IUser extends Document {
  id: string;
  name: string;
  email: string;
  passwordHash?: string;
  googleId?: string;
  appleId?: string;
  avatarUrl: string;
  fitnessGoal: string;
  refreshToken?: string;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema: Schema = new Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true, index: true },
    passwordHash: { type: String },
    googleId: { type: String, sparse: true, index: true },
    appleId: { type: String, sparse: true, index: true },
    avatarUrl: { type: String, default: '' },
    fitnessGoal: { type: String, default: 'Build Strength & Muscle' },
    refreshToken: { type: String },
  },
  {
    timestamps: { createdAt: 'createdAt', updatedAt: 'updatedAt' },
  }
);

UserSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.passwordHash;
  delete obj.refreshToken;
  delete obj.__v;
  delete obj._id;
  return obj;
};

export const User = mongoose.model<IUser>('User', UserSchema);
