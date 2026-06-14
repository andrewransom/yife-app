import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { SessionAttendance } from './types';

export function useSessionAttendanceQuery(
  sessionEntityId: MaybeRefOrGetter<string | null>,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      entityQueryKeys.sessionAttendance(
        toValue(sessionEntityId) ?? 'none',
        options?.previewAsPlayer ? Boolean(toValue(options.previewAsPlayer)) : false,
      ),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(sessionEntityId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const id = toValue(sessionEntityId);

      if (!id) {
        throw new Error('Session id is required.');
      }

      const { data, error } = await client.rpc('get_session_attendance', {
        p_session_entity_id: id,
        p_role_view:
          options?.previewAsPlayer && toValue(options.previewAsPlayer) ? 'player' : undefined,
      });

      if (error) {
        throw error;
      }

      const row = data?.[0];
      return row
        ? {
            session_entity_id: row.session_entity_id,
            attending_users: Array.isArray(row.attending_users) ? row.attending_users : [],
            attending_characters: Array.isArray(row.attending_characters)
              ? row.attending_characters
              : [],
            can_manage: Boolean(row.can_manage),
          }
        : null;
    },
  }) as ReturnType<typeof useQuery<SessionAttendance | null>>;
}
