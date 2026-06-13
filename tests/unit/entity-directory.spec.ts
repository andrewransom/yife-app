import { mount } from '@vue/test-utils';
import { describe, expect, it } from 'vitest';
import EntityDirectoryRow from '../../app/components/entities/EntityDirectoryRow.vue';
import type { EntitySummary } from '../../app/composables/entities/types';
import { filterEntitySummaries } from '../../app/utils/entity-directory';

function summary(overrides: Partial<EntitySummary> = {}): EntitySummary {
  return {
    archived_at: null,
    campaign_id: 'campaign-1',
    controlling_user_display_label: null,
    default_visibility: 'shared',
    deleted_at: null,
    encounter_type_label: null,
    entity_id: 'entity-1',
    entity_type_key: 'npc',
    is_major: null,
    list_caption: 'Mira the Broker',
    location_type_label: null,
    npc_apparent_status_label: 'Alive',
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
    quest_priority_label: null,
    related_plot_arc_entity_id: null,
    related_plot_arc_label: null,
    related_session_entity_id: null,
    related_session_label: null,
    relevant_date: null,
    sort_key: null,
    status_key: 'alive',
    status_label: 'Alive',
    timeline_date_expression: null,
    timeline_event_type_label: null,
    updated_at: '2026-06-12T00:00:00Z',
    ...overrides,
  };
}

describe('entity directory', () => {
  it('renders ListCaption and compact metadata', async () => {
    const wrapper = mount(EntityDirectoryRow, {
      props: {
        summary: summary({
          parent_entity_label: 'Harbor Guild',
        }),
      },
      global: {
        stubs: {
          YVisibilityBadge: {
            props: ['visibility'],
            template: '<span data-testid="visibility">{{ visibility }}</span>',
          },
        },
      },
    });

    expect(wrapper.text()).toContain('Mira the Broker');
    expect(wrapper.text()).toContain('Alive');
    expect(wrapper.text()).toContain('in Harbor Guild');

    await wrapper.trigger('click');
    expect(wrapper.emitted('select')?.[0]).toEqual(['entity-1']);
  });

  it('hides archived and deleted records by default', () => {
    const visible = summary();
    const archived = summary({
      entity_id: 'archived',
      archived_at: '2026-06-12T00:00:00Z',
      list_caption: 'Archived',
    });
    const deleted = summary({
      entity_id: 'deleted',
      deleted_at: '2026-06-12T00:00:00Z',
      list_caption: 'Deleted',
    });

    expect(
      filterEntitySummaries([visible, archived, deleted], {
        entityTypeKey: 'all',
      }).map((item) => item.entity_id),
    ).toEqual(['entity-1']);
  });

  it('filters by type, status, and loaded summary search fields', () => {
    const quest = summary({
      entity_id: 'quest-1',
      entity_type_key: 'quest',
      list_caption: 'Find the Ember Map',
      quest_priority_label: 'High',
      status_key: 'open',
      status_label: 'Open',
    });

    expect(
      filterEntitySummaries([summary(), quest], {
        entityTypeKey: 'quest',
        statusKey: 'open',
        search: 'ember',
      }),
    ).toEqual([quest]);
  });
});
