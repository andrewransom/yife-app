import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { PartyMember } from './types';

export function usePartyMembersQuery(
  partyEntityId: MaybeRefOrGetter<string | null>,
  options?: { enabled?: MaybeRefOrGetter<boolean> },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() => entityQueryKeys.partyMembers(toValue(partyEntityId) ?? 'none')),
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

      const { data, error } = await client
        .from('party_members')
        .select(
          `
            character_entity_id,
            role_label,
            is_active,
            sort_order,
            character:campaign_entities!party_members_character_entity_id_fkey (
              id,
              list_caption,
              default_visibility
            )
          `,
        )
        .eq('party_entity_id', id)
        .order('sort_order', { ascending: true });

      if (error) {
        throw error;
      }

      return (data ?? []).map((row) => ({
        character_entity_id: row.character_entity_id,
        role_label: row.role_label,
        is_active: row.is_active,
        sort_order: row.sort_order,
        character_label:
          row.character && !Array.isArray(row.character) ? row.character.list_caption : null,
        character_visibility:
          row.character && !Array.isArray(row.character) ? row.character.default_visibility : null,
      })) as PartyMember[];
    },
  });
}
