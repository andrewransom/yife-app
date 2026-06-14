import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { PartyMember } from './types';

export function usePartyMembersQuery(
  partyEntityId: MaybeRefOrGetter<string | null>,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      entityQueryKeys.partyMembers(
        toValue(partyEntityId) ?? 'none',
        options?.previewAsPlayer ? Boolean(toValue(options.previewAsPlayer)) : false,
      ),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(partyEntityId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const id = toValue(partyEntityId);

      if (!id) {
        throw new Error('Party entity id is required.');
      }

      const { data, error } = await client.rpc('get_party_members', {
        p_party_entity_id: id,
        p_role_view:
          options?.previewAsPlayer && toValue(options.previewAsPlayer) ? 'player' : undefined,
      });

      if (error) {
        throw error;
      }

      return (data ?? []) as PartyMember[];
    },
  });
}
