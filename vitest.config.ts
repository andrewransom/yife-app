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
    },
  },
  test: {
    include: ['tests/unit/**/*.spec.ts'],
    environment: 'happy-dom',
    globals: true,
  },
});
