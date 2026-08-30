import { Pool } from 'pg';
export interface User {
    id: string;
    email: string;
    password_hash: string;
}
export declare class UsersRepository {
    private readonly pool;
    constructor(pool: Pool);
    findByEmail(email: string): Promise<User | null>;
}
