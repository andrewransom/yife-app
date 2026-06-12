import { useSupabaseUser } from '#imports';

export function useCurrentUser() {
  return useSupabaseUser();
}
