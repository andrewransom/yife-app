import type { EntitySummary } from '~/composables/entities/types';

export type EntityDirectoryFilters = {
  entityTypeKey: string;
  statusKey?: string;
  search?: string;
  includeArchived?: boolean;
  includeDeleted?: boolean;
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
