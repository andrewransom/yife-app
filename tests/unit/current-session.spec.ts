import { describe, expect, it, vi } from 'vitest';
import { resolveCurrentSession } from '../../app/utils/current-session';
import type { EntitySummary } from '../../app/composables/entities/types';

function session(overrides: Partial<EntitySummary> = {}): EntitySummary {
  return {
    archived_at: null,
    campaign_id: 'campaign-1',
    controlling_user_display_label: null,
    default_visibility: 'shared',
    deleted_at: null,
    encounter_type_label: null,
    entity_id: 'session-1',
    entity_type_key: 'session',
    is_major: null,
    list_caption: 'Session 1',
    location_type_label: null,
    npc_apparent_status_label: null,
    parent_entity_id: null,
    parent_entity_label: null,
    primary_image_alt_text: null,
    primary_image_asset_id: null,
    primary_image_grid_bucket: null,
    primary_image_grid_height: null,
    primary_image_grid_path: null,
    primary_image_grid_width: null,
    primary_image_is_decorative: null,
    primary_image_thumb_bucket: null,
    primary_image_thumb_height: null,
    primary_image_thumb_path: null,
    primary_image_thumb_width: null,
    related_session_entity_id: null,
    related_session_label: null,
    related_storyline_entity_id: null,
    related_storyline_label: null,
    relevant_date: '2026-06-20',
    sort_key: null,
    status_key: 'planned',
    status_label: 'Planned',
    storyline_category_label: null,
    storyline_priority_label: null,
    storyline_type: null,
    timeline_date_expression: null,
    timeline_event_type_label: null,
    updated_at: '2026-06-13T00:00:00Z',
    ...overrides,
  };
}

describe('resolveCurrentSession', () => {
  it('prefers the nearest upcoming planned session', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-06-13T12:00:00Z'));

    const result = resolveCurrentSession([
      session({
        entity_id: 'completed-1',
        status_key: 'completed',
        status_label: 'Completed',
        relevant_date: '2026-06-10',
      }),
      session({ entity_id: 'planned-2', relevant_date: '2026-06-18', list_caption: 'Session 2' }),
      session({ entity_id: 'planned-1', relevant_date: '2026-06-15', list_caption: 'Session 1' }),
    ]);

    expect(result?.sessionEntityId).toBe('planned-1');
    expect(result?.selectionReason).toBe('nearest_upcoming_planned');
    vi.useRealTimers();
  });

  it('falls back to the most recent completed session', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-06-13T12:00:00Z'));

    const result = resolveCurrentSession([
      session({
        entity_id: 'completed-1',
        status_key: 'completed',
        status_label: 'Completed',
        relevant_date: '2026-06-11',
      }),
      session({
        entity_id: 'completed-2',
        status_key: 'completed',
        status_label: 'Completed',
        relevant_date: '2026-06-12',
      }),
    ]);

    expect(result?.sessionEntityId).toBe('completed-2');
    expect(result?.selectionReason).toBe('most_recent_completed');
    vi.useRealTimers();
  });

  it('uses a manual override when present and visible', () => {
    const result = resolveCurrentSession(
      [
        session({ entity_id: 'planned-1', list_caption: 'Session 1' }),
        session({ entity_id: 'planned-2', list_caption: 'Session 2' }),
      ],
      { overrideEntityId: 'planned-2' },
    );

    expect(result?.sessionEntityId).toBe('planned-2');
    expect(result?.selectionReason).toBe('manual_override');
  });

  it('returns null when no visible sessions exist', () => {
    expect(resolveCurrentSession([])).toBeNull();
  });
});
