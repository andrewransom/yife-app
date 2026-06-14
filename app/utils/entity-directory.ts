import type { EntitySummary } from '~/composables/entities/types';

export type EntityDirectoryFilters = {
  entityTypeKey: string;
  statusKey?: string;
  search?: string;
  includeArchived?: boolean;
  includeDeleted?: boolean;
  storylineType?: string;
  storylineCategoryLabel?: string;
  storylinePriorityLabel?: string;
  storylineMajorMode?: 'all' | 'major' | 'minor';
  encounterTypeLabel?: string;
  relatedSessionEntityId?: string;
};

export function filterEntitySummaries(summaries: EntitySummary[], filters: EntityDirectoryFilters) {
  const search = filters.search?.trim().toLowerCase() ?? '';

  return summaries.filter((summary) => {
    if (filters.entityTypeKey !== 'all' && summary.entity_type_key !== filters.entityTypeKey) {
      return false;
    }

    if (!filters.includeArchived && summary.archived_at) {
      return false;
    }

    if (!filters.includeDeleted && summary.deleted_at) {
      return false;
    }

    if (filters.statusKey && summary.status_key !== filters.statusKey) {
      return false;
    }

    if (filters.storylineType && summary.storyline_type !== filters.storylineType) {
      return false;
    }

    if (
      filters.storylineCategoryLabel &&
      summary.storyline_category_label !== filters.storylineCategoryLabel
    ) {
      return false;
    }

    if (
      filters.storylinePriorityLabel &&
      summary.storyline_priority_label !== filters.storylinePriorityLabel
    ) {
      return false;
    }

    if (filters.storylineMajorMode === 'major' && summary.is_major !== true) {
      return false;
    }

    if (filters.storylineMajorMode === 'minor' && summary.is_major === true) {
      return false;
    }

    if (
      filters.encounterTypeLabel &&
      summary.encounter_type_label !== filters.encounterTypeLabel
    ) {
      return false;
    }

    if (
      filters.relatedSessionEntityId &&
      summary.related_session_entity_id !== filters.relatedSessionEntityId
    ) {
      return false;
    }

    if (!search) {
      return true;
    }

    return [
      summary.list_caption,
      summary.status_label,
      summary.parent_entity_label,
      summary.related_session_label,
      summary.location_type_label,
      summary.storyline_priority_label,
      summary.storyline_category_label,
      summary.encounter_type_label,
      summary.timeline_date_expression,
    ]
      .filter(Boolean)
      .some((value) => String(value).toLowerCase().includes(search));
  });
}
