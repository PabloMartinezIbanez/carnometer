# Supabase Setup

## Local workflow

1. Install the Supabase CLI.
2. Link or start a local project.
3. Apply all migrations in `supabase/migrations/`.
4. If your local stack was already running when a new migration was added, reset or update it before using the mobile app again:

```bash
supabase db reset
```

or:

```bash
supabase migration up
```

At the moment the mobile client expects both:

- `20260410_initial_schema.sql`
- `20260412_add_route_difficulty.sql`

If `route_templates.difficulty` is missing locally, route sync will fail with a PostgREST error about the missing `difficulty` column.
5. Deploy the `mapbox-routing` edge function and configure:

- `MAPBOX_SECRET_TOKEN`
- `MAPBOX_BASE_URL` (optional, defaults to `https://api.mapbox.com`)

## Expected client behaviour

- The mobile client authenticates anonymously.
- Route templates sync first.
- Completed sessions sync afterward with telemetry rows batched separately.
- Directions and map matching are requested only on demand while editing/preparing a route.
- If the edge function or Mapbox fails, the client keeps the raw geometry.
