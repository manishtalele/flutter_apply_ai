# Flutter Apply AI

A production-grade **Flutter Desktop (Windows)** application that automates job
applications: paste a job post → Gemini extracts structured data and drafts an
email → preview → attach your resume → send via the Gmail API → persist to
SQLite → track replies and measure your funnel.

## Features

- **Home** — paste a job description, run AI analysis, preview the extracted
  company/role/email/skills/experience, a generated subject + HTML email, a
  0–100 match score and an apply recommendation. Apply with one click.
- **Apply pipeline** — duplicate detection ("already applied — apply again?"),
  resume selection, multiple attachments, Gmail send, SQLite persistence.
- **History** — searchable, status-filterable list; detail view; open in
  Gmail; delete; CSV export.
- **Dashboard** — applied today/week/month, total, replies, interviews,
  selected, rejected, no-reply; one-click reply sync.
- **Settings** — Gemini API key (secure storage), candidate profile, multiple
  resumes with a default, Gmail connect/disconnect, theme.
- **Reply tracking** — reads Gmail threads and classifies replies with the AI
  to update application status.

## Architecture

Clean Architecture (Presentation → Domain ← Data) with MVVM via GetX. See
[`ARCHITECTURE.md`](ARCHITECTURE.md) for the full contract. Key invariant: the
Domain layer depends on nothing framework-specific (no Flutter/Dio/sqflite).

```
lib/
├── app/          GetMaterialApp, routes, initial binding
├── core/         constants, errors, network, theme, utils, DI, enums
├── domain/       entities, repository interfaces, use cases   (pure Dart)
├── data/         models (DTOs), datasources (local/remote), repository impls
└── presentation/ splash · shell · home · dashboard · history · settings · shared
```

## Tech stack

Flutter Desktop · GetX (state/DI/routing) · Dio · sqflite_common_ffi ·
Google Gemini 2.5 Flash · Gmail API · OAuth2 (PKCE, loopback) ·
flutter_secure_storage · SharedPreferences · dartz · logger.

## Prerequisites

- Flutter 3.41+ (Dart 3.11+)
- A **Gemini API key** — https://aistudio.google.com/app/apikey
  (entered in-app under Settings; stored in the OS credential store).
- A **Google OAuth Desktop client** with the Gmail API enabled —
  https://console.cloud.google.com/apis/credentials (OAuth client ID →
  *Desktop app*). Note the client ID and secret.

## Run

Provide the OAuth client credentials at launch via `--dart-define` (they are
never hardcoded in source):

```bash
flutter pub get

flutter run -d windows \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=YOUR_ID.apps.googleusercontent.com \
  --dart-define=GOOGLE_OAUTH_CLIENT_SECRET=YOUR_SECRET
```

(On this Linux dev machine, substitute `-d linux`.)

### Build a release

```bash
flutter build windows \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=... \
  --dart-define=GOOGLE_OAUTH_CLIENT_SECRET=...
```

## First-run setup

1. Open **Settings** → paste your **Gemini API key** → Save.
2. Fill your **profile summary** (skills/experience) — improves match scoring.
3. Add at least one **resume** and mark a default.
4. **Connect Gmail** and grant send + read scopes.
5. Go to **Home**, paste a job post, **Analyze**, then **Apply**.

The Home screen shows an onboarding banner listing any missing setup step.

## Quality gates

```bash
flutter analyze   # must be clean (hardened lints in analysis_options.yaml)
flutter test      # unit + integration + widget tests
```

## Testing

Coverage spans every layer: model (de)serialization, the SQLite DAO and full
repository stack against a real in-memory FFI database, the Gemini and Gmail
datasources (mocked Dio), MIME building, the apply/send and reply-sync use
cases, dashboard aggregation, and controller logic.
