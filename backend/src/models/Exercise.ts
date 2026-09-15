import mongoose, { Schema, Document } from 'mongoose';

export interface IExercise extends Document {
  id: string;
  userId?: string | null;
  name: string;
  muscle_group: string;
  equipment: string;
  exercise_type: string;
  instructions: string;
  notes: string;
  is_custom: number;
  created_at: Date;
}

const ExerciseSchema: Schema = new Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    userId: { type: String, default: null, index: true },
    name: { type: String, required: true, trim: true },
    muscle_group: { type: String, required: true },
    equipment: { type: String, default: 'Barbell' },
    exercise_type: { type: String, default: 'strength' },
    instructions: { type: String, default: '' },
    notes: { type: String, default: '' },
    is_custom: { type: Number, default: 1 },
    created_at: { type: Date, default: Date.now },
  },
  {
    timestamps: false,
  }
);

ExerciseSchema.index({ userId: 1, name: 1 });

ExerciseSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.__v;
  delete obj._id;
  return obj;
};

export const Exercise = mongoose.model<IExercise>('Exercise', ExerciseSchema);
