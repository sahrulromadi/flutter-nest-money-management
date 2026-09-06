import 'dotenv/config';
import { Pool } from 'pg';

async function main() {
  const [, , email, name, initialBalanceRaw] = process.argv;
  if (!email || !name) {
    console.error(
      'Usage: npm run seed:account -- <user-email> <nama-akun> [saldo-awal]',
    );
    process.exit(1);
  }
  const initialBalance = Number(initialBalanceRaw ?? 0);
  if (Number.isNaN(initialBalance)) {
    console.error('saldo-awal harus angka');
    process.exit(1);
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  const user = await pool.query<{ id: string }>(
    `SELECT id FROM users WHERE email = $1`,
    [email],
  );
  if (user.rowCount === 0) {
    console.error(`User ${email} belum ada. Jalanin seed:user dulu.`);
    await pool.end();
    process.exit(1);
  }

  const account = await pool.query<{ id: string }>(
    `INSERT INTO accounts (user_id, name, initial_balance)
     VALUES ($1, $2, $3) RETURNING id`,
    [user.rows[0].id, name, initialBalance],
  );

  console.log(
    `Akun "${name}" (saldo awal ${initialBalance}) dibuat: ${account.rows[0].id}`,
  );
  await pool.end();
}

main().catch((err: unknown) => {
  console.error(err);
  process.exit(1);
});
