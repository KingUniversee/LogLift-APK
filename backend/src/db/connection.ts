import mongoose from 'mongoose';

let isConnecting = false;

/**
 * Singleton database connection manager for MongoDB Atlas using Mongoose.
 * Ensures a single reusable connection across the application lifecycle.
 */
export async function connectDatabase(uri: string): Promise<typeof mongoose> {
  // If already connected, reuse existing connection
  if (mongoose.connection.readyState === 1) {
    return mongoose;
  }

  // If connection is in-flight, wait for it instead of opening another
  if (isConnecting) {
    await new Promise<void>((resolve, reject) => {
      const onConnected = () => {
        cleanup();
        resolve();
      };
      const onError = (err: Error) => {
        cleanup();
        reject(err);
      };
      const cleanup = () => {
        mongoose.connection.off('connected', onConnected);
        mongoose.connection.off('error', onError);
      };
      mongoose.connection.once('connected', onConnected);
      mongoose.connection.once('error', onError);
    });
    return mongoose;
  }

  isConnecting = true;

  // Set up connection lifecycle event listeners
  mongoose.connection.on('connected', () => {
    console.log('[MongoDB] Connected successfully to Atlas.');
  });

  mongoose.connection.on('error', (err) => {
    console.error('[MongoDB] Connection error occurred:', err);
  });

  mongoose.connection.on('disconnected', () => {
    console.warn('[MongoDB] Disconnected from Atlas. Awaiting automatic reconnection...');
  });

  mongoose.connection.on('reconnected', () => {
    console.log('[MongoDB] Reconnected to Atlas successfully.');
  });

  try {
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 15000,
      autoIndex: true,
      maxPoolSize: 20,
    });
    return mongoose;
  } catch (error) {
    console.error('[MongoDB] Initial connection failed:', error);
    throw error;
  } finally {
    isConnecting = false;
  }
}

export function isDbReady(): boolean {
  return mongoose.connection.readyState === 1;
}

export function getDbState(): string {
  switch (mongoose.connection.readyState) {
    case 0:
      return 'disconnected';
    case 1:
      return 'connected';
    case 2:
      return 'connecting';
    case 3:
      return 'disconnecting';
    default:
      return 'unknown';
  }
}

export async function closeDatabase(): Promise<void> {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.connection.close();
  }
}
