import { navigateTo } from '#imports';
import { getSafeRedirectTarget } from '~/utils/redirects';
import { useYifeSupabaseClient } from './useYifeSupabaseClient';

export async function completeAuthCallback(url: URL) {
  const client = useYifeSupabaseClient();
  const code = url.searchParams.get('code');

  if (code) {
    const { error } = await client.auth.exchangeCodeForSession(code);

    if (error) {
      throw error;
    }
  }

  const {
    data: { session },
    error,
  } = await client.auth.getSession();

  if (error) {
    throw error;
  }

  if (!session) {
    throw new Error('Authentication finished without an active session.');
  }

  await navigateTo(getSafeRedirectTarget(url.searchParams.get('redirectTo')));
}
