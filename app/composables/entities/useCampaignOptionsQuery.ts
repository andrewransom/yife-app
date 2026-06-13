import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';

export function useCampaignOptionsQuery(
  campaignId: MaybeRefOrGetter<string>,
  groupKey: MaybeRefOrGetter<string | null | undefined>,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    includeInactive?: MaybeRefOrGetter<boolean>;
  },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      entityQueryKeys.options(
        toValue(campaignId),
        toValue(groupKey),
        Boolean(options?.includeInactive && toValue(options.includeInactive)),
      ),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const requestedGroupKey = toValue(groupKey);
      const { data, error } = await client.rpc('get_campaign_options', {
        p_campaign_id: toValue(campaignId),
        p_group_key: requestedGroupKey ? requestedGroupKey : undefined,
        p_include_inactive: Boolean(options?.includeInactive && toValue(options.includeInactive)),
      });

      if (error) {
        throw error;
      }

      return data ?? [];
    },
  });
}
