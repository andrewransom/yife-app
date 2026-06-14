import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { useUiStore } from '~/stores/ui';
import { resolveCurrentSession } from '~/utils/current-session';
import { entityQueryKeys } from './keys';
import { useSessionsQuery } from './useSessionsQuery';
import type { CurrentSession } from './types';

export function useCurrentSessionQuery(
  campaignId: MaybeRefOrGetter<string>,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  const client = useYifeSupabaseClient();
  const uiStore = useUiStore();
  const sessionsQuery = useSessionsQuery(campaignId, undefined, options);

  const baseQuery = useQuery({
    queryKey: computed(() =>
      entityQueryKeys.currentSession(
        toValue(campaignId),
        options?.previewAsPlayer ? Boolean(toValue(options.previewAsPlayer)) : false,
      ),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client.rpc('get_current_session', {
        p_campaign_id: toValue(campaignId),
        p_role_view:
          options?.previewAsPlayer && toValue(options.previewAsPlayer) ? 'player' : undefined,
      });

      if (error) {
        throw error;
      }

      return (data?.[0] as CurrentSession | undefined) ?? null;
    },
  });

  const data = computed<CurrentSession | null>(() => {
    const id = toValue(campaignId);
    const overrideEntityId = uiStore.getCurrentSessionOverride(id || null);
    const override = resolveCurrentSession(sessionsQuery.data.value ?? [], { overrideEntityId });

    if (override) {
      return {
        session_entity_id: override.sessionEntityId,
        list_caption: override.listCaption,
        session_date: override.sessionDate,
        status_key: override.statusKey,
        status_label: override.statusLabel,
        selection_reason: override.selectionReason,
      };
    }

    return baseQuery.data.value ?? null;
  });

  function setOverride(entityId: string | null) {
    const id = toValue(campaignId);
    if (!id) {
      return;
    }
    uiStore.setCurrentSessionOverride(id, entityId);
  }

  return {
    ...baseQuery,
    data,
    sessionsQuery,
    setOverride,
    clearOverride: () => setOverride(null),
  };
}
