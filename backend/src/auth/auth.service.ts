import {
  Injectable,
  UnauthorizedException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import { verify } from '@node-rs/argon2';
import { UsersRepository } from '../users/users.repository';
import { TokenPayload } from './token-payload.interface';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersRepository: UsersRepository,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async login(email: string, password: string) {
    const user = await this.usersRepository.findByEmail(email);
    if (!user) {
      throw new UnauthorizedException('Email atau password salah');
    }

    const passwordValid = await verify(user.password_hash, password);
    if (!passwordValid) {
      throw new UnauthorizedException('Email atau password salah');
    }

    return this.issueTokens(user.id, user.email);
  }

  async refresh(refreshToken: string) {
    let payload: TokenPayload;
    try {
      payload = await this.jwtService.verifyAsync<TokenPayload>(
        refreshToken,
        { secret: this.configService.get<string>('JWT_REFRESH_SECRET') },
      );
    } catch {
      throw new UnauthorizedException('Refresh token invalid/kadaluarsa');
    }

    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Refresh token invalid');
    }

    const user = await this.usersRepository.findByEmail(payload.email);
    if (!user) {
      throw new UnprocessableEntityException('User tidak ditemukan');
    }

    return this.issueTokens(user.id, user.email);
  }

  private issueTokens(userId: string, email: string) {
    const accessPayload: TokenPayload = { sub: userId, email, type: 'access' };
    const refreshPayload: TokenPayload = {
      sub: userId,
      email,
      type: 'refresh',
    };

    const accessToken = this.jwtService.sign(accessPayload, {
      secret: this.configService.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: this.configService.get<string>(
        'JWT_ACCESS_EXPIRES_IN',
      ) as JwtSignOptions['expiresIn'],
    });
    const refreshToken = this.jwtService.sign(refreshPayload, {
      secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: this.configService.get<string>(
        'JWT_REFRESH_EXPIRES_IN',
      ) as JwtSignOptions['expiresIn'],
    });

    return { accessToken, refreshToken };
  }
}
