import { navigateTo } from '#imports';
import { useQueryClient } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from './useYifeSupabaseClient';

export function useSignOut() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();

  return async () => {
    const { error } = await client.auth.signOut();

    if (error) {
      throw error;
    }

    queryClient.clear();
    await navigateTo('/');
  };
}
