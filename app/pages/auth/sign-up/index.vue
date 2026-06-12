<script setup lang="ts">
import { toTypedSchema } from '@vee-validate/zod';
import { useForm } from 'vee-validate';
import { ref } from 'vue';
import { UserPlus } from 'lucide-vue-next';
import { navigateTo } from '#imports';
import { emailPasswordSchema, type EmailPasswordInput } from '~/utils/auth-validation';
import { useSignUp } from '~/composables/auth/useSignUp';
import { useYifeToast } from '~/composables/auth/useYifeToast';

definePageMeta({
  auth: 'guest',
});

const signUp = useSignUp();
const toast = useYifeToast();
const isSubmitting = ref(false);
const formError = ref('');
const successMessage = ref('');

const { defineField, errors, handleSubmit } = useForm<EmailPasswordInput>({
  validationSchema: toTypedSchema(emailPasswordSchema),
  initialValues: {
    email: '',
    password: '',
  },
});

const [email, emailAttrs] = defineField('email');
const [password, passwordAttrs] = defineField('password');

const onSubmit = handleSubmit(async (values) => {
  formError.value = '';
  successMessage.value = '';
  isSubmitting.value = true;

  try {
    const result = await signUp(values);

    if (result.hasSession) {
      await navigateTo('/home');
      return;
    }

    successMessage.value = `Check ${result.userEmail} to finish account confirmation.`;
  } catch (error) {
    formError.value = error instanceof Error ? error.message : 'Account creation failed.';
    toast.error('Account creation failed', formError.value);
  } finally {
    isSubmitting.value = false;
  }
});
</script>

<template>
  <main class="mx-auto flex min-h-screen w-full max-w-md items-center px-4 py-8">
    <section class="w-full border border-[var(--yife-border)] bg-[var(--yife-surface)] p-4">
      <div class="mb-4">
        <p class="text-xs font-semibold uppercase text-[var(--yife-text-muted)]">Yife.app</p>
        <h1 class="mt-1 text-xl font-semibold">Create account</h1>
      </div>

      <form class="space-y-3" @submit="onSubmit">
        <YFormField label="Email" name="email">
          <UInput v-model="email" v-bind="emailAttrs" type="email" autocomplete="email" size="sm" />
          <p v-if="errors.email" class="mt-1 text-xs text-[var(--yife-error)]">
            {{ errors.email }}
          </p>
        </YFormField>

        <YFormField label="Password" name="password">
          <UInput
            v-model="password"
            v-bind="passwordAttrs"
            type="password"
            autocomplete="new-password"
            size="sm"
          />
          <p v-if="errors.password" class="mt-1 text-xs text-[var(--yife-error)]">
            {{ errors.password }}
          </p>
        </YFormField>

        <p v-if="formError" class="text-sm text-[var(--yife-error)]">{{ formError }}</p>
        <p v-if="successMessage" class="text-sm text-[var(--yife-success)]">
          {{ successMessage }}
        </p>

        <YDenseButton
          type="submit"
          color="primary"
          :loading="isSubmitting"
          :disabled="isSubmitting"
        >
          <UserPlus class="size-4" aria-hidden="true" />
          Create account
        </YDenseButton>
      </form>

      <p class="mt-4 text-sm text-[var(--yife-text-muted)]">
        Already have an account?
        <NuxtLink class="font-medium text-[var(--yife-primary)]" to="/auth/sign-in">
          Sign in
        </NuxtLink>
      </p>
    </section>
  </main>
</template>
