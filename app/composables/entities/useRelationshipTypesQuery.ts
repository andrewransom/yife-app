import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { RelationshipType } from './types';

export function useRelationshipTypesQuery(
  campaignId: MaybeRefOrGetter<string>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() => entityQueryKeys.relationshipTypes(toValue(campaignId))),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const id = toValue(campaignId);
      const { data, error } = await client
        .from('relationship_types')
        .select('id, key, label, inverse_label, default_directionality, sort_order')
        .eq('is_active', true)
        .or(`campaign_id.is.null,campaign_id.eq.${id}`)
        .order('sort_order', { ascending: true })
        .order('label', { ascending: true });

      if (error) {
        throw error;
      }

      return (data ?? []) as RelationshipType[];
    },
  });
}
