# Action For Animals — iOS

An animal welfare advocacy app adapted from the [5Calls](https://5calls.org) iOS codebase. Users contact elected representatives and corporate targets about animal policy campaigns.

## Requirements

- Xcode 16
- iOS 16+
- Ruby (for Fastlane): `bundle install`

## Project Layout

```
ActionForAnimals/
├── ActionForAnimals/          # Main app target (Swift sources)
│   ├── App.swift              # App entry point, scene lifecycle
│   ├── AppState.swift         # All published state, UserDefaults persistence
│   ├── Store.swift            # Redux reducer + dispatch
│   ├── Actions.swift          # Exhaustive Action enum
│   ├── Middleware.swift        # Side-effects (network fetches, analytics)
│   └── Extensions/
├── ActionForAnimalsTests/     # Unit tests
├── ActionForAnimalsUITests/   # UI tests (Fastlane snapshot)
└── NotificationsService/      # Notification service extension
fastlane/                      # Fastlane lanes (test, beta, release)
vendor/rswift                  # R.swift binary
```

## Architecture

**Redux-style unidirectional data flow.**

| Layer | File | Role |
|---|---|---|
| State | `AppState.swift` | Single source of truth; `@Published` props auto-persist to `UserDefaults` via `didSet` |
| Actions | `Actions.swift` | Value-type enum; all intents go through here |
| Reducer | `Store.reduce(_:_:)` | Pure function — mutates state synchronously on main thread |
| Middleware | `Middleware.swift` | Network ops, analytics; dispatches result actions |
| Store | `Store.swift` | `ObservableObject`; `dispatch()` runs reducer then middleware |

Views receive `store` as an `@EnvironmentObject` and call `store.dispatch(action:)` for all mutations.

## Backend & Environments

All Cloud Run endpoints are **hardcoded in Swift** and point to the **production** Firebase project (`wv7gpk3bya`). The `GoogleService-Info.plist` controls which Firebase project is used for callable functions (`getOfficialsCallable` / contacts lookup) and Auth.

### Secure files (stored in `../secure-files/`, gitignored)

| File | Purpose |
|---|---|
| `apple/GoogleService-Info.plist.prod` | Firebase project `action-for-animals-da67c` — **production** |
| `apple/GoogleService-Info.plist.test` | Firebase project `action-for-animals-9151f` — test |
| `AuthKey_L4N74NW9TV.p8` | Apple Push Notification auth key (Fastlane deploys only) |
| `devicecheck/AuthKey_L5D63WV9DV.p8` | Apple DeviceCheck key for Firebase App Check (server-side only) |

**To point fully at production**, copy the prod plist into the project:
```bash
cp ../secure-files/apple/GoogleService-Info.plist.prod \
   ActionForAnimals/ActionForAnimals/GoogleService-Info.plist
```
The repo currently has the **test** plist checked in, so `getOfficialsCallable` hits test while all other endpoints hit prod.

### Cloud Run endpoints (all production, `wv7gpk3bya`)

| Endpoint | File | Purpose |
|---|---|---|
| `getissues-wv7gpk3bya-uc.a.run.app` | `FetchAnimalPolicyOperation.swift` | Fetch campaigns |
| `reportcall-wv7gpk3bya-uc.a.run.app` | `ReportOutcomeOperation.swift`, `FetchStatsOperation.swift` | Report outcomes / fetch stats |
| `saveuserinfo-wv7gpk3bya-uc.a.run.app` | `SaveUserInfoOperation.swift` | Save user profile |
| `joinmonthlyLeague-wv7gpk3bya-uc.a.run.app` | `LeagueOperations.swift` | Join monthly challenge |
| `getcurrentmonthleaderboard-wv7gpk3bya-uc.a.run.app` | `LeagueOperations.swift` | Live leaderboard |
| `getpreviousmonthleaderboard-wv7gpk3bya-uc.a.run.app` | `LeagueOperations.swift` | Prior month leaderboard |
| `getmonthlyLeagueResults-wv7gpk3bya-uc.a.run.app` | `GetMonthlyLeagueResultsOperation.swift` | Month transition data |
| `getOfficialsCallable` (Firebase callable) | `FetchContactsOperation.swift` | Reps lookup by location — uses plist project |

## Key Subsystems

### Campaigns (`AnimalPolicy`)
- Two `contactType` variants: `.representatives` (political) and `.corporate`
- Corporate campaigns have `targets: [Target]` and `actions: Actions` (call/email config)
- Batch email campaigns set `actions.email.distributionMethod = "batch"`
- `contactsForIssue(allContacts:)` sorts reps by area; corporate campaigns use `targets` directly

### Contact Resolution
- Political: `FetchContactsOperation` — location → reps list, cached 7 days in `UserDefaults`
- Corporate: contacts created from `Target` via `Contact(from:)`
- Cache keys: `cachedContacts` (JSON), `contactsFetchTime` (Date)

### Impact & Achievements (`ImpactManager`, `AchievementRegistry`)
- `ImpactManager` is an `@StateObject` injected at root; also stored as `ImpactManager.shared`
- `AchievementRegistry.allAchievements` defines badge definitions with `checkUnlocked` / `checkNewlyUnlocked` closures
- Thresholds in `AchievementThresholds` struct
- `AchievementCelebration` overlay shown from `App.swift` when `impactManager.showAchievementCelebration != nil`

### Monthly League
- Opt-in leaderboard tracked by `UserDefaultsKey.lastLeagueMonth` (format: `"YYYY-MM"`)
- Leaderboard cached in `AppState.cachedCurrentLeaderboard` / `cachedCurrentMeta`
- Month transition shown via `MonthTransitionView` sheet when month rolls over
- `GetMonthlyLeagueResultsOperation` fetches prior month results

### Notifications
- `NotificationsService` extension handles notification content modification
- `UNNotification+ScheduleReminders.swift` schedules local reminders
- Push: OneSignal (referenced in `AchievementRegistry`)

### Analytics
- `AnalyticsManager.shared.trackPageview(path:)` — called in each view's `onAppear`

## State Persistence Keys

All `UserDefaults` keys are defined in `UserDefaultsKey.swift` (enum of raw `String`). Notable ones:

| Key | Purpose |
|---|---|
| `locationType` / `locationValue` / `locationDisplay` | Cached user location |
| `issueCompletionCache` | `[String: Data]` — call logs keyed by issue ID |
| `cachedContacts` | JSON-encoded `[Contact]` |
| `contactsFetchTime` | `Date` — cache expiry check (7-day TTL) |
| `lastKnownIssues` | JSON-encoded `[AnimalPolicy]` — shown immediately on launch |
| `animalsHelpedThisMonth` | Monthly counter, reset on new month |
| `weeklyStreak` / `lastActionWeek` | Weekly streak tracking (`YYYY-ww` format) |
| `lastLeagueMonth` | Current league month membership |
| `selectedCategoryFilter` | Comma-separated category keys or `"all"` |
| `changedCampaignIds` | `[Int]` of recently-updated campaign IDs |

## Navigation

`AnimalPolicySplitView` is the root. Navigation state lives in `AppState.issueRouter` (`AnimalPolicyRouter`), a `NavigationPath`-backed router. Actions: `GoBack`, `GoToRoot`, `GoToNext(issue:contacts:actionType:)`.

Detail flow: issue list → `AnimalPolicyDetail` → `AnimalPolicyContactDetail` (per contact call/email) → `AnimalPolicyDone`.

## R.swift

Resources (images, strings, colors) are accessed via `R.*` — strongly typed, compiler-checked. The binary lives in `vendor/rswift`. Run the R.swift build phase in Xcode or add it fresh from [releases](https://github.com/mac-cain13/R.swift/releases) if missing.

Localized strings: `Localizable.strings` → `R.string.localizable.*`.

## CI / Deployment

- **CI**: CircleCI (`.circleci/config.yml`)
- **Fastlane lanes**:
  - `fastlane test` — runs unit tests via `scan`
  - `fastlane beta` — bumps build, archives, uploads to TestFlight
  - `fastlane release` — archives and submits to App Store
- `.env` required for beta/release: `APPLE_ID`, `TEAM_ID`, `ITUNES_CONNECT_TEAM_ID`, `FASTLANE_APPLE_APP_SPECIFIC_PASSWORD`
- Build number is bumped manually before running `fastlane beta`

## Common Patterns

**Adding a new Action**: add a case to `Actions.swift`, handle it in `Store.reduce`, and if it needs a network call, add a branch in `Middleware.swift`.

**Adding a campaign field**: update `AnimalPolicy` (add `CodingKey` if needed), update `Equatable` conformance at the bottom of `AnimalPolicy.swift`.

**Adding a UserDefaults key**: add a case to `UserDefaultsKey.swift` and wire `didSet` persistence in `AppState`.

**Cache invalidation**: contacts TTL is 7 days (`needsContactsRefresh`); issues TTL is 1 minute (`needsIssueRefresh`). Both are computed vars on `AppState`.
