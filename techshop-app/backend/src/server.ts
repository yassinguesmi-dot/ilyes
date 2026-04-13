import 'dotenv/config';

import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';

import authRoutes from './routes/auth.routes';
import categoryRoutes from './routes/category.routes';
import orderRoutes from './routes/order.routes';
import paymentRoutes from './routes/payment.routes';
import productRoutes from './routes/product.routes';
import reviewRoutes from './routes/review.routes';
import userRoutes from './routes/user.routes';
import { errorHandler } from './middlewares/errorHandler';

const app = express();

app.set('trust proxy', 1);

const corsOriginRaw = process.env.CORS_ORIGIN ?? '';
const corsOrigins = corsOriginRaw
  .split(',')
  .map((o) => o.trim())
  .filter((o) => o.length > 0);

app.use(helmet());
app.use(
  cors({
    origin: corsOrigins.length > 0 ? corsOrigins : true,
    credentials: true,
  }),
);

// Stripe webhook needs the raw body, so we skip JSON parsing for that specific route.
app.use((req, res, next) => {
  if (req.originalUrl === '/api/payment/webhook') {
    next();
    return;
  }
  express.json({ limit: '2mb' })(req, res, next);
});
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

app.get('/health', (_req, res) => {
  res.status(200).json({ ok: true });
});

app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/users', userRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api', reviewRoutes);

app.use(errorHandler);

const port = Number(process.env.PORT ?? 4000);
app.listen(port, () => {
  console.log(`TechShop API listening on http://localhost:${port}`);
});

