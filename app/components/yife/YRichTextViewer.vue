<script setup lang="ts">
import { computed, defineComponent, h, type PropType, type VNodeChild } from 'vue';
import { useEntityReferenceResolutionsQuery } from '~/composables/entities/useEntityReferenceResolutionsQuery';
import { normalizeRichTextDocument, isSafeExternalUrl, type RichTextNode } from '~/utils/rich-text';

const props = defineProps<{
  campaignId: string;
  document: Record<string, unknown> | null | undefined;
}>();

function collectMentionIds(node: RichTextNode, values: Set<string>) {
  if (node.type === 'mention' && typeof node.attrs?.entityId === 'string') {
    values.add(node.attrs.entityId);
  }

  for (const child of node.content ?? []) {
    collectMentionIds(child, values);
  }
}

const mentionEntityIds = computed(() => {
  const values = new Set<string>();

  try {
    const document = normalizeRichTextDocument(props.document ?? undefined);

    for (const node of document.content) {
      collectMentionIds(node, values);
    }
  } catch {
    return [] as string[];
  }

  return Array.from(values).sort();
});

const resolutionsQuery = useEntityReferenceResolutionsQuery(() => props.campaignId, mentionEntityIds, {
  enabled: computed(() => Boolean(props.campaignId) && mentionEntityIds.value.length > 0),
});

const resolutionMap = computed(() => {
  const map = new Map<
    string,
    { display_label: string; resolution_state: string; entity_type_key: string | null }
  >();

  for (const item of resolutionsQuery.data.value ?? []) {
    map.set(item.requested_entity_id, {
      display_label: item.display_label,
      resolution_state: item.resolution_state,
      entity_type_key: item.entity_type_key,
    });
  }

  return map;
});

function applyMarks(content: VNodeChild, marks: RichTextNode['marks'], keyPrefix: string): VNodeChild {
  return (marks ?? []).reduce<VNodeChild>((output, mark, index) => {
    if (mark.type === 'bold') {
      return h('strong', { key: `${keyPrefix}-bold-${index}` }, () => output);
    }

    if (mark.type === 'italic') {
      return h('em', { key: `${keyPrefix}-italic-${index}` }, () => output);
    }

    if (mark.type === 'code') {
      return h('code', { key: `${keyPrefix}-code-${index}` }, () => output);
    }

    if (mark.type === 'link') {
      const href = mark.attrs?.href;

      if (typeof href !== 'string' || !isSafeExternalUrl(href)) {
        return output;
      }

      return h(
        'a',
        {
          key: `${keyPrefix}-link-${index}`,
          href,
          target: '_blank',
          rel: 'noreferrer noopener',
        },
        () => output,
      );
    }

    return output;
  }, content);
}

function renderInline(node: RichTextNode, keyPrefix: string): VNodeChild {
  if (node.type === 'text') {
    return applyMarks(node.text ?? '', node.marks, keyPrefix);
  }

  if (node.type === 'mention') {
    const entityId = typeof node.attrs?.entityId === 'string' ? node.attrs.entityId : null;
    const fallbackLabel = typeof node.attrs?.label === 'string' ? node.attrs.label : 'Unavailable record';
    const resolution = entityId ? resolutionMap.value.get(entityId) : null;
    const label = resolution?.display_label ?? fallbackLabel;
    const stateClass =
      resolution?.resolution_state === 'visible'
        ? 'text-[var(--yife-link)]'
        : 'text-[var(--yife-text-muted)]';

    return h(
      'span',
      {
        key: keyPrefix,
        class: ['rounded-[4px] bg-[var(--yife-surface-muted)] px-1 py-0.5', stateClass],
      },
      `@${label}`,
    );
  }

  if (node.type === 'hardBreak') {
    return h('br', { key: keyPrefix });
  }

  return renderInlineNodes(node.content ?? [], keyPrefix);
}

function renderInlineNodes(nodes: RichTextNode[], keyPrefix: string): VNodeChild[] {
  return nodes.map((node, index) => renderInline(node, `${keyPrefix}-inline-${index}`));
}

function renderBlock(node: RichTextNode, keyPrefix: string): VNodeChild {
  if (node.type === 'paragraph') {
    const children = renderInlineNodes(node.content ?? [], keyPrefix);
    return h('p', { key: keyPrefix }, children.length ? children : [h('br')]);
  }

  if (node.type === 'heading') {
    const level = Number(node.attrs?.level) || 2;
    const safeLevel = Math.min(3, Math.max(1, level));
    return h(`h${safeLevel}`, { key: keyPrefix }, renderInlineNodes(node.content ?? [], keyPrefix));
  }

  if (node.type === 'blockquote') {
    return h('blockquote', { key: keyPrefix }, renderBlockNodes(node.content ?? [], keyPrefix));
  }

  if (node.type === 'horizontalRule') {
    return h('hr', { key: keyPrefix });
  }

  if (node.type === 'bulletList') {
    return h('ul', { key: keyPrefix }, renderBlockNodes(node.content ?? [], keyPrefix));
  }

  if (node.type === 'orderedList') {
    return h('ol', { key: keyPrefix }, renderBlockNodes(node.content ?? [], keyPrefix));
  }

  if (node.type === 'listItem') {
    return h('li', { key: keyPrefix }, renderBlockNodes(node.content ?? [], keyPrefix));
  }

  const children = renderInlineNodes(node.content ?? [], keyPrefix);
  return children.length ? h('p', { key: keyPrefix }, children) : h('p', { key: keyPrefix }, [h('br')]);
}

function renderBlockNodes(nodes: RichTextNode[], keyPrefix: string): VNodeChild[] {
  return nodes.map((node, index) => renderBlock(node, `${keyPrefix}-block-${index}`));
}

const renderedBlocks = computed(() => {
  try {
    const document = normalizeRichTextDocument(props.document ?? undefined);
    return renderBlockNodes(document.content, 'root');
  } catch {
    return [h('p', { key: 'unsupported' }, 'Unsupported rich text content.')];
  }
});

const RichTextBlocks = defineComponent({
  name: 'RichTextBlocks',
  props: {
    nodes: {
      type: Array as PropType<VNodeChild[]>,
      required: true,
    },
  },
  setup(componentProps) {
    return () => componentProps.nodes;
  },
});
</script>

<template>
  <div class="y-rich-text-viewer prose prose-sm max-w-none text-[var(--yife-text)]">
    <RichTextBlocks :nodes="renderedBlocks" />
  </div>
</template>

<style scoped>
.y-rich-text-viewer :deep(blockquote) {
  border-left: 2px solid var(--yife-border);
  margin: 0;
  padding-left: 0.75rem;
}

.y-rich-text-viewer :deep(code) {
  border-radius: 4px;
  background: var(--yife-surface-muted);
  padding: 0.1rem 0.3rem;
}

.y-rich-text-viewer :deep(hr) {
  border: 0;
  border-top: 1px solid var(--yife-border);
}
</style>
