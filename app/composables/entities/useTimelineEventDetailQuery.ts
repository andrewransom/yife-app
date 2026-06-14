import type { MaybeRefOrGetter } from 'vue';
import { useEntityDetailQuery } from './useEntityDetailQuery';

export function useTimelineEventDetailQuery(
  entityId: MaybeRefOrGetter<string | null>,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  return useEntityDetailQuery(entityId, options);
}
