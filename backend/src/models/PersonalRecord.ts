import mongoose, { Schema, Document } from 'mongoose';

export interface IPersonalRecord extends Document {
  id: string;
  userId: string;
  exercise_id: string;
  exercise_name: string;
  record_type: string;
  value: number;
  session_id: string;
  achieved_at: Date;
}

const PersonalRecordSchema: Schema = new Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true, index: true },
    exercise_id: { type: String, required: true, index: true },
    exercise_name: { type: String, required: true },
    record_type: { type: String, required: true, index: true },
    value: { type: Number, required: true },
    session_id: { type: String, required: true },
    achieved_at: { type: Date, required: true },
  },
  {
    timestamps: false,
  }
);

PersonalRecordSchema.index({ userId: 1, exercise_id: 1, record_type: 1 });

PersonalRecordSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.__v;
  delete obj._id;
  return obj;
};

export const PersonalRecord = mongoose.model<IPersonalRecord>('PersonalRecord', PersonalRecordSchema);
