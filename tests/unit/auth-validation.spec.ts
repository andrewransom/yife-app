import { describe, expect, it } from 'vitest';
import { emailPasswordSchema } from '../../app/utils/auth-validation';

describe('auth form validation', () => {
  it('accepts email and password credentials', () => {
    expect(
      emailPasswordSchema.safeParse({
        email: 'andrew@example.com',
        password: 'secret1',
      }).success,
    ).toBe(true);
  });

  it('rejects invalid credentials', () => {
    expect(
      emailPasswordSchema.safeParse({
        email: 'not-email',
        password: '123',
      }).success,
    ).toBe(false);
  });
});
