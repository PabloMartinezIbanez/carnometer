# Carnometer

Carnometer is an Android-first proof of concept for timing car routes with custom sectors, local telemetry capture, and optional cloud sync.

## What is already in this repository

- `packages/carnometer_core`
  - Pure Dart domain models for routes, sectors, sessions, and telemetry.
  - A tested tracking engine that detects sectors and laps locally on-device.
- `apps/mobile`
  - Flutter app shell with route, session, and history tabs.
  - Local SQLite persistence for routes, sessions, and pending sync items.
  - Optional anonymous Supabase bootstrap and sync wiring.
  - Demo lap playback so the core timing flow can be exercised without driving.
- `supabase`
  - Initial Postgres/PostGIS schema.
  - Edge function scaffold for optional route snapping through GraphHopper.

## Repository layout

```text
apps/mobile              Flutter shell
packages/carnometer_core Pure Dart timing engine and models
supabase                 SQL schema and edge functions
docs                     Architecture notes
```

## Verified in this environment

The following commands were run successfully during this session:

```bash
cd packages/carnometer_core
../../.tooling/dart-sdk/dart-sdk/bin/dart test
../../.tooling/dart-sdk/dart-sdk/bin/dart analyze
```

Flutter was not available in the current environment, so the mobile shell was scaffolded manually and still needs the normal Flutter native project generation step before running.

## Next steps

1. Install Flutter locally.
2. Generate the Android shell inside `apps/mobile` if needed:

```bash
cd apps/mobile
flutter create . --platforms=android
flutter pub get
```

3. Run the app in local-only mode:

```bash
flutter run --dart-define=MAP_STYLE_URL=https://demotiles.maplibre.org/style.json
```

4. Wire Supabase and GraphHopper when ready:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=MAP_STYLE_URL=https://your-style-url/style.json \
  --dart-define=GRAPHHOPPER_BASE_URL=https://graphhopper.com/api/1
```
