import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import type { CampaignOptionGroup } from './types';
import { campaignQueryKeys } from './keys';

export function useCampaignOptionGroupsQuery(
  campaignId: MaybeRefOrGetter<string>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() => campaignQueryKeys.optionGroups(toValue(campaignId))),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client
        .from('campaign_option_groups')
        .select('*')
        .eq('campaign_id', toValue(campaignId))
        .order('sort_order', { ascending: true })
        .order('label', { ascending: true });

      if (error) {
        throw error;
      }

      return (data ?? []) as CampaignOptionGroup[];
    },
  });
}
