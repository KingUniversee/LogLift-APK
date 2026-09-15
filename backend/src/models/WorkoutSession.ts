import mongoose, { Schema, Document } from 'mongoose';

export interface ISetLog {
  id: string;
  exercise_log_id: string;
  set_number: number;
  weight_kg: number;
  reps: number;
  duration_seconds: number;
  distance_km: number;
  completed: number;
  notes: string;
}

export interface IExerciseLog {
  id: string;
  session_id: string;
  exercise_id: string;
  exercise_name: string;
  exercise_type: string;
  sort_order: number;
  sets: ISetLog[];
}

export interface IWorkoutSession extends Document {
  id: string;
  userId: string;
  plan_id?: string | null;
  plan_name: string;
  started_at: Date;
  completed_at?: Date | null;
  duration_seconds: number;
  status: string;
  note: string;
  logs: IExerciseLog[];
}

const SetLogSchema = new Schema(
  {
    id: { type: String, required: true },
    exercise_log_id: { type: String, required: true },
    set_number: { type: Number, default: 1 },
    weight_kg: { type: Number, default: 0 },
    reps: { type: Number, default: 0 },
    duration_seconds: { type: Number, default: 0 },
    distance_km: { type: Number, default: 0 },
    completed: { type: Number, default: 1 },
    notes: { type: String, default: '' },
  },
  { _id: false }
);

const ExerciseLogSchema = new Schema(
  {
    id: { type: String, required: true },
    session_id: { type: String, required: true },
    exercise_id: { type: String, required: true },
    exercise_name: { type: String, required: true },
    exercise_type: { type: String, default: 'strength' },
    sort_order: { type: Number, default: 0 },
    sets: { type: [SetLogSchema], default: [] },
  },
  { _id: false }
);

const WorkoutSessionSchema: Schema = new Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true, index: true },
    plan_id: { type: String, default: null, index: true },
    plan_name: { type: String, required: true },
    started_at: { type: Date, required: true },
    completed_at: { type: Date, default: null },
    duration_seconds: { type: Number, default: 0 },
    status: { type: String, default: 'completed', index: true },
    note: { type: String, default: '' },
    logs: { type: [ExerciseLogSchema], default: [] },
  },
  {
    timestamps: false,
  }
);

WorkoutSessionSchema.index({ userId: 1, status: 1, started_at: -1 });

WorkoutSessionSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.__v;
  delete obj._id;
  return obj;
};

export const WorkoutSession = mongoose.model<IWorkoutSession>('WorkoutSession', WorkoutSessionSchema);
