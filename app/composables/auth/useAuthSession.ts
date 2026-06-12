import { useSupabaseSession } from '#imports';

export function useAuthSession() {
  return useSupabaseSession();
}
