import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { campaignQueryKeys } from './keys';

export function useMyCampaignsQuery(options?: { enabled?: MaybeRefOrGetter<boolean> }) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: campaignQueryKeys.mine(),
    enabled: computed(() => options?.enabled === undefined || toValue(options.enabled)),
    queryFn: async () => {
      const { data, error } = await client.rpc('get_my_campaigns');

      if (error) {
        throw error;
      }

      return data ?? [];
    },
  });
}
