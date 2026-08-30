import 'dotenv/config';
import { Pool } from 'pg';
import { hash } from '@node-rs/argon2';

async function main() {
  const [, , email, password] = process.argv;
  if (!email || !password) {
    console.error('Usage: npm run seed:user -- <email> <password>');
    process.exit(1);
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const passwordHash = await hash(password);

  await pool.query(
    `INSERT INTO users (email, password_hash) VALUES ($1, $2)
     ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash`,
    [email, passwordHash],
  );

  console.log(`User ${email} seeded.`);
  await pool.end();
}

main().catch((err: unknown) => {
  console.error(err);
  process.exit(1);
});
