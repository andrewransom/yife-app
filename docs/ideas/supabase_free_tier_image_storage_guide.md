# Supabase Free-Tier Image Storage and Thumbnail Serving Guide

## Purpose

This guide summarizes a practical approach for storing and serving images on the Supabase Free tier, especially for applications that need to display many thumbnail images in grids.

The recommended strategy is:

> Generate optimized image variants locally before upload, store those variants in Supabase Storage, and store image metadata in Supabase Postgres.

This avoids relying on paid image transformation features, keeps bandwidth and storage predictable, and gives the UI a clean way to browse and render images efficiently.

---

## Recommended Architecture

```text
Client app
  - User selects image
  - Client generates local variants
  - Client uploads variants to Supabase Storage
  - Client or API writes metadata to Postgres

Supabase Storage
  - Stores optimized image files
  - Serves images through public or signed URLs

Supabase Postgres
  - Stores asset records
  - Stores variant records
  - Drives grid queries and image browsing

Frontend grid
  - Queries Postgres for media records
  - Uses stored variant paths
  - Renders thumbnails with lazy loading and srcset
```

---

## Why This Works Well on the Free Tier

Supabase Image Transformations are useful, but they are not the best default for a Free-tier, thumbnail-heavy application. A grid view can request many thumbnails at once, and dynamic transformations can become a cost or quota concern once the project grows.

Instead, generate the exact thumbnail files you need before upload.

Benefits:

- Predictable storage and bandwidth usage
- No dependency on paid image transformation features
- Fast grid rendering
- Simple CDN/browser caching
- Easier migration to backend thumbnail generation later
- Works across web, mobile web, and native mobile apps

---

## Recommended Image Variants

Start with only the variants you actually render.

| Variant | Suggested size | Purpose | Required? |
|---|---:|---|---|
| `thumb_160` | 160px wide or square | Dense grid, tiny previews, placeholders | Yes |
| `grid_480` | 480px wide or square | Main grid/card image | Yes |
| `original_1600` | Max 1600px or 2048px | Optional larger preview or future reprocessing | Optional |

Avoid storing many variants at the beginning. On the Free tier, two generated variants is usually enough.

---

## Storage Layout

Use deterministic paths that are easy to derive from the database record.

### Simple layout

```text
images/
  {user_id}/
    {asset_id}/
      thumb_160.webp
      grid_480.webp
      original_1600.webp
```

### Better cache-friendly layout

```text
images/
  {user_id}/
    {asset_id}/
      {version_or_hash}/
        thumb_160.webp
        grid_480.webp
        original_1600.webp
```

The versioned or hash-based layout is better because it avoids overwriting existing image URLs. New versions create new paths, which makes browser and CDN caching much easier.

---

## Bucket Strategy

### Public bucket

Use a public bucket when images are not sensitive.

Best for:

- Public galleries
- Product images
- Avatars
- Public project thumbnails
- Shared media libraries

Advantages:

- Simpler URLs
- Easier caching
- Better grid performance
- No signed URL generation needed

### Private bucket

Use a private bucket when images are user-private or workspace-private.

Best for:

- Personal images
- Private project assets
- Sensitive user uploads
- Internal documents or screenshots

Tradeoffs:

- Requires signed URLs
- More backend or client URL management
- More care needed around expiry and caching

For early development on the Free tier, use public buckets only for genuinely public images.

---

## Postgres Metadata Model

The UI should not list Supabase Storage objects directly for every grid. Instead, store image metadata in Postgres and use it as the source for browsing, filtering, ownership, and rendering.

### `media_assets` table

Represents the logical image asset.

```sql
create table media_assets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  bucket text not null default 'images',
  original_path text,
  status text not null default 'uploading',
  title text,
  alt_text text,
  width integer,
  height integer,
  mime_type text,
  byte_size bigint,
  dominant_color text,
  blurhash text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index media_assets_owner_created_idx
  on media_assets (owner_id, created_at desc);

create index media_assets_status_idx
  on media_assets (status);
```

Suggested `status` values:

| Status | Meaning |
|---|---|
| `uploading` | Asset row exists, but files are not fully uploaded yet. |
| `ready` | Required variants exist and the image can be shown in the UI. |
| `failed` | Upload or local processing failed. |
| `deleted` | Soft-deleted or pending cleanup. |

---

### `media_asset_variants` table

Represents each stored file variant for a logical asset.

```sql
create table media_asset_variants (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references media_assets(id) on delete cascade,
  variant text not null,
  bucket text not null default 'images',
  path text not null,
  width integer not null,
  height integer not null,
  format text not null default 'webp',
  mime_type text not null default 'image/webp',
  byte_size bigint,
  created_at timestamptz not null default now(),
  unique (asset_id, variant)
);

create index media_asset_variants_asset_idx
  on media_asset_variants (asset_id);

create index media_asset_variants_variant_idx
  on media_asset_variants (variant);
```

Example records:

```json
{
  "media_assets": {
    "id": "b7b1a4d8-0000-4000-9000-123456789abc",
    "owner_id": "user_123",
    "bucket": "images",
    "original_path": "user_123/b7b1a4d8/v1/original_1600.webp",
    "status": "ready",
    "title": "Project screenshot",
    "alt_text": "Screenshot of the project dashboard",
    "width": 1600,
    "height": 1067,
    "mime_type": "image/webp",
    "byte_size": 284000
  },
  "media_asset_variants": [
    {
      "asset_id": "b7b1a4d8-0000-4000-9000-123456789abc",
      "variant": "thumb_160",
      "bucket": "images",
      "path": "user_123/b7b1a4d8/v1/thumb_160.webp",
      "width": 160,
      "height": 160,
      "format": "webp",
      "mime_type": "image/webp",
      "byte_size": 8200
    },
    {
      "asset_id": "b7b1a4d8-0000-4000-9000-123456789abc",
      "variant": "grid_480",
      "bucket": "images",
      "path": "user_123/b7b1a4d8/v1/grid_480.webp",
      "width": 480,
      "height": 480,
      "format": "webp",
      "mime_type": "image/webp",
      "byte_size": 42000
    }
  ]
}
```

---

## Optional Jobs Table for Later Repair or Reprocessing

If thumbnails are generated locally, you do not need a backend queue at the start. However, a jobs table is useful for later repair, retries, or server-side regeneration.

```sql
create table thumbnail_jobs (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references media_assets(id) on delete cascade,
  status text not null default 'pending',
  attempts integer not null default 0,
  max_attempts integer not null default 5,
  locked_at timestamptz,
  locked_by text,
  error text,
  created_at timestamptz not null default now(),
  available_at timestamptz not null default now(),
  completed_at timestamptz
);

create index thumbnail_jobs_pending_idx
  on thumbnail_jobs (status, available_at, created_at)
  where status = 'pending';
```

Use this later if you add an Edge Function or external worker to regenerate variants.

---

## Local Variant Generation

Local variant generation means resizing and compressing the image on the user's device before uploading it.

### Browser flow

```text
User selects image
  -> Browser reads file
  -> Browser decodes image
  -> Browser resizes/crops with canvas
  -> Browser exports WebP or JPEG blob
  -> App uploads generated blobs to Supabase Storage
  -> App writes variant metadata to Postgres
```

### Browser APIs

| API | Purpose |
|---|---|
| `File` / `Blob` | Represents the selected image. |
| `URL.createObjectURL()` | Creates a temporary local URL for decoding. |
| `Image` or `createImageBitmap()` | Decodes the image. |
| `<canvas>` or `OffscreenCanvas` | Resizes or crops the image. |
| `canvas.toBlob()` | Encodes the resized image as JPEG, PNG, or WebP. |
| Supabase Storage client | Uploads generated blobs. |

---

## Example Browser Resize Function

```ts
async function resizeImageToSquare(
  file: File,
  size: number,
  outputType = 'image/webp',
  quality = 0.82
): Promise<Blob> {
  const imageUrl = URL.createObjectURL(file);

  try {
    const img = new Image();
    img.src = imageUrl;
    await img.decode();

    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;

    const ctx = canvas.getContext('2d');
    if (!ctx) throw new Error('Canvas not supported');

    const sourceRatio = img.width / img.height;
    const targetRatio = 1;

    let sourceX = 0;
    let sourceY = 0;
    let sourceWidth = img.width;
    let sourceHeight = img.height;

    if (sourceRatio > targetRatio) {
      sourceWidth = img.height * targetRatio;
      sourceX = (img.width - sourceWidth) / 2;
    } else {
      sourceHeight = img.width / targetRatio;
      sourceY = (img.height - sourceHeight) / 2;
    }

    ctx.drawImage(
      img,
      sourceX,
      sourceY,
      sourceWidth,
      sourceHeight,
      0,
      0,
      size,
      size
    );

    return await new Promise<Blob>((resolve, reject) => {
      canvas.toBlob(
        blob => {
          if (!blob) reject(new Error('Image encoding failed'));
          else resolve(blob);
        },
        outputType,
        quality
      );
    });
  } finally {
    URL.revokeObjectURL(imageUrl);
  }
}
```

---

## Example Upload Flow

```ts
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function uploadImageWithVariants(file: File, userId: string) {
  const assetId = crypto.randomUUID();
  const version = 'v1';
  const bucket = 'images';

  const thumb = await resizeImageToSquare(file, 160, 'image/webp', 0.75);
  const grid = await resizeImageToSquare(file, 480, 'image/webp', 0.82);

  const thumbPath = `${userId}/${assetId}/${version}/thumb_160.webp`;
  const gridPath = `${userId}/${assetId}/${version}/grid_480.webp`;

  // 1. Create asset row in uploading state.
  const { error: assetError } = await supabase
    .from('media_assets')
    .insert({
      id: assetId,
      owner_id: userId,
      bucket,
      status: 'uploading',
      mime_type: file.type,
      byte_size: file.size
    });

  if (assetError) throw assetError;

  // 2. Upload generated variants.
  const { error: thumbError } = await supabase.storage
    .from(bucket)
    .upload(thumbPath, thumb, {
      contentType: 'image/webp',
      cacheControl: '31536000',
      upsert: false
    });

  if (thumbError) throw thumbError;

  const { error: gridError } = await supabase.storage
    .from(bucket)
    .upload(gridPath, grid, {
      contentType: 'image/webp',
      cacheControl: '31536000',
      upsert: false
    });

  if (gridError) throw gridError;

  // 3. Insert variant metadata.
  const { error: variantsError } = await supabase
    .from('media_asset_variants')
    .insert([
      {
        asset_id: assetId,
        variant: 'thumb_160',
        bucket,
        path: thumbPath,
        width: 160,
        height: 160,
        format: 'webp',
        mime_type: 'image/webp',
        byte_size: thumb.size
      },
      {
        asset_id: assetId,
        variant: 'grid_480',
        bucket,
        path: gridPath,
        width: 480,
        height: 480,
        format: 'webp',
        mime_type: 'image/webp',
        byte_size: grid.size
      }
    ]);

  if (variantsError) throw variantsError;

  // 4. Mark asset ready.
  const { error: readyError } = await supabase
    .from('media_assets')
    .update({ status: 'ready', updated_at: new Date().toISOString() })
    .eq('id', assetId);

  if (readyError) throw readyError;

  return { assetId, thumbPath, gridPath };
}
```

---

## Serving Images in a Grid

For public buckets, get public URLs from the stored paths.

```ts
function getPublicImageUrl(bucket: string, path: string) {
  const { data } = supabase.storage.from(bucket).getPublicUrl(path);
  return data.publicUrl;
}
```

The grid should query Postgres for assets and variants, not list Storage directly.

Example query shape:

```sql
select
  a.id,
  a.title,
  a.alt_text,
  a.status,
  v.variant,
  v.bucket,
  v.path,
  v.width,
  v.height
from media_assets a
join media_asset_variants v
  on v.asset_id = a.id
where a.owner_id = :owner_id
  and a.status = 'ready'
  and v.variant in ('thumb_160', 'grid_480')
order by a.created_at desc;
```

In the application, group variants by `asset_id`.

Example HTML:

```html
<img
  src="GRID_480_PUBLIC_URL"
  srcset="THUMB_160_PUBLIC_URL 160w, GRID_480_PUBLIC_URL 480w"
  sizes="(max-width: 600px) 50vw, 240px"
  loading="lazy"
  decoding="async"
  width="240"
  height="240"
  alt="Project screenshot"
/>
```

---

## Frontend Grid Best Practices

| Practice | Why it matters |
|---|---|
| Lazy loading | Avoids loading offscreen images. |
| `srcset` and `sizes` | Lets the browser choose the right image size. |
| Fixed `width` and `height` | Prevents layout shift. |
| Virtualized grid | Keeps large image grids fast. |
| Pagination or infinite scroll | Avoids loading too many assets at once. |
| WebP with JPEG fallback | Reduces file size while preserving compatibility. |
| Blurhash or dominant color | Improves perceived loading speed. |

---

## Mobile App Feasibility

Local image generation is feasible on mobile.

| Platform | Feasibility | Notes |
|---|---:|---|
| Desktop browser | High | Best browser environment for canvas-based resizing. |
| Mobile browser | Medium to high | Feasible for one or a few images. Keep variants small. |
| PWA | Medium to high | Similar to mobile browser. |
| React Native | High | Use native image compression/manipulation libraries. |
| Expo | High | Use `expo-image-manipulator`. |
| Flutter | High | Use image compression packages or native platform channels. |
| Native iOS/Android | Very high | Best performance and orientation handling. |

Mobile guidance:

- Generate only 1 to 2 variants at first.
- Process one image at a time.
- Cap large images before upload.
- Test real phone camera images.
- Watch for HEIC and EXIF orientation issues.

---

## Handling Failures

Supabase Storage uploads and Postgres inserts are not a single atomic transaction. Design for partial failure.

Recommended state flow:

```text
uploading
  -> ready
  -> failed
```

Failure handling:

- Create the asset row before uploading files.
- Upload required variants.
- Insert variant metadata.
- Mark the asset `ready` only after all required variants exist.
- If a step fails, mark the asset `failed`.
- Optionally add a cleanup routine for failed uploads.

---

## Security and Access Control

### Public images

Use public bucket URLs when images are intended to be public.

### Private images

Use private buckets and signed URLs when images should only be visible to authorized users.

Recommended private flow:

```text
UI queries media metadata
  -> backend verifies access
  -> backend returns signed URLs for required variants
  -> frontend renders signed URLs
```

Do not expose service role keys in the browser or mobile app.

---

## Row Level Security Ideas

Enable RLS on metadata tables and restrict access by owner or workspace.

Example owner-based policy:

```sql
alter table media_assets enable row level security;
alter table media_asset_variants enable row level security;

create policy "Users can read their own media assets"
  on media_assets
  for select
  using (owner_id = auth.uid());

create policy "Users can insert their own media assets"
  on media_assets
  for insert
  with check (owner_id = auth.uid());

create policy "Users can read variants for their own assets"
  on media_asset_variants
  for select
  using (
    exists (
      select 1
      from media_assets a
      where a.id = media_asset_variants.asset_id
        and a.owner_id = auth.uid()
    )
  );
```

If using non-UUID external owner IDs, adapt `owner_id` accordingly.

---

## What to Defer Until Later

On the Free tier, defer:

- Supabase Image Transformations for routine grid thumbnails
- Many variant sizes
- Heavy Edge Function image processing
- Complex queue infrastructure
- External image CDN
- Full-resolution original retention for every image, unless required
- Large batch image processing on mobile web

---

## Upgrade Path

This design can evolve without changing the UI model.

### Phase 1: Free-tier simple version

```text
Client generates variants
Client uploads variants
Postgres stores metadata
Grid reads Postgres and serves Storage URLs
```

### Phase 2: Add repair jobs

```text
Client still generates variants
Failed or missing variants create thumbnail_jobs rows
Edge Function or server worker repairs failed assets
```

### Phase 3: Backend-generated variants

```text
Client uploads original
Postgres trigger or app code enqueues job
Worker generates variants
Postgres metadata is updated
```

### Phase 4: Higher-scale delivery

```text
Stored variants remain canonical
Image CDN or Supabase transformations handle uncommon sizes
Public assets use long cache headers and immutable URLs
```

---

## Final Recommendation

For Supabase Free-tier image storage and thumbnail grids:

1. Generate `thumb_160` and `grid_480` locally before upload.
2. Store generated variants in Supabase Storage.
3. Store asset and variant metadata in Postgres.
4. Render grids from Postgres records, not Storage listings.
5. Use lazy loading, `srcset`, fixed dimensions, and pagination or virtualization.
6. Use public buckets only for non-sensitive images.
7. Use private buckets and signed URLs for sensitive images.
8. Add a jobs table later for repair and backend regeneration.
9. Keep paths immutable and cache-friendly.
10. Defer paid transformations or external image CDNs until the product needs them.

This gives you a low-cost starting point that remains compatible with more advanced backend processing and image delivery later.
