<script setup lang="ts">
import { toTypedSchema } from '@vee-validate/zod';
import { useForm } from 'vee-validate';
import { computed, ref } from 'vue';
import { Save } from 'lucide-vue-next';
import { createCampaignSchema, type CreateCampaignFormInput } from '~/utils/campaign-validation';
import { useCreateCampaignMutation } from '~/composables/campaigns/useCreateCampaignMutation';

const emit = defineEmits<{
  created: [campaignId: string];
}>();

const formError = ref('');
const createCampaign = useCreateCampaignMutation();
const today = new Date().toISOString().slice(0, 10);
const isCreating = computed(() => createCampaign.isPending.value);

const { defineField, errors, handleSubmit } = useForm<CreateCampaignFormInput>({
  validationSchema: toTypedSchema(createCampaignSchema),
  initialValues: {
    name: '',
    description: '',
    startDate: today,
    endDate: '',
  },
});

const [name, nameAttrs] = defineField('name');
const [description, descriptionAttrs] = defineField('description');
const [startDate, startDateAttrs] = defineField('startDate');
const [endDate, endDateAttrs] = defineField('endDate');

const onSubmit = handleSubmit(async (values) => {
  formError.value = '';

  try {
    const parsed = createCampaignSchema.parse(values);
    const created = await createCampaign.mutateAsync(parsed);
    emit('created', created.campaign_id);
  } catch (error) {
    formError.value =
      error instanceof Error ? error.message : 'Campaign could not be created. Try again.';
  }
});
</script>

<template>
  <form class="space-y-3" @submit="onSubmit">
    <YFormField label="Name" name="name">
      <UInput v-model="name" v-bind="nameAttrs" size="sm" autocomplete="off" />
      <p v-if="errors.name" class="mt-1 text-xs text-[var(--yife-error)]">{{ errors.name }}</p>
    </YFormField>

    <YFormField label="Description" name="description">
      <UTextarea v-model="description" v-bind="descriptionAttrs" :rows="3" size="sm" />
      <p v-if="errors.description" class="mt-1 text-xs text-[var(--yife-error)]">
        {{ errors.description }}
      </p>
    </YFormField>

    <div class="grid gap-3 sm:grid-cols-2">
      <YFormField label="Start date" name="startDate">
        <UInput v-model="startDate" v-bind="startDateAttrs" type="date" size="sm" />
        <p v-if="errors.startDate" class="mt-1 text-xs text-[var(--yife-error)]">
          {{ errors.startDate }}
        </p>
      </YFormField>

      <YFormField label="End date" name="endDate">
        <UInput v-model="endDate" v-bind="endDateAttrs" type="date" size="sm" />
        <p v-if="errors.endDate" class="mt-1 text-xs text-[var(--yife-error)]">
          {{ errors.endDate }}
        </p>
      </YFormField>
    </div>

    <p v-if="formError" class="text-sm text-[var(--yife-error)]">{{ formError }}</p>

    <div class="flex items-center justify-end gap-2">
      <YDenseButton type="submit" color="primary" :loading="isCreating" :disabled="isCreating">
        <Save class="size-4" aria-hidden="true" />
        Create campaign
      </YDenseButton>
    </div>
  </form>
</template>
