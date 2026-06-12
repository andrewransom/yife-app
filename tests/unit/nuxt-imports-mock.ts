import { vi } from 'vitest';

export const navigateTo = vi.fn();

export function useRoute() {
  return {
    query: {},
    params: {},
    fullPath: '/',
  };
}

export function definePageMeta() {
  return undefined;
}
