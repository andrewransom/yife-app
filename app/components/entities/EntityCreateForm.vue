<script setup lang="ts">
import { toTypedSchema } from '@vee-validate/zod';
import { useForm } from 'vee-validate';
import { computed, watch, ref } from 'vue';
import { Save } from 'lucide-vue-next';
import { useCurrentUser } from '~/composables/auth/useCurrentUser';
import { useCampaignMemberProfilesQuery } from '~/composables/campaigns/useCampaignMemberProfilesQuery';
import { useCreateEntityMutation } from '~/composables/entities/useCreateEntityMutation';
import { useEntityOptionDefinitionsQuery } from '~/composables/entities/useEntityOptionDefinitionsQuery';
import { useEntityStatusOptionsQuery } from '~/composables/entities/useEntityStatusOptionsQuery';
import type { EntityTypeOption } from '~/composables/entities/types';
import {
  createEntityBaseSchema,
  toCreateEntityRpcInput,
  validateCreateEntityInput,
  type CreateEntityFormInput,
} from '~/utils/entity-validation';

const props = defineProps<{
  campaignId: string;
  entityTypes: EntityTypeOption[];
  initialTypeKey?: string;
}>();

const emit = defineEmits<{
  created: [entityId: string];
  cancel: [];
}>();

const currentUser = useCurrentUser();
const formError = ref('');
const entityTypeKey = ref(
  props.initialTypeKey && props.initialTypeKey !== 'all' ? props.initialTypeKey : '',
);
const selectedType = computed(() =>
  props.entityTypes.find((type) => type.entity_type_key === entityTypeKey.value),
);
const canSubmit = computed(() => Boolean(selectedType.value?.can_create));
const isNameType = computed(() =>
  ['character', 'npc', 'party', 'faction', 'location'].includes(entityTypeKey.value),
);
const requiresStatus = computed(() =>
  ['character', 'quest', 'session', 'plot_arc', 'encounter'].includes(entityTypeKey.value),
);
const optionGroupKey = computed(() => {
  if (entityTypeKey.value === 'location') {
    return 'location_type';
  }
  if (entityTypeKey.value === 'quest') {
    return 'quest_priority';
  }
  if (entityTypeKey.value === 'encounter') {
    return 'encounter_type';
  }
  if (entityTypeKey.value === 'timeline_event') {
    return 'timeline_event_type';
  }
  return null;
});

const statusesQuery = useEntityStatusOptionsQuery(props.campaignId, entityTypeKey, {
  enabled: computed(() => Boolean(entityTypeKey.value)),
});
const optionsQuery = useEntityOptionDefinitionsQuery(
  props.campaignId,
  entityTypeKey,
  optionGroupKey,
  {
    enabled: computed(() => Boolean(optionGroupKey.value)),
  },
);
const membersQuery = useCampaignMemberProfilesQuery(props.campaignId, {
  enabled: computed(() => entityTypeKey.value === 'character'),
});
const createEntity = useCreateEntityMutation();
const isCreating = computed(() => createEntity.isPending.value);
const statuses = computed(() => statusesQuery.data.value ?? []);
const options = computed(() => optionsQuery.data.value ?? []);
const members = computed(() => membersQuery.data.value ?? []);

const { defineField, errors, handleSubmit, resetForm, setFieldValue } =
  useForm<CreateEntityFormInput>({
    validationSchema: toTypedSchema(createEntityBaseSchema),
    initialValues: {
      entityTypeKey: entityTypeKey.value,
      name: '',
      title: '',
      statusId: '',
      apparentStatusId: '',
      realStatusId: '',
      controllingUserId: '',
      locationTypeOptionId: '',
      priorityOptionId: '',
      encounterTypeOptionId: '',
      eventTypeOptionId: '',
      sessionDate: '',
      dateExpression: '',
      sortKey: '',
      isMajor: false,
    },
  });

const [name, nameAttrs] = defineField('name');
const [title, titleAttrs] = defineField('title');
const [statusId, statusAttrs] = defineField('statusId');
const [apparentStatusId, apparentStatusAttrs] = defineField('apparentStatusId');
const [realStatusId, realStatusAttrs] = defineField('realStatusId');
const [controllingUserId, controllingUserAttrs] = defineField('controllingUserId');
const [locationTypeOptionId, locationTypeAttrs] = defineField('locationTypeOptionId');
const [priorityOptionId, priorityAttrs] = defineField('priorityOptionId');
const [encounterTypeOptionId, encounterTypeAttrs] = defineField('encounterTypeOptionId');
const [eventTypeOptionId, eventTypeAttrs] = defineField('eventTypeOptionId');
const [sessionDate, sessionDateAttrs] = defineField('sessionDate');
const [dateExpression, dateExpressionAttrs] = defineField('dateExpression');
const [sortKey, sortKeyAttrs] = defineField('sortKey');
const [isMajor] = defineField('isMajor');

watch(
  () => props.initialTypeKey,
  (value) => {
    if (value && value !== 'all') {
      entityTypeKey.value = value;
    }
  },
);

watch(entityTypeKey, (value) => {
  setFieldValue('entityTypeKey', value);
  formError.value = '';
});

watch(
  () => statusesQuery.data.value,
  (statuses) => {
    const firstStatus = statuses?.[0]?.id ?? '';
    if (!statusId.value && firstStatus) {
      statusId.value = firstStatus;
    }
    if (entityTypeKey.value === 'npc' && !realStatusId.value && firstStatus) {
      realStatusId.value = firstStatus;
    }
  },
  { immediate: true },
);

watch(
  () => optionsQuery.data.value,
  (options) => {
    const firstOption = options?.[0]?.id ?? '';
    if (!firstOption) {
      return;
    }
    if (entityTypeKey.value === 'location' && !locationTypeOptionId.value) {
      locationTypeOptionId.value = firstOption;
    } else if (entityTypeKey.value === 'encounter' && !encounterTypeOptionId.value) {
      encounterTypeOptionId.value = firstOption;
    } else if (entityTypeKey.value === 'timeline_event' && !eventTypeOptionId.value) {
      eventTypeOptionId.value = firstOption;
    }
  },
  { immediate: true },
);

watch(
  () => membersQuery.data.value,
  (members) => {
    if (entityTypeKey.value !== 'character' || controllingUserId.value) {
      return;
    }

    controllingUserId.value =
      members?.find((member) => member.user_id === currentUser.value?.id)?.user_id ??
      members?.[0]?.user_id ??
      '';
  },
  { immediate: true },
);

const onSubmit = handleSubmit(async (values) => {
  formError.value = '';

  try {
    const parsed = validateCreateEntityInput({ ...values, entityTypeKey: entityTypeKey.value });
    const created = await createEntity.mutateAsync({
      campaignId: props.campaignId,
      entityTypeKey: parsed.entityTypeKey,
      input: toCreateEntityRpcInput(parsed),
    });
    resetForm();
    entityTypeKey.value = parsed.entityTypeKey;
    emit('created', created.entity_id);
  } catch (error) {
    formError.value = error instanceof Error ? error.message : 'Entity could not be created.';
  }
});
</script>

<template>
  <form class="space-y-3" @submit="onSubmit">
    <YFormField label="Type" name="entityTypeKey">
      <select
        v-model="entityTypeKey"
        aria-label="Entity type"
        class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
      >
        <option value="" disabled>Select type</option>
        <option
          v-for="type in entityTypes.filter((item) => item.can_create)"
          :key="type.entity_type_key"
          :value="type.entity_type_key"
        >
          {{ type.label }}
        </option>
      </select>
    </YFormField>

    <YFormField v-if="isNameType" label="Name" name="name">
      <UInput v-model="name" v-bind="nameAttrs" size="sm" autocomplete="off" />
      <p v-if="errors.name" class="mt-1 text-xs text-[var(--yife-error)]">{{ errors.name }}</p>
    </YFormField>

    <YFormField v-else label="Title" name="title">
      <UInput v-model="title" v-bind="titleAttrs" size="sm" autocomplete="off" />
      <p v-if="errors.title" class="mt-1 text-xs text-[var(--yife-error)]">{{ errors.title }}</p>
    </YFormField>

    <div v-if="entityTypeKey === 'character'" class="grid gap-3 sm:grid-cols-2">
      <YFormField label="Status" name="statusId">
        <select
          v-model="statusId"
          v-bind="statusAttrs"
          class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
        >
          <option value="" disabled>Status</option>
          <option v-for="status in statuses" :key="status.id" :value="status.id">
            {{ status.label }}
          </option>
        </select>
      </YFormField>
      <YFormField label="Controller" name="controllingUserId">
        <select
          v-model="controllingUserId"
          v-bind="controllingUserAttrs"
          class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
        >
          <option value="" disabled>Member</option>
          <option v-for="member in members" :key="member.user_id" :value="member.user_id">
            {{ member.display_name_override || member.display_name || member.user_id }}
          </option>
        </select>
      </YFormField>
    </div>

    <div v-else-if="entityTypeKey === 'npc'" class="grid gap-3 sm:grid-cols-2">
      <YFormField label="Real status" name="realStatusId">
        <select
          v-model="realStatusId"
          v-bind="realStatusAttrs"
          class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
        >
          <option value="" disabled>Status</option>
          <option v-for="status in statuses" :key="status.id" :value="status.id">
            {{ status.label }}
          </option>
        </select>
      </YFormField>
      <YFormField label="Apparent status" name="apparentStatusId">
        <select
          v-model="apparentStatusId"
          v-bind="apparentStatusAttrs"
          class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
        >
          <option value="">Same as real</option>
          <option v-for="status in statuses" :key="status.id" :value="status.id">
            {{ status.label }}
          </option>
        </select>
      </YFormField>
    </div>

    <YFormField v-else-if="statuses.length" label="Status" name="statusId">
      <select
        v-model="statusId"
        v-bind="statusAttrs"
        class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
      >
        <option :value="requiresStatus ? '' : ''" :disabled="requiresStatus">Status</option>
        <option v-for="status in statuses" :key="status.id" :value="status.id">
          {{ status.label }}
        </option>
      </select>
    </YFormField>

    <YFormField
      v-if="entityTypeKey === 'location'"
      label="Location type"
      name="locationTypeOptionId"
    >
      <select
        v-model="locationTypeOptionId"
        v-bind="locationTypeAttrs"
        class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
      >
        <option value="" disabled>Type</option>
        <option v-for="option in options" :key="option.id" :value="option.id">
          {{ option.label }}
        </option>
      </select>
    </YFormField>

    <YFormField v-if="entityTypeKey === 'quest'" label="Priority" name="priorityOptionId">
      <select
        v-model="priorityOptionId"
        v-bind="priorityAttrs"
        class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
      >
        <option value="">No priority</option>
        <option v-for="option in options" :key="option.id" :value="option.id">
          {{ option.label }}
        </option>
      </select>
      <label class="mt-2 flex items-center gap-2 text-sm">
        <input v-model="isMajor" type="checkbox" class="size-4" />
        Major quest
      </label>
    </YFormField>

    <YFormField v-if="entityTypeKey === 'session'" label="Session date" name="sessionDate">
      <UInput v-model="sessionDate" v-bind="sessionDateAttrs" type="date" size="sm" />
    </YFormField>

    <YFormField
      v-if="entityTypeKey === 'encounter'"
      label="Encounter type"
      name="encounterTypeOptionId"
    >
      <select
        v-model="encounterTypeOptionId"
        v-bind="encounterTypeAttrs"
        class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
      >
        <option value="" disabled>Type</option>
        <option v-for="option in options" :key="option.id" :value="option.id">
          {{ option.label }}
        </option>
      </select>
    </YFormField>

    <div v-if="entityTypeKey === 'timeline_event'" class="grid gap-3 sm:grid-cols-2">
      <YFormField label="Event type" name="eventTypeOptionId">
        <select
          v-model="eventTypeOptionId"
          v-bind="eventTypeAttrs"
          class="h-8 w-full rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] px-2 text-sm"
        >
          <option value="" disabled>Type</option>
          <option v-for="option in options" :key="option.id" :value="option.id">
            {{ option.label }}
          </option>
        </select>
      </YFormField>
      <YFormField label="Date expression" name="dateExpression">
        <UInput v-model="dateExpression" v-bind="dateExpressionAttrs" size="sm" />
      </YFormField>
      <YFormField label="Sort key" name="sortKey">
        <UInput v-model="sortKey" v-bind="sortKeyAttrs" size="sm" />
      </YFormField>
    </div>

    <p v-if="formError" class="text-sm text-[var(--yife-error)]">{{ formError }}</p>

    <div class="flex items-center justify-end gap-2">
      <YDenseButton variant="ghost" @click="emit('cancel')">Cancel</YDenseButton>
      <YDenseButton
        type="submit"
        color="primary"
        :loading="isCreating"
        :disabled="isCreating || !canSubmit"
      >
        <Save class="size-4" aria-hidden="true" />
        Create
      </YDenseButton>
    </div>
  </form>
</template>
