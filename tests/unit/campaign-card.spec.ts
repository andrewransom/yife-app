import { RouterLinkStub, mount } from '@vue/test-utils';
import { describe, expect, it } from 'vitest';
import CampaignCard from '../../app/components/campaigns/CampaignCard.vue';
import type { MyCampaign } from '../../app/composables/campaigns/types';

const campaign: MyCampaign = {
  campaign_id: 'campaign-1',
  description: 'A coastal campaign.',
  membership_status: 'active',
  name: 'Ember Coast',
  primary_image_alt_text: '',
  primary_image_asset_id: '',
  primary_image_grid_bucket: '',
  primary_image_grid_height: 0,
  primary_image_grid_path: '',
  primary_image_grid_width: 0,
  primary_image_is_decorative: false,
  primary_image_thumb_bucket: '',
  primary_image_thumb_height: 0,
  primary_image_thumb_path: '',
  primary_image_thumb_width: 0,
  role_keys: ['owner'],
  status_key: 'planned',
  status_label: 'Planned',
  updated_at: '2026-06-12T00:00:00Z',
};

describe('CampaignCard', () => {
  it('renders campaign summary fields', () => {
    const wrapper = mount(CampaignCard, {
      props: {
        campaign,
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub,
          YStatusBadge: {
            props: ['label'],
            template: '<span data-testid="status"><slot />{{ label }}</span>',
          },
        },
      },
    });

    expect(wrapper.text()).toContain('Ember Coast');
    expect(wrapper.text()).toContain('A coastal campaign.');
    expect(wrapper.text()).toContain('Planned');
    expect(wrapper.text()).toContain('owner');
    expect(wrapper.findComponent(RouterLinkStub).props('to')).toBe('/campaigns/campaign-1');
  });
});
