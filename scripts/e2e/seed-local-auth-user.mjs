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

const existingUsers = [];
let page = 1;
let hasMore = true;

while (hasMore) {
  const { data, error } = await client.auth.admin.listUsers({ page, perPage: 100 });

  if (error) {
    throw error;
  }

  existingUsers.push(...data.users);
  hasMore = data.users.length === 100;
  page += 1;
}

const existing = existingUsers.find((user) => user.email === email);

if (existing) {
  const { error } = await client.auth.admin.updateUserById(existing.id, {
    email_confirm: true,
    password,
  });

  if (error) {
    throw error;
  }

  console.log(`Updated local Auth user ${email}`);
} else {
  const { error } = await client.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });

  if (error) {
    throw error;
  }

  console.log(`Created local Auth user ${email}`);
}
