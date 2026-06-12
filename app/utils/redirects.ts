const appOrigin = 'https://yife.local';

export function getSafeRedirectTarget(value: unknown, fallback = '/home') {
  if (typeof value !== 'string') {
    return fallback;
  }

  const candidate = value.trim();

  if (!candidate.startsWith('/') || candidate.startsWith('//') || candidate.includes('\\')) {
    return fallback;
  }

  try {
    const parsed = new URL(candidate, appOrigin);

    if (parsed.origin !== appOrigin) {
      return fallback;
    }

    return `${parsed.pathname}${parsed.search}${parsed.hash}`;
  } catch {
    return fallback;
  }
}

export function getRedirectQueryValue(value: unknown) {
  if (typeof value === 'string') {
    return getSafeRedirectTarget(value);
  }

  if (Array.isArray(value)) {
    return getSafeRedirectTarget(value[0]);
  }

  return '/home';
}
