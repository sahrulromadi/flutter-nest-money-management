import { Pool } from 'pg';
export declare class HealthController {
    private readonly pool;
    constructor(pool: Pool);
    check(): Promise<{
        status: string;
    }>;
}
