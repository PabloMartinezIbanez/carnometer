# Repository Agent Instructions

These instructions apply to the entire repository.

## Skill Routing By Folder

- If a task modifies anything under `supabase/`, always use the `supabase` skill first.
- If a task modifies anything under `supabase/` and touches SQL, schema design, migrations, indexes, RLS, or Postgres performance, also use `supabase-postgres-best-practices`.
- If a task modifies anything under `flutter/` or `apps/mobile/`, always use the Flutter skill or skills that best match the task being performed.

## Cross-Area Changes

- If a task modifies both Supabase and Flutter areas in the same change, apply both families of skills.

## Notes

- These folder-based rules are mandatory for work in this repository.
- Do not skip the relevant skill just because the task looks small.
