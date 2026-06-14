import { z } from 'zod';

const optionalUuid = z.string().uuid().or(z.literal('')).optional();

export const createEntityBaseSchema = z.object({
  entityTypeKey: z.string().min(1),
  name: z.string().trim().optional(),
  title: z.string().trim().optional(),
  statusId: optionalUuid,
  apparentStatusId: optionalUuid,
  realStatusId: optionalUuid,
  controllingUserId: optionalUuid,
  locationTypeOptionId: optionalUuid,
  priorityOptionId: optionalUuid,
  encounterTypeOptionId: optionalUuid,
  eventTypeOptionId: optionalUuid,
  relatedSessionEntityId: optionalUuid,
  relatedStorylineEntityId: optionalUuid,
  storylineType: z.enum(['quest', 'thread']).optional(),
  sessionDate: z.string().optional(),
  dateExpression: z.string().trim().optional(),
  sortKey: z.string().trim().optional(),
  isMajor: z.boolean().optional(),
});

export type CreateEntityFormInput = z.input<typeof createEntityBaseSchema>;
export type CreateEntityFormOutput = z.output<typeof createEntityBaseSchema>;

export function validateCreateEntityInput(input: CreateEntityFormInput) {
  const parsed = createEntityBaseSchema.parse(input);
  const primaryText = parsed.entityTypeKey.match(/^(character|npc|party|faction|location)$/)
    ? parsed.name
    : parsed.title;

  if (!primaryText?.trim()) {
    throw new Error('Name or title is required.');
  }

  if (
    ['character', 'storyline', 'session', 'encounter'].includes(parsed.entityTypeKey) &&
    !parsed.statusId
  ) {
    throw new Error('Status is required.');
  }

  if (parsed.entityTypeKey === 'npc' && !parsed.realStatusId) {
    throw new Error('Real status is required.');
  }

  if (parsed.entityTypeKey === 'character' && !parsed.controllingUserId) {
    throw new Error('Controller is required.');
  }

  if (parsed.entityTypeKey === 'location' && !parsed.locationTypeOptionId) {
    throw new Error('Location type is required.');
  }

  if (parsed.entityTypeKey === 'encounter' && !parsed.encounterTypeOptionId) {
    throw new Error('Encounter type is required.');
  }

  if (parsed.entityTypeKey === 'timeline_event') {
    if (!parsed.eventTypeOptionId) {
      throw new Error('Timeline event type is required.');
    }
    if (!parsed.dateExpression?.trim()) {
      throw new Error('Date expression is required.');
    }
  }

  if (parsed.entityTypeKey === 'session' && !parsed.sessionDate) {
    throw new Error('Session date is required.');
  }

  return parsed;
}

export function toCreateEntityRpcInput(input: CreateEntityFormOutput) {
  return {
    name: input.name || undefined,
    title: input.title || undefined,
    status_id: input.statusId || undefined,
    apparent_status_id: input.apparentStatusId || input.realStatusId || input.statusId || undefined,
    real_status_id: input.realStatusId || input.statusId || undefined,
    controlling_user_id: input.controllingUserId || undefined,
    location_type_option_id: input.locationTypeOptionId || undefined,
    priority_option_id: input.priorityOptionId || undefined,
    encounter_type_option_id: input.encounterTypeOptionId || undefined,
    event_type_option_id: input.eventTypeOptionId || undefined,
    related_session_entity_id: input.relatedSessionEntityId || undefined,
    related_storyline_entity_id: input.relatedStorylineEntityId || undefined,
    storyline_type: input.storylineType || undefined,
    session_date: input.sessionDate || undefined,
    date_expression: input.dateExpression || undefined,
    sort_key: input.sortKey || undefined,
    is_major: Boolean(input.isMajor),
  };
}
