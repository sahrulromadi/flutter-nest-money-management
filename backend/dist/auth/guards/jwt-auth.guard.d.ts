import { CanActivate, ExecutionContext } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';
export declare class JwtAuthGuard implements CanActivate {
    private readonly jwtService;
    private readonly configService;
    private readonly reflector;
    constructor(jwtService: JwtService, configService: ConfigService, reflector: Reflector);
    canActivate(context: ExecutionContext): Promise<boolean>;
    private extractToken;
}
