import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { CharacterHook } from './types';

export function useCharacterHooksQuery(
  characterEntityId: MaybeRefOrGetter<string | null>,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      entityQueryKeys.characterHooks(
        toValue(characterEntityId) ?? 'none',
        options?.previewAsPlayer ? Boolean(toValue(options.previewAsPlayer)) : false,
      ),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(characterEntityId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const id = toValue(characterEntityId);

      if (!id) {
        throw new Error('Character entity id is required.');
      }

      const { data, error } = await client.rpc('get_character_hooks', {
        p_character_entity_id: id,
        p_role_view:
          options?.previewAsPlayer && toValue(options.previewAsPlayer) ? 'player' : undefined,
      });

      if (error) {
        throw error;
      }

      return (data ?? []) as CharacterHook[];
    },
  });
}
