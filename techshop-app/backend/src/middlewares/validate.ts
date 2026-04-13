import type { NextFunction, Request, Response } from 'express';
import { ZodError, type ZodTypeAny } from 'zod';

type RequestSchema = {
  body?: ZodTypeAny;
  query?: ZodTypeAny;
  params?: ZodTypeAny;
};

export function validate(schema: RequestSchema) {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      if (schema.params) req.params = schema.params.parse(req.params);
      if (schema.query) req.query = schema.query.parse(req.query);
      if (schema.body) req.body = schema.body.parse(req.body);
      next();
    } catch (err) {
      if (err instanceof ZodError) {
        res.status(400).json({ message: 'Validation error', issues: err.issues });
        return;
      }
      next(err);
    }
  };
}
