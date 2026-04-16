# AGENT.md

Operating guide for AI coding agents working in this repository. Read this
first — it captures conventions, layering rules, and the design-source-of-
truth that the rest of the codebase assumes you already know.

---

## 1. What this app is

**`gh_todos`** is a Flutter client that re-frames **GitHub Projects V2** as a
personal todo list. The user pastes a GitHub Personal Access Token (PAT), the
app queries the GitHub GraphQL API, and the project's issues are rendered as
a priority-aware, due-date-aware feed.

Think of it as a premium, editorial "daily driver" on top of the raw GitHub
issue tracker — not a full project management tool.

### Use case & primary flows

- **Connect** — user pastes a PAT on the `ConnectPage`; token is trimmed and
  written to platform-secure storage (Keychain / Keystore).
- **Pick a project** — from any org or the viewer's personal projects, the
  user adds one or more Projects V2 projects in Settings. One is "selected"
  at a time via the chip row on the Root page.
- **Browse issues** — the Root page shows `open` + `recentlyClosed` issues
  for the selected project, each tagged with a local **priority** (urgent →
  trivial) and optional **due date** if the project has the corresponding
  fields mapped.
- **Quick-add** — an inline composer creates new issues in the project's
  linked repository and auto-adds them as project items.
- **Triage** — swipe to close/reopen; tap to open the detail page for
  comments, edits, and priority/due-date changes.
- **Optimistic updates** — mutations (state, priority, comments, etc.) are
  reflected in the UI immediately and reconciled when the mutation returns.

### Platform targets

Flutter multi-platform: **iOS, Android, macOS, Windows, Linux, Web**. The
shell is fully responsive — see §6.

---

## 2. Tech stack

| Concern          | Choice                                                      |
| ---------------- | ----------------------------------------------------------- |
| Language         | Dart, SDK `^3.11.4`                                         |
| UI framework     | Flutter (Material 3 base, styled via Mix)                   |
| Design system    | [`mix`](https://pub.dev/packages/mix) v2 tokens + variants  |
| State            | `flutter_riverpod` v3 + `riverpod_annotation` (codegen)     |
| Routing          | `go_router` v17 with `StatefulShellRoute.indexedStack`      |
| API              | GitHub GraphQL v4 via `graphql` + `graphql_codegen`         |
| Models           | `freezed` + `json_serializable`                             |
| Secure storage   | `flutter_secure_storage` (PAT only)                         |
| Local prefs      | `shared_preferences` (selected project, project list cache) |
| Typography       | `google_fonts` — Manrope (display) + Inter (body)           |
| Icons            | `lucide_icons_flutter`                                      |
| Relative time    | `timeago`                                                   |
| Swipe gestures   | `flutter_slidable`                                          |
| External links   | `url_launcher`                                              |

---

## 3. Directory layout

```
lib/
  main.dart                 # bootstraps ProviderScope + GhTodosApp
  app.dart                  # MaterialApp.router + MixScope (octanePrime)
  router/                   # go_router setup + route name/path constants
  pages/                    # top-level routed screens (thin — delegate to compositions)
  compositions/             # page-specific widget groups (not globally reusable)
    shell/                  # AppShell, top bar, bottom nav, nav rail, split view
    todos/                  # feed, project chips, issue card, composer, swipe row
    issue_detail/           # detail-page sections, sheets, composers
    settings/               # settings sections + sheets (add/edit project, PAT)
    setup/                  # ConnectPage pieces (brand block, token form, …)
    shared/                 # cross-cutting helpers (e.g. editorial text link)
  components/               # design-system primitives — globally reusable
    editorial_*.dart        # EditorialButton, Card, Chip, TextField, Switch, …
    status_blip.dart
    src/
      component_foundation.dart  # shared Mix helpers
      adaptive_sheet.dart        # modal that adapts to width
  providers/                # Riverpod providers (paired .g.dart files)
  services/                 # thin wrappers over secure storage + shared_preferences
  models/                   # freezed domain types (Project, IssueData, …)
  graphql/                  # .graphql operation files + generated .graphql.dart
  style/
    breakpoints.dart        # kCompactMax / kMediumMax / kExpandedMax
    colors.dart             # ColorTokens (nested token classes)
    typography.dart         # TextTokens
    themes.dart             # octanePrime — the MixScope factory
  util/                     # misc helpers

design/                     # Stitch design source (see §5)
test/                       # widget + service + router tests
assets/fonts, assets/icon.png
```

### Layering rules (strict)

- `pages/` ⟶ `compositions/` ⟶ `components/`. A page never hand-rolls widgets
  that belong in a composition; a composition never re-implements primitives
  that exist in `components/`.
- `components/` must **not** import `compositions/` or `pages/` or feature-
  specific providers. They depend only on `style/` and `components/src/`.
- `compositions/` may import `components/`, `providers/`, `models/`,
  `graphql/`, `style/` — but not other feature compositions cross-folder
  (keep feature folders self-contained; put anything shared in
  `compositions/shared/`).
- `providers/` own all state and GraphQL calls. Pages/compositions read via
  `ref.watch` / `ref.read` and never build their own `GraphQLClient`.
- Generated files live next to their source: `foo.dart` + `foo.g.dart` +
  `foo.freezed.dart`, `foo.graphql` + `foo.graphql.dart`. Never hand-edit
  `.g.dart` / `.freezed.dart` / `.graphql.dart`.

---

## 4. Data & GraphQL

- **Auth.** PAT is stored by `GithubTokenStorageService` in
  [`flutter_secure_storage`](lib/services/github_token_storage_service.dart).
  Never log, echo, or write it elsewhere.
- **Client.** `graphqlClientProvider` constructs a `GraphQLClient` with an
  `AuthLink` that injects `Bearer <token>` and points at
  `https://api.github.com/graphql`.
- **Operations.** Every query/mutation lives in `lib/graphql/*.graphql`.
  `graphql_codegen` emits typed helpers in the paired `.graphql.dart`. The
  authoritative schema is `lib/graphql/schema.graphql` — regenerate after
  any edit (see §7).
- **Models.** Domain types (`IssueData`, `Project`, `IssueDetails`, …) are
  `@freezed` with `json_serializable`. They sit between the raw GraphQL
  response and the UI — the UI should import models, not `graphql/`.
- **Priority mapping.** `TodoPriority` (urgent/high/medium/low/trivial) is a
  local 5-level enum. A project can map a GitHub single-select field onto
  these via `Project.priorityFieldId` + `priorityOptionMap`. Due dates map
  onto a date field via `Project.dueDateFieldId`. Options not in the map are
  treated as "unset" — fail gracefully, don't crash.
- **Two distinct ids.** `IssueData.id` is the issue node id; `projectItemId`
  is the Projects V2 item id. **Priority/due-date mutations target the item
  id**, state/comment mutations target the issue id. Don't mix them up.

---

## 5. Design source of truth — Stitch exports

The design was produced in **Stitch** and exported as paired HTML + PNG
files under `design/`. These are not decorative — **they are the visual
contract** for every screen. Consult them before touching UI.

```
design/
  mobile/
    DESIGN.md          ← design system spec (read first, every time)
    main.html / .png           — Root / issues feed
    detail.html / .png         — Issue detail page
    settings.html / .png       — Settings (projects, PAT, account)
    connect.html / .png        — PAT connect / onboarding
    prio.html / .png           — Priority semantics + color scale
    components.html / .png     — Design-system component gallery
  desktop/
    main.html / .png           — wide Root with split view + nav rail
    detail.html / .png         — wide issue detail
    settings.html / .png       — wide settings
```

### How to use the design files

1. **Read `design/mobile/DESIGN.md` first.** It codifies the "Engineering
   Editorial" aesthetic — surface hierarchy, no-line rule, glass & gradient
   rule, typography dual-face (Manrope + Inter), component specs. Most
   subjective styling questions are answered there.
2. **Open the corresponding HTML file** for the screen you're working on
   (e.g. editing the issue detail page → open `design/mobile/detail.html`
   and `design/desktop/detail.html`). HTML is the highest-fidelity source —
   pull spacing, colors, and structure from it, not from the PNG.
3. **Use the PNG as a quick visual check**, especially when reviewing a
   diff without a running app.
4. **Map tokens, don't transliterate styles.** If the HTML hard-codes
   `#0051AE`, find the matching Mix token (`ColorTokens.primary.$default`
   in this case — see `lib/style/themes.dart`) and use the token. Same for
   font sizes — use `TextTokens.*`. New tokens go through
   `lib/style/themes.dart`.
5. **Honor the "No-Line" rule.** Never reach for `Border`/`Divider` to
   separate sections. Use surface tokens
   (`surface` / `surface_container_low` / `surface_container_lowest` / …)
   and whitespace. `outline_variant` at 15% opacity is the only
   accessibility fallback.
6. **Priority colors** live in `ColorTokens.priority.*` and match
   `design/mobile/prio.html §07 Semantics`. Never hard-code a priority
   color in a widget.

### When the design and the code disagree

- Design file is newer (recent edit, mentioned in a PR): treat the design
  as correct and update the code.
- Code is newer (design wasn't re-exported): flag it in the response and
  ask the user which is canonical before changing either.
- Never silently drift from the design. If you're introducing something
  not covered by the design files (a new screen, a new state), say so
  explicitly in your plan.

---

## 6. Responsive shell

Width thresholds live in [lib/style/breakpoints.dart](lib/style/breakpoints.dart):

```
compact   < 600    phone portrait / landscape
medium    600–899  iPad portrait, foldables, phone landscape
expanded  900–1279 iPad landscape, small desktop windows
large    ≥ 1280    desktop full-screen
```

**The single hinge is `isWide(context)` (≥ 900).** Above it, the shell
switches from bottom-tab + push navigation to **side rail + split view**
(issues list on the left, detail on the right via `TodosSplitView`).
`ConnectPage` additionally decorates itself with a side panel at `large`.

When adding layout, prefer Mix variants (`.onTablet()`, `.onDesktop()` —
remapped to these tiers via `appBreakpoints`) over imperative branches.
Reach for `isCompact/isMedium/isExpanded/isLarge/isWide` only when a Mix
variant isn't expressive enough.

---

## 7. Build, test, run

All commands run from the repo root.

```bash
# Install deps
flutter pub get

# Regenerate freezed / riverpod / json / graphql_codegen outputs
make build_runner
# (equivalent to: dart run build_runner build --delete-conflicting-outputs)

# Static analysis + tests (run both before finishing a change)
flutter analyze
flutter test

# Launcher icons (rarely needed)
make launcher_icons
```

**Run `make build_runner` after any change to:**

- `*.graphql` files (queries/mutations)
- `@freezed` / `@JsonSerializable` models
- `@riverpod` providers

If you edit a generated file by hand, you're doing it wrong — edit the
source and rerun the codegen.

---

## 8. Conventions you're expected to follow

- **State** — use Riverpod. New async data = new provider; don't add
  `StatefulWidget` fields for things a provider should own. Use `keepAlive`
  for long-lived singletons (client, session), `autoDispose` for view-
  scoped queries.
- **Styling** — use Mix tokens via `octanePrime`. Never hard-code colors,
  font sizes, or spacing that have a token. Define new tokens centrally
  (`lib/style/`) before using them.
- **Typography** — `display`/`headline`/`title` → Manrope, `body`/`label`
  → Inter. Numbers and metrics go in Manrope for the premium feel.
- **Icons** — `lucide_icons_flutter` only. Don't mix icon libraries.
- **Navigation** — go through `AppRoutes` name/path constants; never
  hard-code strings. Use `context.goNamed` / `context.pushNamed`.
- **Testing** — widget tests live in `test/pages/` and `test/router/`.
  Fakes live in `test/support/`. New pages get a smoke test that
  exercises the main interaction.
- **Copy** — user-facing strings stay in code (no i18n layer yet); use
  plain strings, no ad-hoc constants files.
- **Do not introduce** — new state-management packages, new HTTP clients,
  new design-system abstractions, or Material widgets that bypass Mix
  tokens (use the `editorial_*` primitives instead).

---

## 9. Security & data handling

- The PAT is the only secret in this app. It is read once per mutation
  through `sessionProvider.readToken()` and flows only into the
  `Authorization` header. Never:
  - log it,
  - print it in errors,
  - persist it outside `flutter_secure_storage`,
  - pass it as a URL parameter,
  - put it in a widget tree or route `extra`.
- Token form should always be obscured. On clear/logout, call
  `sessionProvider.clearToken()` — it already nukes the keychain entry.

---

## 10. Quick-reference — where to start for common tasks

| Task                                | Start here                                                                          |
| ----------------------------------- | ----------------------------------------------------------------------------------- |
| New screen                          | `design/{mobile,desktop}/<name>.{html,png}` → `pages/` + `compositions/<feature>/` |
| New GraphQL query                   | Add `lib/graphql/<name>.graphql` → `make build_runner` → wrap in a provider         |
| New reusable widget                 | `lib/components/editorial_*.dart`; keep it provider-free                            |
| Restyle an existing widget          | Check `design/mobile/DESIGN.md` + the relevant HTML; update Mix style, not inline   |
| New priority color / surface tone   | `lib/style/themes.dart` (tokens) + `lib/style/colors.dart` (token declarations)     |
| Change responsive breakpoint        | `lib/style/breakpoints.dart` — update both `kXxxMax` and `appBreakpoints`           |
| Mutation with optimistic UI         | `lib/providers/issue_mutations.dart` is the pattern to copy                         |
| Wire an external link               | `url_launcher` + the existing footer composition                                    |

---

## 11. Things to ask the user before doing

- Adding a new top-level dependency to `pubspec.yaml`.
- Changing the design system spec (`design/mobile/DESIGN.md`) or
  introducing a token/variant that doesn't exist in it.
- Storing anything new in secure storage or shared_preferences.
- Introducing a new route — confirm it's intended to be deep-linkable.
- Touching the GraphQL schema file (`lib/graphql/schema.graphql`) — this
  is mirrored from GitHub; changes here are almost always wrong.
