import { describe, expect, it } from 'vitest';
import { createDefaultRichTextDocument, extractRichText, isSafeExternalUrl, normalizeRichTextDocument } from '../../app/utils/rich-text';

describe('rich text utilities', () => {
  it('derives body text, preview, and mentions from the supported document format', () => {
    const document = {
      type: 'doc',
      content: [
        {
          type: 'paragraph',
          content: [
            { type: 'text', text: 'Meet ' },
            { type: 'mention', attrs: { entityId: 'entity-1', label: 'Ari Voss' } },
            { type: 'text', text: ' at dawn.' },
          ],
        },
      ],
    };

    expect(extractRichText(document)).toEqual({
      bodyJson: document,
      bodyText: 'Meet @Ari Voss at dawn.',
      bodyPreview: 'Meet @Ari Voss at dawn.',
      mentions: [{ entity_id: 'entity-1', label: 'Ari Voss' }],
    });
  });

  it('rejects unsupported node types', () => {
    expect(() =>
      normalizeRichTextDocument({
        type: 'doc',
        content: [{ type: 'table' }],
      }),
    ).toThrow(/Unsupported rich text node/);
  });

  it('validates only http and https links', () => {
    expect(isSafeExternalUrl('https://example.com')).toBe(true);
    expect(isSafeExternalUrl('http://example.com')).toBe(true);
    expect(isSafeExternalUrl('javascript:alert(1)')).toBe(false);
  });

  it('returns a stable empty default document', () => {
    expect(createDefaultRichTextDocument()).toEqual({
      type: 'doc',
      content: [{ type: 'paragraph' }],
    });
  });
});
