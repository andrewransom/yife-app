import { describe, expect, it } from 'vitest';
import { designTokens } from '../../app/design/tokens';

describe('design tokens', () => {
  it('keeps Nuxt UI theme aliases tied to the token source', () => {
    expect(designTokens.nuxtUi.colors).toEqual([
      'primary',
      'secondary',
      'success',
      'info',
      'warning',
      'error',
      'neutral',
    ]);
    expect(designTokens.radius.lg).toBe('8px');
    expect(designTokens.component.rowHeight).toBe('2.75rem');
  });
});
