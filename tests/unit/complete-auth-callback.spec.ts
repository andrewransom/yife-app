import { describe, expect, it, vi } from 'vitest';
import { navigateTo } from '#imports';

const exchangeCodeForSession = vi.fn();
const getSession = vi.fn();

vi.mock('../../app/composables/auth/useYifeSupabaseClient', () => ({
  useYifeSupabaseClient: () => ({
    auth: {
      exchangeCodeForSession,
      getSession,
    },
  }),
}));

describe('completeAuthCallback', () => {
  it('exchanges callback code, verifies session, and navigates to a safe target', async () => {
    const { completeAuthCallback } =
      await import('../../app/composables/auth/useCompleteAuthCallback');

    exchangeCodeForSession.mockResolvedValue({ error: null });
    getSession.mockResolvedValue({
      data: {
        session: {
          user: {
            id: 'user-1',
          },
        },
      },
      error: null,
    });

    await completeAuthCallback(new URL('http://127.0.0.1/auth/callback?code=abc&redirectTo=/home'));

    expect(exchangeCodeForSession).toHaveBeenCalledWith('abc');
    expect(getSession).toHaveBeenCalled();
    expect(navigateTo).toHaveBeenCalledWith('/home');
  });
});
