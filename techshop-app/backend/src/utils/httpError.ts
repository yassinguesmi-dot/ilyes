export class HttpError extends Error {
  public readonly status: number;
  public readonly details?: unknown;

  constructor(status: number, message: string, details?: unknown) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

export function asHttpError(err: unknown): HttpError {
  if (err instanceof HttpError) return err;
  if (err instanceof Error) return new HttpError(500, err.message);
  return new HttpError(500, 'Unexpected error');
}
