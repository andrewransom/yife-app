import { describe, expect, it } from 'vitest';
import {
  toCreateEntityRpcInput,
  validateCreateEntityInput,
} from '../../app/utils/entity-validation';

describe('entity creation validation', () => {
  it('accepts required character fields', () => {
    const result = validateCreateEntityInput({
      entityTypeKey: 'character',
      name: 'Aria Vale',
      statusId: '11111111-1111-4111-8111-111111111111',
      controllingUserId: '22222222-2222-4222-8222-222222222222',
    });

    expect(result.name).toBe('Aria Vale');
    expect(toCreateEntityRpcInput(result)).toMatchObject({
      name: 'Aria Vale',
      status_id: '11111111-1111-4111-8111-111111111111',
      controlling_user_id: '22222222-2222-4222-8222-222222222222',
    });
  });

  it('rejects missing required type-specific fields', () => {
    expect(() =>
      validateCreateEntityInput({
        entityTypeKey: 'location',
        name: 'Saltwind Docks',
      }),
    ).toThrow('Location type is required.');

    expect(() =>
      validateCreateEntityInput({
        entityTypeKey: 'timeline_event',
        title: 'The Beacon Falls',
        eventTypeOptionId: '33333333-3333-4333-8333-333333333333',
      }),
    ).toThrow('Date expression is required.');
  });

  it('requires NPC real status and defaults apparent status to it', () => {
    const result = validateCreateEntityInput({
      entityTypeKey: 'npc',
      name: 'Mira the Broker',
      realStatusId: '11111111-1111-4111-8111-111111111111',
    });

    expect(toCreateEntityRpcInput(result)).toMatchObject({
      apparent_status_id: '11111111-1111-4111-8111-111111111111',
      real_status_id: '11111111-1111-4111-8111-111111111111',
    });
  });
});
