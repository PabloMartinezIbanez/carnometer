# Supabase Setup

## Local workflow

1. Install the Supabase CLI.
2. Link or start a local project.
3. Apply the migration in `migrations/20260410_initial_schema.sql`.
4. Deploy the `snap-route` edge function and configure:

- `GRAPHHOPPER_API_KEY`
- `GRAPHHOPPER_BASE_URL` (optional, defaults to `https://graphhopper.com/api/1`)

## Expected client behaviour

- The mobile client authenticates anonymously.
- Route templates sync first.
- Completed sessions sync afterward with telemetry rows batched separately.
- If the edge function or GraphHopper fails, the client keeps the raw geometry.
