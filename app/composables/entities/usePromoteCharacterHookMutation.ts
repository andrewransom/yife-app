import { useMutation, useQueryClient } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { useUiStore } from '~/stores/ui';
import { entityQueryKeys } from './keys';
import type { CreateEntityResult } from './types';

type PromoteCharacterHookInput = {
  hookId: string;
  characterEntityId: string;
  visibility?: 'shared' | 'gm_only' | 'private';
};

export function usePromoteCharacterHookMutation() {
  const client = useYifeSupabaseClient();
  const queryClient = useQueryClient();
  const uiStore = useUiStore();

  return useMutation({
    mutationFn: async ({ hookId, visibility }: PromoteCharacterHookInput) => {
      const { data, error } = await client.rpc('promote_character_hook_to_storyline', {
        p_hook_id: hookId,
        p_visibility: visibility,
      });

      if (error) {
        throw error;
      }

      const promoted = data?.[0];

      if (!promoted) {
        throw new Error('Storyline was not returned after hook promotion.');
      }

      return promoted as CreateEntityResult;
    },
    onSuccess: async (promoted, input) => {
      uiStore.selectEntity(promoted.entity_id);
      await queryClient.invalidateQueries({
        queryKey: entityQueryKeys.characterHooks(input.characterEntityId),
      });
      await queryClient.invalidateQueries({
        queryKey: entityQueryKeys.summaries(promoted.campaign_id),
      });
      await queryClient.invalidateQueries({
        queryKey: entityQueryKeys.detail(input.characterEntityId),
      });
      await queryClient.invalidateQueries({
        queryKey: entityQueryKeys.detail(promoted.entity_id),
      });
    },
  });
}
