import { expect, test } from '@playwright/test';

test('public route renders without the campaign workspace shell', async ({ page }) => {
  await page.goto('/');

  await expect(page.getByRole('heading', { name: 'Yife.app' })).toBeVisible();
  await expect(page.getByRole('link', { name: /create account/i }).first()).toBeVisible();
  await expect(page.getByRole('link', { name: /sign in/i }).first()).toBeVisible();
  await expect(page.getByText('Campaign ·')).toHaveCount(0);
});

test('auth pages load', async ({ page }) => {
  await page.goto('/auth/sign-in');
  await expect(page.getByRole('heading', { name: 'Sign in' })).toBeVisible();

  await page.goto('/auth/sign-up');
  await expect(page.getByRole('heading', { name: 'Create account' })).toBeVisible();
});

test('protected routes redirect unauthenticated users', async ({ page }) => {
  await page.goto('/home');
  await expect(page).toHaveURL(/\/auth\/sign-in\?redirectTo=(%2Fhome|\/home)/);
  await expect(page.getByRole('heading', { name: 'Sign in' })).toBeVisible();

  await page.goto('/campaigns/ember-coast');
  await expect(page).toHaveURL(
    /\/auth\/sign-in\?redirectTo=(%2Fcampaigns%2Fember-coast|\/campaigns\/ember-coast)/,
  );
});

test('auth callback handles error state', async ({ page }) => {
  await page.goto('/auth/callback#error_description=Denied+by+test');

  await expect(page.getByRole('heading', { name: 'Authentication problem' })).toBeVisible();
  await expect(page.getByText('Denied by test')).toBeVisible();
});

test('dev component workbench is hidden when flag is off', async ({ page }) => {
  await page.goto('/dev/components');

  await expect(page.getByRole('heading', { name: 'Page not found' })).toBeVisible();
  await expect(page.getByText('Component Workbench')).toHaveCount(0);
});
