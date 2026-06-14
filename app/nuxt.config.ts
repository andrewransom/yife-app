import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { designTokens } from './design/tokens';

const appRoot = resolve(fileURLToPath(new URL('.', import.meta.url)));
const projectRoot = resolve(appRoot, '..');

export default defineNuxtConfig({
  ssr: false,
  compatibilityDate: '2026-06-12',
  devtools: { enabled: true },
  modules: ['@nuxt/ui', '@nuxtjs/supabase', '@pinia/nuxt'],
  components: [
    {
      path: '~/components',
      pathPrefix: false,
    },
  ],
  css: ['~/assets/css/main.css'],
  typescript: {
    strict: true,
    typeCheck: true,
  },
  runtimeConfig: {
    public: {
      supabaseUrl: '',
      supabaseAnonKey: '',
      devComponentWorkbench: false,
    },
  },
  supabase: {
    url: process.env.NUXT_PUBLIC_SUPABASE_URL || 'http://127.0.0.1:54321',
    key: process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY || 'placeholder-anon-key',
    redirect: false,
  },
  ui: {
    theme: {
      colors: [...designTokens.nuxtUi.colors],
      defaultVariants: designTokens.nuxtUi.defaultVariants,
    },
  },
  vite: {
    resolve: {
      alias: {
        'vee-validate': resolve(projectRoot, 'node_modules/vee-validate/dist/vee-validate.mjs'),
        '@vee-validate/zod': resolve(
          projectRoot,
          'node_modules/@vee-validate/zod/dist/vee-validate-zod.mjs',
        ),
      },
    },
    optimizeDeps: {
      include: [
        '@tanstack/vue-query',
        '@vue/devtools-api',
        'lucide-vue-next',
        'vee-validate',
        '@vee-validate/zod',
        'zod',
      ],
    },
  },
});
