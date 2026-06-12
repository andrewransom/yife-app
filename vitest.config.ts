import { fileURLToPath } from 'node:url';
import vue from '@vitejs/plugin-vue';
import { defineConfig } from 'vitest/config';

const appPath = fileURLToPath(new URL('./app', import.meta.url));

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '~': appPath,
      '@': appPath,
      '#imports': fileURLToPath(new URL('./tests/unit/nuxt-imports-mock.ts', import.meta.url)),
    },
  },
  test: {
    include: ['tests/unit/**/*.spec.ts'],
    environment: 'happy-dom',
    globals: true,
  },
});
