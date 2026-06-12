import { expect, test } from '@playwright/test';

test('public route renders without the campaign workspace shell', async ({ page }) => {
  await page.goto('/');

  await expect(page.getByRole('heading', { name: 'Yife.app' })).toBeVisible();
  await expect(page.getByText('Campaign ·')).toHaveCount(0);
});

test('home and campaign shell routes render', async ({ page }) => {
  await page.goto('/home');
  await expect(page.getByRole('heading', { name: 'Campaign Home' })).toBeVisible();

  await page.goto('/campaigns/ember-coast');
  await expect(page.getByRole('heading', { name: 'Campaign · ember-coast' })).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Record Detail Shell' })).toBeVisible();
});

test('dev component workbench is hidden when flag is off', async ({ page }) => {
  await page.goto('/dev/components');

  await expect(page.getByRole('heading', { name: 'Page not found' })).toBeVisible();
  await expect(page.getByText('Component Workbench')).toHaveCount(0);
});
