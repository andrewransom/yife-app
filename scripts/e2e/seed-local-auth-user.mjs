import { createClient } from '@supabase/supabase-js';
import { existsSync, readFileSync } from 'node:fs';

if (existsSync('.env')) {
  const lines = readFileSync('.env', 'utf8').split(/\r?\n/);

  for (const line of lines) {
    const match = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);

    if (!match || process.env[match[1]]) {
      continue;
    }

    process.env[match[1]] = match[2].replace(/^["']|["']$/g, '');
  }
}

const url = process.env.NUXT_PUBLIC_SUPABASE_URL || 'http://127.0.0.1:54321';
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const email = process.env.E2E_AUTH_EMAIL || 'e2e@yife.local';
const password = process.env.E2E_AUTH_PASSWORD || 'password123';

if (!serviceRoleKey) {
  console.error('Set SUPABASE_SERVICE_ROLE_KEY before seeding an Auth user.');
  process.exit(1);
}

const client = createClient(url, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

const { error: createError } = await client.auth.admin.createUser({
  email,
  password,
  email_confirm: true,
});

if (!createError) {
  console.log(`Created local Auth user ${email}`);
  process.exit(0);
}

const alreadyExists =
  createError.status === 422 ||
  createError.code === 'email_exists' ||
  createError.message.toLowerCase().includes('already');

if (!alreadyExists) {
  throw createError;
}

const verifyClient = createClient(url, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

const { error: signInError } = await verifyClient.auth.signInWithPassword({
  email,
  password,
});

if (signInError) {
  throw new Error(
    `Auth user ${email} already exists, but the password could not be verified. Run pnpm supabase:reset, then rerun this seed script.`,
  );
}

console.log(`Local Auth user ${email} already exists and password is valid`);
