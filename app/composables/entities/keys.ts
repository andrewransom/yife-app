export const entityQueryKeys = {
  summaries: (campaignId: string) => ['campaigns', campaignId, 'entities', 'summaries'] as const,
  detail: (entityId: string) => ['entities', entityId, 'detail'] as const,
  typeOptions: (campaignId: string) => ['campaigns', campaignId, 'entities', 'types'] as const,
  statuses: (campaignId: string, entityTypeKey: string) =>
    ['campaigns', campaignId, 'entities', entityTypeKey, 'statuses'] as const,
  options: (campaignId: string, entityTypeKey: string, groupKey?: string | null) =>
    ['campaigns', campaignId, 'entities', entityTypeKey, 'options', groupKey ?? 'all'] as const,
};
