import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UsersRepository } from '../users/users.repository';
export declare class AuthService {
    private readonly usersRepository;
    private readonly jwtService;
    private readonly configService;
    constructor(usersRepository: UsersRepository, jwtService: JwtService, configService: ConfigService);
    login(email: string, password: string): Promise<{
        accessToken: string;
        refreshToken: string;
    }>;
    refresh(refreshToken: string): Promise<{
        accessToken: string;
        refreshToken: string;
    }>;
    private issueTokens;
}
