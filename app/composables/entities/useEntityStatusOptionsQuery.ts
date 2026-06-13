import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';

export function useEntityStatusOptionsQuery(
  campaignId: MaybeRefOrGetter<string>,
  entityTypeKey: MaybeRefOrGetter<string>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() => entityQueryKeys.statuses(toValue(campaignId), toValue(entityTypeKey))),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        Boolean(toValue(entityTypeKey)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client.rpc('get_entity_status_options', {
        p_campaign_id: toValue(campaignId),
        p_entity_type_key: toValue(entityTypeKey),
      });

      if (error) {
        throw error;
      }

      return data ?? [];
    },
  });
}
