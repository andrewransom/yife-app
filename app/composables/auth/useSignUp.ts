import type { EmailPasswordInput } from '~/utils/auth-validation';
import { useYifeSupabaseClient } from './useYifeSupabaseClient';

export function useSignUp() {
  const client = useYifeSupabaseClient();

  return async (input: EmailPasswordInput) => {
    const emailRedirectTo =
      typeof window === 'undefined' ? undefined : `${window.location.origin}/auth/callback`;

    const { data, error } = await client.auth.signUp({
      email: input.email,
      password: input.password,
      options: {
        emailRedirectTo,
      },
    });

    if (error) {
      throw error;
    }

    return {
      hasSession: Boolean(data.session),
      userEmail: data.user?.email ?? input.email,
    };
  };
}
