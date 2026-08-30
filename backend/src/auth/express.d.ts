import { TokenPayload } from './token-payload.interface';

declare module 'express' {
  interface Request {
    user?: TokenPayload;
  }
}
