import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { EntityReferenceResolution } from './types';

export function useEntityReferenceResolutionsQuery(
  campaignId: MaybeRefOrGetter<string>,
  entityIds: MaybeRefOrGetter<string[]>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() => {
      const ids = Array.from(new Set(toValue(entityIds))).sort();
      return entityQueryKeys.referenceResolutions(toValue(campaignId), ids);
    }),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        toValue(entityIds).length > 0 &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const ids = Array.from(new Set(toValue(entityIds))).sort();

      if (!ids.length) {
        return [] as EntityReferenceResolution[];
      }

      const { data, error } = await client.rpc('resolve_entity_references', {
        p_entity_ids: ids,
      });

      if (error) {
        throw error;
      }

      return (data ?? []) as EntityReferenceResolution[];
    },
  });
}
