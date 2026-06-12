import { describe, expect, it } from 'vitest';
import { canRunProtectedQueries } from '../../app/utils/protected-bootstrap';

describe('protected bootstrap query gating', () => {
  it('allows protected queries only after user defaults succeed', () => {
    expect(
      canRunProtectedQueries({
        hasUser: true,
        isPending: false,
        isSuccess: true,
        isError: false,
      }),
    ).toBe(true);
  });

  it('blocks protected queries while defaults are pending or failed', () => {
    expect(
      canRunProtectedQueries({
        hasUser: true,
        isPending: true,
        isSuccess: false,
        isError: false,
      }),
    ).toBe(false);
    expect(
      canRunProtectedQueries({
        hasUser: true,
        isPending: false,
        isSuccess: false,
        isError: true,
      }),
    ).toBe(false);
    expect(
      canRunProtectedQueries({
        hasUser: false,
        isPending: false,
        isSuccess: true,
        isError: false,
      }),
    ).toBe(false);
  });
});
