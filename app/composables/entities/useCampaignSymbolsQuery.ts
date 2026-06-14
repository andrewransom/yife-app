import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { CampaignSymbol } from './types';

export function useCampaignSymbolsQuery(
  campaignId: MaybeRefOrGetter<string>,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    includeInactive?: MaybeRefOrGetter<boolean>;
  },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      entityQueryKeys.symbols(
        toValue(campaignId),
        Boolean(options?.includeInactive && toValue(options.includeInactive)),
      ),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client.rpc('get_campaign_symbols', {
        p_campaign_id: toValue(campaignId),
        p_include_inactive: Boolean(options?.includeInactive && toValue(options.includeInactive)),
      });

      if (error) {
        throw error;
      }

      return (data ?? []) as CampaignSymbol[];
    },
  });
}
