import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useCampaignEntitySummariesQuery } from './useCampaignEntitySummariesQuery';
import { entityQueryKeys } from './keys';

type SessionFilters = {
  statusKey?: MaybeRefOrGetter<string | null | undefined>;
  includeCancelled?: MaybeRefOrGetter<boolean | undefined>;
  search?: MaybeRefOrGetter<string | null | undefined>;
};

export function useSessionsQuery(
  campaignId: MaybeRefOrGetter<string>,
  filters?: SessionFilters,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  const baseQuery = useCampaignEntitySummariesQuery(campaignId, options);
  const today = computed(() =>
    new Intl.DateTimeFormat('en-CA', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(new Date()),
  );

  const data = computed(() => {
    const statusKey = toValue(filters?.statusKey) ?? '';
    const search = toValue(filters?.search)?.trim().toLowerCase() ?? '';
    const includeCancelled = Boolean(toValue(filters?.includeCancelled));

    return (baseQuery.data.value ?? [])
      .filter((summary) => summary.entity_type_key === 'session')
      .filter((summary) => (includeCancelled ? true : summary.status_key !== 'cancelled'))
      .filter((summary) => (statusKey ? summary.status_key === statusKey : true))
      .filter((summary) =>
        search
          ? [summary.list_caption, summary.status_label, summary.related_storyline_label]
              .filter(Boolean)
              .some((value) => String(value).toLowerCase().includes(search))
          : true,
      )
      .slice()
      .sort((left, right) => {
        const leftGroup =
          left.status_key === 'planned' && left.relevant_date && left.relevant_date >= today.value
            ? 0
            : left.status_key === 'completed'
              ? 1
              : 2;
        const rightGroup =
          right.status_key === 'planned' &&
          right.relevant_date &&
          right.relevant_date >= today.value
            ? 0
            : right.status_key === 'completed'
              ? 1
              : 2;
        const leftDate = left.relevant_date ?? '';
        const rightDate = right.relevant_date ?? '';
        return (
          leftGroup - rightGroup ||
          (leftGroup === 1
            ? rightDate.localeCompare(leftDate)
            : leftDate.localeCompare(rightDate)) ||
          left.list_caption.localeCompare(right.list_caption)
        );
      });
  });

  return {
    ...baseQuery,
    queryKey: computed(() =>
      entityQueryKeys.sessions(toValue(campaignId), {
        statusKey: toValue(filters?.statusKey) ?? null,
        includeCancelled: Boolean(toValue(filters?.includeCancelled)),
        search: toValue(filters?.search) ?? null,
        previewAsPlayer:
          options?.previewAsPlayer && toValue(options.previewAsPlayer)
            ? 'player-preview'
            : 'default',
      }),
    ),
    data,
  };
}
