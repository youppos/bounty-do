import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS so the mobile app or frontend can connect
  app.enableCors();

  // Enable validation pipes globally
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );

  const port = process.env.PORT || 3000;
  // Listen on 0.0.0.0 so other devices on the same network (e.g. phone simulators or physical phones) can connect
  await app.listen(port, '0.0.0.0');
  console.log(`Bounty-Do backend server running on: http://localhost:${port}`);
}
bootstrap().catch((err: unknown) => {
  console.error('Error starting server:', err);
});
