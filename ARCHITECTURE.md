# Flutter Apply AI — Architecture

Production desktop (Windows) application that automates job applications:
paste a job post → Gemini extracts structured data → preview → generate subject/body
→ attach resume → send via Gmail API → persist to SQLite → track replies.

## Architectural Style

**Clean Architecture (3 layers)** for macro structure + **MVVM via GetX** for presentation.

```
Presentation  →  Domain  ←  Data
 (GetX MVVM)     (pure Dart)  (SQLite / Gemini / Gmail)
        \          |          /
              Core (cross-cutting)
```

### The Dependency Rule
Dependencies point **inward only**. Domain depends on nothing external
(no Flutter, no Dio, no sqflite). Data implements Domain interfaces.
Presentation depends on Domain (and Core), never on Data concretely.

## Layers

### Presentation (`lib/presentation`, `lib/app`)
- **Views**: stateless `GetView<Controller>` widgets.
- **Controllers**: GetX `GetxController` = the ViewModel. Reactive `Rx` state,
  no business rules (they delegate to UseCases).
- **Bindings**: per-route DI (`Get.lazyPut`).
- **Widgets**: reusable Material 3 components.
- **Routes**: named routes via `GetPage`.

### Domain (`lib/domain`) — PURE DART
- **Entities**: `JobPosting`, `Application`, `ResumeProfile`, `AppSettings`.
- **Repository interfaces**: `AiRepository`, `GmailRepository`,
  `ApplicationRepository`, `SettingsRepository`, `ResumeRepository`.
- **UseCases**: one class per business action (`AnalyzeJobUseCase`,
  `SendApplicationUseCase`, `CheckDuplicateUseCase`, dashboard aggregates…).
- **Failures**: typed `Failure` hierarchy.
- **Enums/Value Objects**: `ApplicationStatus`, `MatchScore`, `ReplyOutcome`.

### Data (`lib/data`) — implements Domain contracts
- **Models (DTOs)**: JSON/SQLite serialization; map to/from Entities.
- **DataSources**:
  - Local: `AppDatabase` (sqflite_common_ffi), `SecurePrefsDataSource`.
  - Remote: `GeminiRemoteDataSource` (Dio, structured JSON), `GmailRemoteDataSource` (Dio + OAuth2 PKCE).
- **RepositoryImpls**: catch typed exceptions, map to `Failure`, return `Either`.

### Core (`lib/core`) — cross-cutting, no domain logic
- Constants (strings, keys, table names, API paths, prompt templates).
- Errors (`Failure`, `Exception` hierarchies).
- Network (Dio factory, interceptors, timeouts).
- DI bootstrap. Utils. `AppLogger`. Theme tokens.

## Contracts / Conventions

- **Error handling**: `Either<Failure, T>` (dartz) across every layer boundary.
  DataSources throw typed exceptions; RepositoryImpls map to `Failure`.
- **State**: `Rx<ViewState>` (initial/loading/success/error) + typed `Rx` fields; `Obx` in views. No `setState`.
- **Logging**: single `AppLogger` (wraps `logger`). No `print`.
- **Strings**: none hardcoded — all in `core/constants`.
- **Secrets**: Gemini key + Gmail OAuth tokens in `flutter_secure_storage`
  (Windows Credential Manager). SharedPreferences only for non-secret prefs.
- **OAuth2**: desktop installed-app loopback flow (RFC 8252) with **PKCE**.

## Request Flow

```
HomeView.paste → HomeController.analyze()
  → AnalyzeJobUseCase → AiRepository.extractJobPosting()
    → GeminiRemoteDataSource (Dio, JSON mode) → JobPosting entity
User taps Apply → SendApplicationUseCase
  → CheckDuplicateUseCase → ApplicationRepository.findByEmail() (SQLite)
  → GmailRepository.sendEmail(draft + attachment) (Gmail API)
  → ApplicationRepository.save(Application) (SQLite)
```

## Tech Stack

Flutter Desktop (Windows) · GetX (state/DI/routing) · Dio · sqflite_common_ffi ·
Google Gemini 2.5 Flash · Gmail API · OAuth2 (PKCE) · flutter_secure_storage ·
SharedPreferences · dartz · logger.

## Build Order (module-by-module)

1 Architecture · 2 Folder Structure · 3 pubspec · 4 Main · 5 Theme · 6 Models ·
7 Database · 8 Repository · 9 AI Service · 10 Gmail Service · 11 Home · 12 Settings ·
13 History · 14 Apply Logic · 15 SQLite · 16 OAuth · 17 Email Sending ·
18 AI Integration · 19 Dashboard · 20 Final Polish.
