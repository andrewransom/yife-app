import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { EntitySummary } from './types';

export function useCampaignEntitySummariesQuery(
  campaignId: MaybeRefOrGetter<string>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() => entityQueryKeys.summaries(toValue(campaignId))),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client.rpc('get_campaign_entity_summaries', {
        p_campaign_id: toValue(campaignId),
      });

      if (error) {
        throw error;
      }

      return (data ?? []) as EntitySummary[];
    },
  });
}
