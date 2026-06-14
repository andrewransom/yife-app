import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { EntityNote } from './types';

export function useCampaignNotesQuery(
  campaignId: MaybeRefOrGetter<string | null>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() => entityQueryKeys.campaignNotes(toValue(campaignId) ?? 'none')),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const id = toValue(campaignId);

      if (!id) {
        throw new Error('Campaign id is required.');
      }

      const { data, error } = await client.rpc('get_campaign_notes', {
        p_campaign_id: id,
      });

      if (error) {
        throw error;
      }

      return (data ?? []) as EntityNote[];
    },
  });
}
