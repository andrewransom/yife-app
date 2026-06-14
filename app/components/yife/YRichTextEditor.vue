<script setup lang="ts">
import { computed, onBeforeUnmount, watch } from 'vue';
import { Bold, Code, Heading2, Italic, Link2, List, ListOrdered, Minus, Quote } from 'lucide-vue-next';
import Mention from '@tiptap/extension-mention';
import Link from '@tiptap/extension-link';
import StarterKit from '@tiptap/starter-kit';
import { EditorContent, useEditor } from '@tiptap/vue-3';
import { useCampaignEntitySummariesQuery } from '~/composables/entities/useCampaignEntitySummariesQuery';
import { normalizeRichTextDocument, isSafeExternalUrl } from '~/utils/rich-text';

const props = withDefaults(
  defineProps<{
    modelValue: Record<string, unknown>;
    campaignId: string;
    disabled?: boolean;
    activeRoleView?: 'gm' | 'player';
  }>(),
  {
    disabled: false,
    activeRoleView: 'gm',
  },
);

const emit = defineEmits<{
  'update:modelValue': [value: Record<string, unknown>];
}>();

const summariesQuery = useCampaignEntitySummariesQuery(() => props.campaignId, {
  enabled: computed(() => Boolean(props.campaignId)),
});
const visibleSummaries = computed(() =>
  (summariesQuery.data.value ?? []).filter((item) => {
    if (props.activeRoleView !== 'player') {
      return true;
    }

    return item.default_visibility === 'shared';
  }),
);

type MentionItem = {
  id: string;
  label: string;
  meta: string;
};

type SuggestionRenderProps = {
  clientRect?: (() => DOMRect | null) | null;
  command: (item: { id: string; label: string }) => void;
  items: MentionItem[];
};

type SuggestionRenderer = {
  onStart: (props: SuggestionRenderProps) => void;
  onUpdate: (props: SuggestionRenderProps) => void;
  onKeyDown: (props: { event: KeyboardEvent }) => boolean;
  onExit: () => void;
};

function createSuggestionRenderer(): SuggestionRenderer {
  let element: HTMLDivElement | null = null;
  let selectedIndex = 0;
  let currentItems: MentionItem[] = [];
  let currentCommand: ((item: MentionItem) => void) | null = null;

  const updatePosition = (clientRect?: (() => DOMRect | null) | null) => {
    if (!element || !clientRect) {
      return;
    }

    const rect = clientRect();

    if (!rect) {
      return;
    }

    element.style.left = `${rect.left + window.scrollX}px`;
    element.style.top = `${rect.bottom + window.scrollY + 4}px`;
  };

  const renderItems = (command: (item: MentionItem) => void) => {
    if (!element) {
      return;
    }

    currentCommand = command;
    element.innerHTML = '';

    if (!currentItems.length) {
      const empty = document.createElement('div');
      empty.className = 'px-2 py-1 text-xs text-[var(--yife-text-muted)]';
      empty.textContent = 'No matching records';
      element.appendChild(empty);
      return;
    }

    currentItems.forEach((item, index) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className =
        'block w-full px-2 py-1 text-left text-sm hover:bg-[var(--yife-surface-muted)]';
      if (index === selectedIndex) {
        button.className += ' bg-[var(--yife-surface-muted)]';
      }
      const label = document.createElement('div');
      label.textContent = item.label;
      const meta = document.createElement('div');
      meta.className = 'text-xs text-[var(--yife-text-muted)]';
      meta.textContent = item.meta;
      button.appendChild(label);
      button.appendChild(meta);
      button.addEventListener('mousedown', (event) => {
        event.preventDefault();
        command(item);
      });
      element?.appendChild(button);
    });
  };

  const create = () => {
    element = document.createElement('div');
    element.className =
      'fixed z-50 min-w-52 rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)] p-1 shadow-lg';
    document.body.appendChild(element);
  };

  const destroy = () => {
    element?.remove();
    element = null;
    currentItems = [];
    selectedIndex = 0;
    currentCommand = null;
  };

  return {
    onStart: (props: SuggestionRenderProps) => {
      create();
      currentItems = props.items;
      selectedIndex = 0;
      updatePosition(props.clientRect);
      renderItems((item) => props.command({ id: item.id, label: item.label }));
    },
    onUpdate: (props: SuggestionRenderProps) => {
      currentItems = props.items;
      selectedIndex = 0;
      updatePosition(props.clientRect);
      renderItems((item) => props.command({ id: item.id, label: item.label }));
    },
    onKeyDown: ({ event }: { event: KeyboardEvent }) => {
      if (!currentItems.length) {
        return false;
      }

      if (event.key === 'ArrowDown') {
        selectedIndex = (selectedIndex + 1) % currentItems.length;
        return true;
      }

      if (event.key === 'ArrowUp') {
        selectedIndex = (selectedIndex + currentItems.length - 1) % currentItems.length;
        return true;
      }

      if (event.key === 'Enter') {
        const selectedItem = currentItems[selectedIndex];

        if (selectedItem) {
          currentCommand?.(selectedItem);
        }
        return true;
      }

      if (event.key === 'Escape') {
        destroy();
        return true;
      }

      return false;
    },
    onExit: destroy,
  };
}

const editor = useEditor({
  content: normalizeRichTextDocument(props.modelValue),
  editable: !props.disabled,
  extensions: [
    StarterKit.configure({
      heading: { levels: [1, 2, 3] },
    }),
    Link.configure({
      openOnClick: false,
      autolink: false,
      HTMLAttributes: {
        rel: 'noreferrer noopener',
        target: '_blank',
      },
      isAllowedUri: (href) => isSafeExternalUrl(href),
    }),
    Mention.configure({
      HTMLAttributes: {
        class:
          'rounded-[4px] bg-[var(--yife-surface-muted)] px-1 py-0.5 text-[var(--yife-link)]',
      },
      suggestion: {
        char: '@',
        items: ({ query }) =>
          visibleSummaries.value
            .filter((item) => item.list_caption.toLowerCase().includes(query.toLowerCase()))
            .slice(0, 8)
            .map((item) => ({
              id: item.entity_id,
              label: item.list_caption,
              meta: [item.entity_type_key, item.status_label].filter(Boolean).join(' • '),
            })),
        render: () => createSuggestionRenderer(),
        command: ({ editor: activeEditor, range, props: mention }) => {
          activeEditor
            .chain()
            .focus()
            .insertContentAt(range, [
              {
                type: 'mention',
                attrs: {
                  entityId: mention.id,
                  label: mention.label,
                },
              },
              {
                type: 'text',
                text: ' ',
              },
            ])
            .run();
        },
      },
    }),
  ],
  onUpdate: ({ editor: activeEditor }) => {
    emit('update:modelValue', activeEditor.getJSON() as Record<string, unknown>);
  },
});

watch(
  () => props.modelValue,
  (value) => {
    const activeEditor = editor.value;

    if (!activeEditor) {
      return;
    }

    const next = JSON.stringify(normalizeRichTextDocument(value));
    const current = JSON.stringify(activeEditor.getJSON());

    if (next !== current) {
      activeEditor.commands.setContent(normalizeRichTextDocument(value), {
        emitUpdate: false,
      });
    }
  },
);

watch(
  () => props.disabled,
  (value) => {
    editor.value?.setEditable(!value);
  },
);

function applyLink() {
  const href = window.prompt('Link URL');

  if (!href) {
    return;
  }

  if (!isSafeExternalUrl(href)) {
    return;
  }

  editor.value?.chain().focus().setLink({ href }).run();
}

function toggle(command: () => void) {
  if (props.disabled) {
    return;
  }

  command();
}

onBeforeUnmount(() => {
  editor.value?.destroy();
});
</script>

<template>
  <div class="rounded-[4px] border border-[var(--yife-border)] bg-[var(--yife-surface)]">
    <div class="flex flex-wrap gap-1 border-b border-[var(--yife-border)] p-2">
      <YIconButton :icon="Bold" label="Bold" :disabled="disabled" @click="toggle(() => editor?.chain().focus().toggleBold().run())" />
      <YIconButton :icon="Italic" label="Italic" :disabled="disabled" @click="toggle(() => editor?.chain().focus().toggleItalic().run())" />
      <YIconButton :icon="Code" label="Inline code" :disabled="disabled" @click="toggle(() => editor?.chain().focus().toggleCode().run())" />
      <YIconButton :icon="Heading2" label="Heading" :disabled="disabled" @click="toggle(() => editor?.chain().focus().toggleHeading({ level: 2 }).run())" />
      <YIconButton :icon="List" label="Bullet list" :disabled="disabled" @click="toggle(() => editor?.chain().focus().toggleBulletList().run())" />
      <YIconButton :icon="ListOrdered" label="Ordered list" :disabled="disabled" @click="toggle(() => editor?.chain().focus().toggleOrderedList().run())" />
      <YIconButton :icon="Quote" label="Blockquote" :disabled="disabled" @click="toggle(() => editor?.chain().focus().toggleBlockquote().run())" />
      <YIconButton :icon="Minus" label="Horizontal rule" :disabled="disabled" @click="toggle(() => editor?.chain().focus().setHorizontalRule().run())" />
      <YIconButton :icon="Link2" label="Link" :disabled="disabled" @click="applyLink" />
    </div>
    <EditorContent
      :editor="editor"
      class="min-h-36 px-3 py-2 text-sm text-[var(--yife-text)]"
    />
    <p class="border-t border-[var(--yife-border)] px-3 py-2 text-xs text-[var(--yife-text-muted)]">
      Type `@` to mention a visible campaign record.
    </p>
  </div>
</template>

<style scoped>
:deep(.ProseMirror) {
  min-height: 8rem;
  outline: none;
  white-space: pre-wrap;
}

:deep(.ProseMirror p.is-editor-empty:first-child::before) {
  color: var(--yife-text-muted);
  content: attr(data-placeholder);
  float: left;
  height: 0;
  pointer-events: none;
}
</style>
