import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useCurrentUser } from './useCurrentUser';
import { useYifeSupabaseClient } from './useYifeSupabaseClient';

export const userDefaultsQueryKey = ['user', 'defaults'] as const;

export function useEnsureUserProfile(options?: { enabled?: MaybeRefOrGetter<boolean> }) {
  const client = useYifeSupabaseClient();
  const user = useCurrentUser();

  return useQuery({
    queryKey: userDefaultsQueryKey,
    enabled: computed(
      () => Boolean(user.value) && (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client.rpc('ensure_user_defaults');

      if (error) {
        throw error;
      }

      const defaults = data?.[0];

      if (!defaults) {
        throw new Error('User defaults were not returned.');
      }

      return defaults;
    },
  });
}
