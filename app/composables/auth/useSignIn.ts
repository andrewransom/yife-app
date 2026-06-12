import { navigateTo } from '#imports';
import type { EmailPasswordInput } from '~/utils/auth-validation';
import { getSafeRedirectTarget } from '~/utils/redirects';
import { useYifeSupabaseClient } from './useYifeSupabaseClient';

export function useSignIn() {
  const client = useYifeSupabaseClient();

  return async (input: EmailPasswordInput & { redirectTo?: string }) => {
    const { error } = await client.auth.signInWithPassword({
      email: input.email,
      password: input.password,
    });

    if (error) {
      throw error;
    }

    await navigateTo(getSafeRedirectTarget(input.redirectTo));
  };
}
