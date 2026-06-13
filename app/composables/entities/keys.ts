export const entityQueryKeys = {
  summaries: (campaignId: string) => ['campaigns', campaignId, 'entities', 'summaries'] as const,
  detail: (entityId: string) => ['entities', entityId, 'detail'] as const,
  typeOptions: (campaignId: string) => ['campaigns', campaignId, 'entities', 'types'] as const,
  statuses: (campaignId: string, entityTypeKey: string) =>
    ['campaigns', campaignId, 'entities', entityTypeKey, 'statuses'] as const,
  optionsRoot: (campaignId: string) => ['campaigns', campaignId, 'options'] as const,
  options: (campaignId: string, groupKey?: string | null, includeInactive = false) =>
    ['campaigns', campaignId, 'options', groupKey ?? 'all', includeInactive ? 'all' : 'active'] as const,
  paletteColorsRoot: (campaignId: string) => ['campaigns', campaignId, 'palette-colors'] as const,
  paletteColors: (campaignId: string, includeInactive = false) =>
    ['campaigns', campaignId, 'palette-colors', includeInactive ? 'all' : 'active'] as const,
  symbolsRoot: (campaignId: string) => ['campaigns', campaignId, 'symbols'] as const,
  symbols: (campaignId: string, includeInactive = false) =>
    ['campaigns', campaignId, 'symbols', includeInactive ? 'all' : 'active'] as const,
  quickStats: (entityId: string) => ['entities', entityId, 'quick-stats'] as const,
  characterHooks: (entityId: string) => ['entities', entityId, 'character-hooks'] as const,
  partyMembers: (entityId: string) => ['entities', entityId, 'party-members'] as const,
  encounterStatblocks: (entityId: string) =>
    ['entities', entityId, 'encounter-statblocks'] as const,
};
