import mongoose, { Schema, Document } from 'mongoose';

export interface IPlanExercise {
  id: string;
  plan_id: string;
  exercise_id: string;
  exercise_name: string;
  exercise_muscle: string;
  exercise_type: string;
  sort_order: number;
  day_of_week?: number | null;
  target_sets: number;
  target_reps: number;
  target_weight: number;
  target_duration_seconds: number;
  target_distance_km?: number;
  rest_seconds: number;
}

export interface IWorkoutPlan extends Document {
  id: string;
  userId: string;
  name: string;
  description: string;
  color_index: number;
  days_of_week: number[];
  exercises: IPlanExercise[];
  created_at: Date;
  updated_at: Date;
}

const PlanExerciseSchema = new Schema(
  {
    id: { type: String, required: true },
    plan_id: { type: String, required: true },
    exercise_id: { type: String, required: true },
    exercise_name: { type: String, required: true },
    exercise_muscle: { type: String, default: 'fullBody' },
    exercise_type: { type: String, default: 'strength' },
    sort_order: { type: Number, default: 0 },
    day_of_week: { type: Number, required: false, default: null },
    target_sets: { type: Number, default: 3 },
    target_reps: { type: Number, default: 10 },
    target_weight: { type: Number, default: 0 },
    target_duration_seconds: { type: Number, default: 0 },
    target_distance_km: { type: Number, default: 0 },
    rest_seconds: { type: Number, default: 60 },
  },
  { _id: false }
);

const WorkoutPlanSchema: Schema = new Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true, index: true },
    name: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    color_index: { type: Number, default: 0 },
    days_of_week: { type: [Number], default: [] },
    exercises: { type: [PlanExerciseSchema], default: [] },
    created_at: { type: Date, default: Date.now },
    updated_at: { type: Date, default: Date.now },
  },
  {
    timestamps: false,
  }
);

// Compound index for fast user-scoped queries
WorkoutPlanSchema.index({ userId: 1, created_at: -1 });

WorkoutPlanSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.__v;
  delete obj._id;
  return obj;
};

export const WorkoutPlan = mongoose.model<IWorkoutPlan>('WorkoutPlan', WorkoutPlanSchema);
