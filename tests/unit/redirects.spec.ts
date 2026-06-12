import { describe, expect, it } from 'vitest';
import { getRedirectQueryValue, getSafeRedirectTarget } from '../../app/utils/redirects';

describe('redirect helpers', () => {
  it('keeps app-relative redirect targets', () => {
    expect(getSafeRedirectTarget('/campaigns/abc?tab=notes#top')).toBe(
      '/campaigns/abc?tab=notes#top',
    );
  });

  it('drops unsafe redirect targets', () => {
    expect(getSafeRedirectTarget('https://example.com')).toBe('/home');
    expect(getSafeRedirectTarget('//example.com/path')).toBe('/home');
    expect(getSafeRedirectTarget('/\\example.com')).toBe('/home');
    expect(getRedirectQueryValue(['https://example.com'])).toBe('/home');
  });
});
