"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const jwt_1 = require("@nestjs/jwt");
const argon2_1 = require("@node-rs/argon2");
const users_repository_1 = require("../users/users.repository");
let AuthService = class AuthService {
    usersRepository;
    jwtService;
    configService;
    constructor(usersRepository, jwtService, configService) {
        this.usersRepository = usersRepository;
        this.jwtService = jwtService;
        this.configService = configService;
    }
    async login(email, password) {
        const user = await this.usersRepository.findByEmail(email);
        if (!user) {
            throw new common_1.UnauthorizedException('Email atau password salah');
        }
        const passwordValid = await (0, argon2_1.verify)(user.password_hash, password);
        if (!passwordValid) {
            throw new common_1.UnauthorizedException('Email atau password salah');
        }
        return this.issueTokens(user.id, user.email);
    }
    async refresh(refreshToken) {
        let payload;
        try {
            payload = await this.jwtService.verifyAsync(refreshToken, { secret: this.configService.get('JWT_REFRESH_SECRET') });
        }
        catch {
            throw new common_1.UnauthorizedException('Refresh token invalid/kadaluarsa');
        }
        if (payload.type !== 'refresh') {
            throw new common_1.UnauthorizedException('Refresh token invalid');
        }
        const user = await this.usersRepository.findByEmail(payload.email);
        if (!user) {
            throw new common_1.UnprocessableEntityException('User tidak ditemukan');
        }
        return this.issueTokens(user.id, user.email);
    }
    issueTokens(userId, email) {
        const accessPayload = { sub: userId, email, type: 'access' };
        const refreshPayload = {
            sub: userId,
            email,
            type: 'refresh',
        };
        const accessToken = this.jwtService.sign(accessPayload, {
            secret: this.configService.get('JWT_ACCESS_SECRET'),
            expiresIn: this.configService.get('JWT_ACCESS_EXPIRES_IN'),
        });
        const refreshToken = this.jwtService.sign(refreshPayload, {
            secret: this.configService.get('JWT_REFRESH_SECRET'),
            expiresIn: this.configService.get('JWT_REFRESH_EXPIRES_IN'),
        });
        return { accessToken, refreshToken };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [users_repository_1.UsersRepository,
        jwt_1.JwtService,
        config_1.ConfigService])
], AuthService);
//# sourceMappingURL=auth.service.js.map