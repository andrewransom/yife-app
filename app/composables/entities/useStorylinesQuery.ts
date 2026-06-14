import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useCampaignEntitySummariesQuery } from './useCampaignEntitySummariesQuery';
import { entityQueryKeys } from './keys';

type StorylineFilters = {
  statusKey?: MaybeRefOrGetter<string | null | undefined>;
  search?: MaybeRefOrGetter<string | null | undefined>;
  storylineType?: MaybeRefOrGetter<string | null | undefined>;
  categoryLabel?: MaybeRefOrGetter<string | null | undefined>;
  priorityLabel?: MaybeRefOrGetter<string | null | undefined>;
  majorMode?: MaybeRefOrGetter<'all' | 'major' | 'minor' | null | undefined>;
};

export function useStorylinesQuery(
  campaignId: MaybeRefOrGetter<string>,
  filters?: StorylineFilters,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  const baseQuery = useCampaignEntitySummariesQuery(campaignId, options);

  const data = computed(() => {
    const statusKey = toValue(filters?.statusKey) ?? '';
    const search = toValue(filters?.search)?.trim().toLowerCase() ?? '';
    const storylineType = toValue(filters?.storylineType) ?? '';
    const categoryLabel = toValue(filters?.categoryLabel) ?? '';
    const priorityLabel = toValue(filters?.priorityLabel) ?? '';
    const majorMode = toValue(filters?.majorMode) ?? 'all';

    return (baseQuery.data.value ?? [])
      .filter((summary) => summary.entity_type_key === 'storyline')
      .filter((summary) => (statusKey ? summary.status_key === statusKey : true))
      .filter((summary) =>
        search
          ? [
              summary.list_caption,
              summary.status_label,
              summary.storyline_category_label,
              summary.storyline_priority_label,
              summary.parent_entity_label,
            ]
              .filter(Boolean)
              .some((value) => String(value).toLowerCase().includes(search))
          : true,
      )
      .filter((summary) => (storylineType ? summary.storyline_type === storylineType : true))
      .filter((summary) =>
        categoryLabel ? summary.storyline_category_label === categoryLabel : true,
      )
      .filter((summary) =>
        priorityLabel ? summary.storyline_priority_label === priorityLabel : true,
      )
      .filter((summary) => {
        if (majorMode === 'major') {
          return summary.is_major === true;
        }

        if (majorMode === 'minor') {
          return summary.is_major !== true;
        }

        return true;
      })
      .slice()
      .sort((left, right) => {
        const leftMajor = left.is_major ? 0 : 1;
        const rightMajor = right.is_major ? 0 : 1;
        return (
          leftMajor - rightMajor ||
          String(left.storyline_priority_label ?? '').localeCompare(
            String(right.storyline_priority_label ?? ''),
          ) ||
          left.list_caption.localeCompare(right.list_caption)
        );
      });
  });

  return {
    ...baseQuery,
    queryKey: computed(() =>
      entityQueryKeys.storylines(toValue(campaignId), {
        statusKey: toValue(filters?.statusKey) ?? null,
        search: toValue(filters?.search) ?? null,
        storylineType: toValue(filters?.storylineType) ?? null,
        categoryLabel: toValue(filters?.categoryLabel) ?? null,
        priorityLabel: toValue(filters?.priorityLabel) ?? null,
        majorMode: toValue(filters?.majorMode) ?? null,
        previewAsPlayer:
          options?.previewAsPlayer && toValue(options.previewAsPlayer)
            ? 'player-preview'
            : 'default',
      }),
    ),
    data,
  };
}
