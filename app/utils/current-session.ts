import type { EntitySummary } from '~/composables/entities/types';

export type CurrentSessionResult = {
  sessionEntityId: string;
  listCaption: string;
  sessionDate: string | null;
  statusKey: string | null;
  statusLabel: string | null;
  selectionReason: 'manual_override' | 'nearest_upcoming_planned' | 'most_recent_completed';
};

export function resolveCurrentSession(
  sessions: EntitySummary[],
  options?: { overrideEntityId?: string | null },
): CurrentSessionResult | null {
  const visibleSessions = sessions.filter((session) => session.entity_type_key === 'session');
  const today = new Intl.DateTimeFormat('en-CA', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
  const override = options?.overrideEntityId
    ? visibleSessions.find((session) => session.entity_id === options.overrideEntityId)
    : null;

  if (override) {
    return {
      sessionEntityId: override.entity_id,
      listCaption: override.list_caption,
      sessionDate: override.relevant_date,
      statusKey: override.status_key,
      statusLabel: override.status_label,
      selectionReason: 'manual_override',
    };
  }

  const upcoming = visibleSessions
    .filter(
      (session) =>
        session.status_key === 'planned' && session.relevant_date && session.relevant_date >= today,
    )
    .sort((left, right) => left.relevant_date!.localeCompare(right.relevant_date!))[0];

  if (upcoming) {
    return {
      sessionEntityId: upcoming.entity_id,
      listCaption: upcoming.list_caption,
      sessionDate: upcoming.relevant_date,
      statusKey: upcoming.status_key,
      statusLabel: upcoming.status_label,
      selectionReason: 'nearest_upcoming_planned',
    };
  }

  const completed = visibleSessions
    .filter((session) => session.status_key === 'completed' && session.relevant_date)
    .sort((left, right) => right.relevant_date!.localeCompare(left.relevant_date!))[0];

  if (!completed) {
    return null;
  }

  return {
    sessionEntityId: completed.entity_id,
    listCaption: completed.list_caption,
    sessionDate: completed.relevant_date,
    statusKey: completed.status_key,
    statusLabel: completed.status_label,
    selectionReason: 'most_recent_completed',
  };
}
