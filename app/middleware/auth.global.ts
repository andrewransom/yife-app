import { defineNuxtRouteMiddleware, navigateTo } from '#imports';
import { useYifeSupabaseClient } from '~/composables/auth/useYifeSupabaseClient';
import { getSafeRedirectTarget } from '~/utils/redirects';

export default defineNuxtRouteMiddleware(async (to) => {
  const authMode = to.meta.auth ?? 'public';

  if (authMode === 'public') {
    return;
  }

  const client = useYifeSupabaseClient();
  const {
    data: { session },
  } = await client.auth.getSession();
  const isSignedIn = Boolean(session?.user);

  if (authMode === 'protected' && !isSignedIn) {
    return navigateTo({
      path: '/auth/sign-in',
      query: {
        redirectTo: getSafeRedirectTarget(to.fullPath),
      },
    });
  }

  if (authMode === 'guest' && isSignedIn) {
    return navigateTo(getSafeRedirectTarget(to.query.redirectTo, '/home'));
  }
});
