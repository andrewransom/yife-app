import { computed, toValue, type MaybeRefOrGetter } from 'vue';
import { useCampaignEntitySummariesQuery } from './useCampaignEntitySummariesQuery';
import { entityQueryKeys } from './keys';

type EncounterFilters = {
  statusKey?: MaybeRefOrGetter<string | null | undefined>;
  search?: MaybeRefOrGetter<string | null | undefined>;
  encounterTypeLabel?: MaybeRefOrGetter<string | null | undefined>;
  relatedSessionEntityId?: MaybeRefOrGetter<string | null | undefined>;
};

export function useEncountersQuery(
  campaignId: MaybeRefOrGetter<string>,
  filters?: EncounterFilters,
  options?: {
    enabled?: MaybeRefOrGetter<boolean>;
    previewAsPlayer?: MaybeRefOrGetter<boolean>;
  },
) {
  const baseQuery = useCampaignEntitySummariesQuery(campaignId, options);

  const data = computed(() => {
    const statusKey = toValue(filters?.statusKey) ?? '';
    const search = toValue(filters?.search)?.trim().toLowerCase() ?? '';
    const encounterTypeLabel = toValue(filters?.encounterTypeLabel) ?? '';
    const relatedSessionEntityId = toValue(filters?.relatedSessionEntityId) ?? '';

    return (baseQuery.data.value ?? [])
      .filter((summary) => summary.entity_type_key === 'encounter')
      .filter((summary) => (statusKey ? summary.status_key === statusKey : true))
      .filter((summary) =>
        search
          ? [
              summary.list_caption,
              summary.status_label,
              summary.encounter_type_label,
              summary.related_session_label,
              summary.related_storyline_label,
            ]
              .filter(Boolean)
              .some((value) => String(value).toLowerCase().includes(search))
          : true,
      )
      .filter((summary) =>
        encounterTypeLabel ? summary.encounter_type_label === encounterTypeLabel : true,
      )
      .filter((summary) =>
        relatedSessionEntityId
          ? summary.related_session_entity_id === relatedSessionEntityId
          : true,
      )
      .slice()
      .sort((left, right) => {
        const leftDate = left.relevant_date ?? '';
        const rightDate = right.relevant_date ?? '';
        return (
          rightDate.localeCompare(leftDate) || left.list_caption.localeCompare(right.list_caption)
        );
      });
  });

  return {
    ...baseQuery,
    queryKey: computed(() =>
      entityQueryKeys.encounters(toValue(campaignId), {
        statusKey: toValue(filters?.statusKey) ?? null,
        search: toValue(filters?.search) ?? null,
        encounterTypeLabel: toValue(filters?.encounterTypeLabel) ?? null,
        relatedSessionEntityId: toValue(filters?.relatedSessionEntityId) ?? null,
        previewAsPlayer:
          options?.previewAsPlayer && toValue(options.previewAsPlayer)
            ? 'player-preview'
            : 'default',
      }),
    ),
    data,
  };
}
