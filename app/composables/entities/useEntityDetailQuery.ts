import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { EntityDetail } from './types';

export function useEntityDetailQuery(
  entityId: MaybeRefOrGetter<string | null>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() => entityQueryKeys.detail(toValue(entityId) ?? 'none')),
    enabled: computed(
      () =>
        Boolean(toValue(entityId)) && (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const id = toValue(entityId);

      if (!id) {
        throw new Error('Entity id is required.');
      }

      const { data, error } = await client.rpc('get_entity_detail', {
        p_entity_id: id,
      });

      if (error) {
        throw error;
      }

      return (data?.[0] as EntityDetail | undefined) ?? null;
    },
  });
}
