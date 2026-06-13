import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';

export function useEntityOptionDefinitionsQuery(
  campaignId: MaybeRefOrGetter<string>,
  entityTypeKey: MaybeRefOrGetter<string>,
  groupKey?: MaybeRefOrGetter<string | null | undefined>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      entityQueryKeys.options(toValue(campaignId), toValue(entityTypeKey), toValue(groupKey)),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        Boolean(toValue(entityTypeKey)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client.rpc('get_entity_option_definitions', {
        p_campaign_id: toValue(campaignId),
        p_entity_type_key: toValue(entityTypeKey),
        p_group_key: toValue(groupKey) || undefined,
      });

      if (error) {
        throw error;
      }

      return data ?? [];
    },
  });
}
