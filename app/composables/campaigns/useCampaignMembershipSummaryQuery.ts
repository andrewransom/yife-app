import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { campaignQueryKeys } from './keys';

export function useCampaignMembershipSummaryQuery(
  campaignId: MaybeRefOrGetter<string>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() => campaignQueryKeys.membership(toValue(campaignId))),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client.rpc('get_campaign_membership_summary', {
        p_campaign_id: toValue(campaignId),
      });

      if (error) {
        throw error;
      }

      return data?.[0] ?? null;
    },
  });
}
