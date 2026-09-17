import mongoose, { Schema, Document } from 'mongoose';

export interface IAppSettings extends Document {
  id: string;
  userId: string;
  appearance: string;
  weight_unit: string;
  distance_unit: string;
  default_rest_seconds: number;
  notifications_enabled: number;
  reminders_enabled: number;
  haptics_enabled: number;
}

const AppSettingsSchema: Schema = new Schema(
  {
    id: { type: String, required: true, default: 'settings_default' },
    userId: { type: String, required: true, unique: true, index: true },
    appearance: { type: String, default: 'dark' },
    weight_unit: { type: String, default: 'kg' },
    distance_unit: { type: String, default: 'km' },
    default_rest_seconds: { type: Number, default: 60 },
    notifications_enabled: { type: Number, default: 1 },
    reminders_enabled: { type: Number, default: 1 },
    haptics_enabled: { type: Number, default: 1 },
  },
  {
    timestamps: false,
  }
);

AppSettingsSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.__v;
  delete obj._id;
  return obj;
};

export const AppSettings = mongoose.model<IAppSettings>('AppSettings', AppSettingsSchema);
