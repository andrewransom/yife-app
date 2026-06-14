import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { EntityRelationship } from './types';

export function useEntityRelationshipsQuery(
  entityId: MaybeRefOrGetter<string | null>,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      entityQueryKeys.relationships(
        toValue(entityId) ?? 'none',
        options?.previewAsPlayer ? Boolean(toValue(options.previewAsPlayer)) : false,
      ),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(entityId)) && (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const id = toValue(entityId);

      if (!id) {
        throw new Error('Entity id is required.');
      }

      const { data, error } = await client.rpc('get_entity_relationships', {
        p_entity_id: id,
        p_role_view:
          options?.previewAsPlayer && toValue(options.previewAsPlayer) ? 'player' : undefined,
      });

      if (error) {
        throw error;
      }

      return (data ?? []) as EntityRelationship[];
    },
  });
}
