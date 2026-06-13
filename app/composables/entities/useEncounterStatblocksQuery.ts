import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { EncounterStatblock } from './types';

export function useEncounterStatblocksQuery(
  encounterEntityId: MaybeRefOrGetter<string | null>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      entityQueryKeys.encounterStatblocks(toValue(encounterEntityId) ?? 'none'),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(encounterEntityId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const id = toValue(encounterEntityId);

      if (!id) {
        throw new Error('Encounter entity id is required.');
      }

      const { data, error } = await client.rpc('get_encounter_statblocks', {
        p_encounter_entity_id: id,
      });

      if (error) {
        throw error;
      }

      return (data ?? []) as EncounterStatblock[];
    },
  });
}
