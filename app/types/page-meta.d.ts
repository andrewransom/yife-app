declare module '#app' {
  interface PageMeta {
    auth?: 'public' | 'guest' | 'protected';
  }
}

export {};
