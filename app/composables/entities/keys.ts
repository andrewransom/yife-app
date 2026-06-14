export const entityQueryKeys = {
  summaries: (campaignId: string) => ['campaigns', campaignId, 'entities', 'summaries'] as const,
  sessions: (
    campaignId: string,
    filters?: {
      statusKey?: string | null;
      includeCancelled?: boolean;
      search?: string | null;
      previewAsPlayer?: string | null;
    },
  ) =>
    [
      'campaigns',
      campaignId,
      'sessions',
      filters?.statusKey ?? 'all',
      filters?.includeCancelled ? 'with-cancelled' : 'without-cancelled',
      filters?.search ?? '',
      filters?.previewAsPlayer ?? 'default',
    ] as const,
  storylines: (
    campaignId: string,
    filters?: {
      statusKey?: string | null;
      search?: string | null;
      storylineType?: string | null;
      categoryLabel?: string | null;
      priorityLabel?: string | null;
      majorMode?: string | null;
      previewAsPlayer?: string | null;
    },
  ) =>
    [
      'campaigns',
      campaignId,
      'storylines',
      filters?.statusKey ?? 'all',
      filters?.search ?? '',
      filters?.storylineType ?? 'all',
      filters?.categoryLabel ?? 'all',
      filters?.priorityLabel ?? 'all',
      filters?.majorMode ?? 'all',
      filters?.previewAsPlayer ?? 'default',
    ] as const,
  encounters: (
    campaignId: string,
    filters?: {
      statusKey?: string | null;
      search?: string | null;
      encounterTypeLabel?: string | null;
      relatedSessionEntityId?: string | null;
      previewAsPlayer?: string | null;
    },
  ) =>
    [
      'campaigns',
      campaignId,
      'encounters',
      filters?.statusKey ?? 'all',
      filters?.search ?? '',
      filters?.encounterTypeLabel ?? 'all',
      filters?.relatedSessionEntityId ?? 'all',
      filters?.previewAsPlayer ?? 'default',
    ] as const,
  detail: (entityId: string, previewAsPlayer = false) =>
    ['entities', entityId, 'detail', previewAsPlayer ? 'player-preview' : 'default'] as const,
  sessionAttendance: (entityId: string, previewAsPlayer = false) =>
    [
      'entities',
      entityId,
      'session-attendance',
      previewAsPlayer ? 'player-preview' : 'default',
    ] as const,
  currentSession: (campaignId: string, previewAsPlayer = false) =>
    [
      'campaigns',
      campaignId,
      'current-session',
      previewAsPlayer ? 'player-preview' : 'default',
    ] as const,
  activity: (
    campaignId: string,
    filters?: {
      relatedEntityId?: string | null;
      limit?: number | null;
      previewAsPlayer?: string | null;
    },
  ) =>
    [
      'campaigns',
      campaignId,
      'activity',
      filters?.relatedEntityId ?? 'all',
      String(filters?.limit ?? 30),
      filters?.previewAsPlayer ?? 'default',
    ] as const,
  sections: (entityId: string, previewAsPlayer = false) =>
    ['entities', entityId, 'sections', previewAsPlayer ? 'player-preview' : 'default'] as const,
  sectionContributions: (sectionId: string, previewAsPlayer = false) =>
    [
      'sections',
      sectionId,
      'contributions',
      previewAsPlayer ? 'player-preview' : 'default',
    ] as const,
  notes: (entityId: string, previewAsPlayer = false) =>
    ['entities', entityId, 'notes', previewAsPlayer ? 'player-preview' : 'default'] as const,
  campaignNotes: (campaignId: string) => ['campaigns', campaignId, 'notes'] as const,
  backlinks: (entityId: string, previewAsPlayer = false) =>
    ['entities', entityId, 'backlinks', previewAsPlayer ? 'player-preview' : 'default'] as const,
  relationships: (entityId: string, previewAsPlayer = false) =>
    [
      'entities',
      entityId,
      'relationships',
      previewAsPlayer ? 'player-preview' : 'default',
    ] as const,
  relatedRecords: (entityId: string, previewAsPlayer = false) =>
    [
      'entities',
      entityId,
      'related-records',
      previewAsPlayer ? 'player-preview' : 'default',
    ] as const,
  relationshipTypes: (campaignId: string) =>
    ['campaigns', campaignId, 'relationship-types'] as const,
  timelineEvents: (
    campaignId: string,
    filters?: {
      eventTypeKey?: string | null;
      relatedSessionEntityId?: string | null;
      relatedEntityId?: string | null;
      visibility?: string | null;
      previewAsPlayer?: string | null;
    },
  ) =>
    [
      'campaigns',
      campaignId,
      'timeline-events',
      filters?.eventTypeKey ?? 'all',
      filters?.relatedSessionEntityId ?? 'all',
      filters?.relatedEntityId ?? 'all',
      filters?.visibility ?? 'all',
      filters?.previewAsPlayer ?? 'default',
    ] as const,
  timelineDetail: (entityId: string, previewAsPlayer = false) =>
    [
      'timeline-events',
      entityId,
      'detail',
      previewAsPlayer ? 'player-preview' : 'default',
    ] as const,
  referenceResolutions: (campaignId: string, entityIds: string[]) =>
    ['campaigns', campaignId, 'entity-reference-resolutions', ...entityIds] as const,
  typeOptions: (campaignId: string) => ['campaigns', campaignId, 'entities', 'types'] as const,
  statuses: (campaignId: string, entityTypeKey: string) =>
    ['campaigns', campaignId, 'entities', entityTypeKey, 'statuses'] as const,
  optionsRoot: (campaignId: string) => ['campaigns', campaignId, 'options'] as const,
  options: (campaignId: string, groupKey?: string | null, includeInactive = false) =>
    [
      'campaigns',
      campaignId,
      'options',
      groupKey ?? 'all',
      includeInactive ? 'all' : 'active',
    ] as const,
  paletteColorsRoot: (campaignId: string) => ['campaigns', campaignId, 'palette-colors'] as const,
  paletteColors: (campaignId: string, includeInactive = false) =>
    ['campaigns', campaignId, 'palette-colors', includeInactive ? 'all' : 'active'] as const,
  symbolsRoot: (campaignId: string) => ['campaigns', campaignId, 'symbols'] as const,
  symbols: (campaignId: string, includeInactive = false) =>
    ['campaigns', campaignId, 'symbols', includeInactive ? 'all' : 'active'] as const,
  quickStats: (entityId: string, previewAsPlayer = false) =>
    ['entities', entityId, 'quick-stats', previewAsPlayer ? 'player-preview' : 'default'] as const,
  characterHooks: (entityId: string, previewAsPlayer = false) =>
    [
      'entities',
      entityId,
      'character-hooks',
      previewAsPlayer ? 'player-preview' : 'default',
    ] as const,
  partyMembers: (entityId: string, previewAsPlayer = false) =>
    [
      'entities',
      entityId,
      'party-members',
      previewAsPlayer ? 'player-preview' : 'default',
    ] as const,
  encounterStatblocks: (entityId: string, previewAsPlayer = false) =>
    [
      'entities',
      entityId,
      'encounter-statblocks',
      previewAsPlayer ? 'player-preview' : 'default',
    ] as const,
};
