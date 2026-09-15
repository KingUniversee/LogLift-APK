import dotenv from 'dotenv';
import http from 'http';
import { createApp } from './app.js';
import { connectDatabase, closeDatabase } from './db/connection.js';
import { seedStandardExercisesIfNeeded } from './routes/exercises.js';

// Load environment variables from .env file
dotenv.config();

const PORT = parseInt(process.env.PORT || '5000', 10);
const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('[FATAL] MONGODB_URI is not defined in environment variables. Server cannot start.');
  process.exit(1);
}

async function bootstrap() {
  try {
    console.log('[LiftLog Server] Initializing database connection to MongoDB Atlas...');
    // Strictly wait for MongoDB connection before accepting any incoming requests
    await connectDatabase(MONGODB_URI!);

    // Ensure default exercise catalog is seeded
    await seedStandardExercisesIfNeeded();

    const app = createApp();
    const server = http.createServer(app);

    server.listen(PORT, '0.0.0.0', () => {
      console.log('====================================================');
      console.log(` LiftLog REST API Server running on port ${PORT}`);
      console.log(` Health check available at: http://localhost:${PORT}/api/health`);
      console.log('====================================================');
    });

    // Graceful shutdown handling
    const shutdown = async (signal: string) => {
      console.log(`\n[LiftLog Server] Received ${signal}. Gracefully closing server and database...`);
      server.close(async () => {
        try {
          await closeDatabase();
          console.log('[LiftLog Server] Database connection closed cleanly.');
          process.exit(0);
        } catch (err) {
          console.error('[LiftLog Server] Error closing database:', err);
          process.exit(1);
        }
      });
    };

    process.on('SIGINT', () => shutdown('SIGINT'));
    process.on('SIGTERM', () => shutdown('SIGTERM'));
  } catch (error) {
    console.error('[FATAL] Failed to initialize backend server:', error);
    process.exit(1);
  }
}

bootstrap();
