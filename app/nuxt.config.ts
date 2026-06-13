import { designTokens } from './design/tokens';

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
    optimizeDeps: {
      include: [
        '@tanstack/vue-query',
        '@vee-validate/zod',
        '@vue/devtools-api',
        'lucide-vue-next',
        'vee-validate',
        'zod',
      ],
    },
  },
});
