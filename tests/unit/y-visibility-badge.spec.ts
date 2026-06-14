import { mount } from '@vue/test-utils';
import { describe, expect, it } from 'vitest';
import YVisibilityBadge from '../../app/components/yife/YVisibilityBadge.vue';

describe('YVisibilityBadge', () => {
  it('renders character owner visibility distinctly', () => {
    const wrapper = mount(YVisibilityBadge, {
      props: {
        visibility: 'character_owner_gm',
      },
      global: {
        stubs: {
          YStatusBadge: {
            props: ['label', 'tone'],
            template: '<span data-testid="visibility" :data-tone="tone">{{ label }}</span>',
          },
        },
      },
    });

    expect(wrapper.get('[data-testid="visibility"]').text()).toBe('Owner + GM');
    expect(wrapper.get('[data-testid="visibility"]').attributes('data-tone')).toBe('info');
  });
});
