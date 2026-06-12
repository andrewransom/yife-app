import { expect, test } from '@playwright/test';

const email = process.env.E2E_AUTH_EMAIL || 'e2e@yife.local';
const password = process.env.E2E_AUTH_PASSWORD || 'password123';

test('seeded local auth user can create a campaign and see inaccessible campaign fallback', async ({
  page,
}) => {
  await page.goto('/auth/sign-in');
  await page.getByLabel('Email').fill(email);
  await page.getByLabel('Password').fill(password);
  await page.getByRole('button', { name: 'Sign in' }).click();

  await expect(page.getByRole('heading', { name: 'Campaign Home' })).toBeVisible();

  await page.getByRole('button', { name: 'New' }).click();

  const name = `E2E Campaign ${Date.now()}`;
  await page.getByLabel('Name').fill(name);
  await page.getByLabel('Start date').fill('2026-06-12');
  await page.getByRole('button', { name: 'Create campaign' }).click();

  await expect(page).toHaveURL(/\/campaigns\//);
  await expect(page.getByRole('heading', { name }).first()).toBeVisible();

  await page.goto('/campaigns/00000000-0000-4000-8000-000000000001');
  await expect(page.getByRole('heading', { name: 'Campaign unavailable' })).toBeVisible();
  await page.getByRole('link', { name: 'Return home' }).click();
  await expect(page).toHaveURL(/\/home$/);
});
