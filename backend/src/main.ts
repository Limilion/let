import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import * as express from 'express';
import { join } from 'path';
import { mkdirSync } from 'fs';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS
  app.enableCors();

  // Increase payload limits for images/videos
  app.use(express.json({ limit: '50mb' }));
  app.use(express.urlencoded({ limit: '50mb', extended: true }));

  // Integrated global validation pipe
  app.useGlobalPipes(new ValidationPipe());

  // Set global prefix
  app.setGlobalPrefix('api');

  const uploadsDir = join(process.cwd(), 'uploads');
  mkdirSync(uploadsDir, { recursive: true });

  // Serve static files (uploads)
  app.use('/uploads', express.static(uploadsDir));

  const PORT = process.env.PORT || 3000;
  await app.listen(PORT, '0.0.0.0');
  console.log(`Application is running on: http://localhost:${PORT}/api`);
}
bootstrap();
