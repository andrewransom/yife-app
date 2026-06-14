import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { CampaignActivityItem } from './types';

export function useCampaignActivityQuery(
  campaignId: MaybeRefOrGetter<string>,
  filters?: {
    relatedEntityId?: MaybeRefOrGetter<string | null | undefined>;
    limit?: MaybeRefOrGetter<number | undefined>;
  },
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      entityQueryKeys.activity(toValue(campaignId), {
        relatedEntityId: toValue(filters?.relatedEntityId) ?? null,
        limit: toValue(filters?.limit) ?? 30,
        previewAsPlayer:
          options?.previewAsPlayer && toValue(options.previewAsPlayer)
            ? 'player-preview'
            : 'default',
      }),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client.rpc('get_campaign_activity', {
        p_campaign_id: toValue(campaignId),
        p_role_view:
          options?.previewAsPlayer && toValue(options.previewAsPlayer) ? 'player' : undefined,
        p_limit: toValue(filters?.limit) ?? 30,
        p_related_entity_id: toValue(filters?.relatedEntityId) ?? undefined,
      });

      if (error) {
        throw error;
      }

      return (data ?? []) as CampaignActivityItem[];
    },
  });
}
