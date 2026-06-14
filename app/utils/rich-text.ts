export type RichTextMark =
  | { type: 'bold' }
  | { type: 'italic' }
  | { type: 'code' }
  | { type: 'link'; attrs?: { href?: string | null } };

export type RichTextNode = {
  type: string;
  text?: string;
  attrs?: Record<string, unknown>;
  marks?: RichTextMark[];
  content?: RichTextNode[];
};

export type RichTextDocument = {
  type: 'doc';
  content: RichTextNode[];
};

export type RichTextMention = {
  entity_id: string;
  label: string;
};

const SUPPORTED_NODE_TYPES = new Set([
  'doc',
  'paragraph',
  'text',
  'heading',
  'bulletList',
  'orderedList',
  'listItem',
  'blockquote',
  'horizontalRule',
  'mention',
  'hardBreak',
]);
const SUPPORTED_MARK_TYPES = new Set(['bold', 'italic', 'code', 'link']);
const DEFAULT_DOCUMENT: RichTextDocument = {
  type: 'doc',
  content: [{ type: 'paragraph' }],
};

export function createDefaultRichTextDocument(): RichTextDocument {
  return structuredClone(DEFAULT_DOCUMENT);
}

export function isSafeExternalUrl(value: string) {
  try {
    const url = new URL(value);
    return url.protocol === 'http:' || url.protocol === 'https:';
  } catch {
    return false;
  }
}

function normalizeNode(node: unknown): RichTextNode {
  if (!node || typeof node !== 'object' || Array.isArray(node)) {
    throw new Error('Invalid rich text node.');
  }

  const record = node as Record<string, unknown>;
  const type = typeof record.type === 'string' ? record.type : '';

  if (!SUPPORTED_NODE_TYPES.has(type)) {
    throw new Error(`Unsupported rich text node: ${type || 'unknown'}.`);
  }

  const normalized: RichTextNode = { type };

  if (type === 'text') {
    if (typeof record.text !== 'string') {
      throw new Error('Text nodes require a text string.');
    }
    normalized.text = record.text;
  }

  if (record.attrs !== undefined) {
    if (!record.attrs || typeof record.attrs !== 'object' || Array.isArray(record.attrs)) {
      throw new Error('Invalid rich text attrs.');
    }

    normalized.attrs = record.attrs as Record<string, unknown>;

    if (type === 'mention') {
      const entityId = normalized.attrs.entityId;
      const label = normalized.attrs.label;

      if (typeof entityId !== 'string' || !entityId.length) {
        throw new Error('Mention nodes require attrs.entityId.');
      }

      if (typeof label !== 'string' || !label.trim().length) {
        throw new Error('Mention nodes require attrs.label.');
      }
    }
  }

  if (record.marks !== undefined) {
    if (!Array.isArray(record.marks)) {
      throw new Error('Invalid rich text marks.');
    }

    normalized.marks = record.marks.map((mark) => {
      if (!mark || typeof mark !== 'object' || Array.isArray(mark)) {
        throw new Error('Invalid rich text mark.');
      }

      const markRecord = mark as Record<string, unknown>;
      const markType = typeof markRecord.type === 'string' ? markRecord.type : '';

      if (!SUPPORTED_MARK_TYPES.has(markType)) {
        throw new Error(`Unsupported rich text mark: ${markType || 'unknown'}.`);
      }

      if (markType === 'link') {
        const href = typeof markRecord.attrs === 'object' ? (markRecord.attrs as { href?: unknown }).href : undefined;

        if (href !== undefined && href !== null && (typeof href !== 'string' || !isSafeExternalUrl(href))) {
          throw new Error('Link mark uses an unsafe URL.');
        }
      }

      return markRecord as RichTextMark;
    });
  }

  if (record.content !== undefined) {
    if (!Array.isArray(record.content)) {
      throw new Error('Invalid rich text content.');
    }

    normalized.content = record.content.map(normalizeNode);
  }

  return normalized;
}

export function normalizeRichTextDocument(document: unknown): RichTextDocument {
  if (!document || typeof document !== 'object' || Array.isArray(document)) {
    throw new Error('Invalid rich text document.');
  }

  const normalized = normalizeNode(document);

  if (normalized.type !== 'doc') {
    throw new Error('Rich text root must be a doc node.');
  }

  return {
    type: 'doc',
    content: normalized.content ?? [{ type: 'paragraph' }],
  };
}

function collectText(node: RichTextNode, mentions: RichTextMention[]): string {
  if (node.type === 'text' && node.text) {
    return node.text;
  }

  if (node.type === 'mention') {
    const entityId = typeof node.attrs?.entityId === 'string' ? node.attrs.entityId : '';
    const label = typeof node.attrs?.label === 'string' ? node.attrs.label.trim() : '';

    if (entityId && label) {
      mentions.push({
        entity_id: entityId,
        label,
      });
      return `@${label}`;
    }

    return '';
  }

  if (node.type === 'horizontalRule') {
    return '---';
  }

  if (node.type === 'hardBreak') {
    return '\n';
  }

  const childText: string = (node.content ?? [])
    .map((child) => collectText(child, mentions))
    .join('');

  if (['paragraph', 'heading', 'blockquote', 'listItem'].includes(node.type)) {
    return childText ? `${childText}\n` : '';
  }

  if (['bulletList', 'orderedList', 'doc'].includes(node.type)) {
    return childText;
  }

  return childText;
}

export function extractRichText(document: unknown) {
  const normalized = normalizeRichTextDocument(document);
  const mentions: RichTextMention[] = [];
  const bodyText = collectText(normalized, mentions).replace(/\n{3,}/g, '\n\n').trim();
  const bodyPreview = bodyText.slice(0, 280) || null;

  return {
    bodyJson: normalized,
    bodyText,
    bodyPreview,
    mentions,
  };
}

export function isStaleConflictError(error: unknown) {
  if (!error || typeof error !== 'object') {
    return false;
  }

  const message = 'message' in error ? String(error.message) : '';
  return message.includes('stale_conflict');
}
