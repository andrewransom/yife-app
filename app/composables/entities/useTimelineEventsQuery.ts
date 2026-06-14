import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useQuery } from '@tanstack/vue-query';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { entityQueryKeys } from './keys';
import type { TimelineEvent } from './types';

type TimelineEventFilters = {
  eventTypeKey?: MaybeRefOrGetter<string | null>;
  relatedSessionEntityId?: MaybeRefOrGetter<string | null>;
  relatedEntityId?: MaybeRefOrGetter<string | null>;
  visibility?: MaybeRefOrGetter<string | null>;
};

export function useTimelineEventsQuery(
  campaignId: MaybeRefOrGetter<string>,
  filters?: TimelineEventFilters,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  const client = useYifeSupabaseClient();

  return useQuery({
    queryKey: computed(() =>
      entityQueryKeys.timelineEvents(toValue(campaignId), {
        eventTypeKey: filters?.eventTypeKey ? toValue(filters.eventTypeKey) : null,
        relatedSessionEntityId: filters?.relatedSessionEntityId
          ? toValue(filters.relatedSessionEntityId)
          : null,
        relatedEntityId: filters?.relatedEntityId ? toValue(filters.relatedEntityId) : null,
        visibility: filters?.visibility ? toValue(filters.visibility) : null,
        previewAsPlayer:
          options?.previewAsPlayer && toValue(options.previewAsPlayer) ? 'player-preview' : 'default',
      }),
    ),
    enabled: computed(
      () =>
        Boolean(toValue(campaignId)) &&
        (options?.enabled === undefined || toValue(options.enabled)),
    ),
    queryFn: async () => {
      const { data, error } = await client.rpc('get_timeline_events', {
        p_campaign_id: toValue(campaignId),
        p_event_type_key: filters?.eventTypeKey
          ? (toValue(filters.eventTypeKey) ?? undefined)
          : undefined,
        p_related_session_entity_id: filters?.relatedSessionEntityId
          ? (toValue(filters.relatedSessionEntityId) ?? undefined)
          : undefined,
        p_related_entity_id: filters?.relatedEntityId
          ? (toValue(filters.relatedEntityId) ?? undefined)
          : undefined,
        p_visibility: filters?.visibility ? (toValue(filters.visibility) ?? undefined) : undefined,
        p_role_view:
          options?.previewAsPlayer && toValue(options.previewAsPlayer) ? 'player' : undefined,
      });

      if (error) {
        throw error;
      }

      return (data ?? []) as TimelineEvent[];
    },
  });
}
