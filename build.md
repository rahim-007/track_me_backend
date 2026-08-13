# 🛠️ BUILD.md — Track Me (Flutter + Supabase)

> **How to use this file:** Paste the entire contents below into your AI coding assistant (Freebuff / Claude / ChatGPT / Cursor) to build the **Track Me** Flutter app from scratch — completely on **Flutter + Supabase**, with **no custom backend**. The assistant should scaffold the Flutter project, set up Supabase (Auth, Postgres, Storage, Edge Functions), implement every feature described here, and validate with `flutter analyze` + a debug build.

---

## 🎯 Role & Goal

You are an expert Flutter + Supabase engineer. Build a polished, production-quality **AI-powered productivity app called "Track Me"** that combines **Habit Tracking, Goal Tracking, and Expense Management** into one beautiful offline-first mobile app.

**Hard constraints:**

- **Backend = Supabase only.** No custom Node/NestJS/Express server. Use Supabase Auth, Supabase Postgres (+ Row Level Security), Supabase Storage, and Supabase Edge Functions for anything requiring a secret (e.g., Gemini AI key).
- All user data lives in Supabase Postgres behind **RLS policies** that enforce `user_id = auth.uid()`.
- The app must work **offline-first**: read from a local cache instantly, sync to Supabase in the background, and never block the UI.
- Everything below is a **hard requirement**, not a suggestion.

---

## 🧱 Tech Stack

| Concern | Choice |
|---|---|
| Framework | Flutter (latest stable, Dart 3) |
| State management | Riverpod (`flutter_riverpod`, code-gen optional) |
| Navigation | `go_router` (splash → onboarding → auth → shell → feature routes) |
| Local database / offline cache | `isar` (v3) + `path_provider` for JSON file caches |
| Secure storage (tokens) | `flutter_secure_storage` |
| Auth | `supabase_flutter` (email/password + Google OAuth) + `google_sign_in` for native Google login |
| Charts | `fl_chart` |
| Images | `cached_network_image` |
| Notifications | `flutter_local_notifications` + `timezone` (local reminders); `firebase_messaging` optional for push |
| AI | Gemini via **Supabase Edge Function** (never embed the API key in the app) |
| Design | Material 3, custom theme with purple primary, light + dark mode |

**Structure (feature-first):**

```
lib/
  main.dart
  app/app.dart
  core/
    config/app_env.dart          # Supabase URL/anon key via --dart-define
    network/supabase_client.dart # shared Supabase client + token refresh
    local/isar_service.dart      # Isar bootstrap (skip on web)
    router/app_router.dart
    theme/app_colors.dart, app_theme.dart, theme_provider.dart
    notifications/notification_service.dart
    constants/app_constants.dart
    widgets/                     # app_button, app_card, app_text_field, shared_widgets
  features/
    splash/ onboarding/ auth/ dashboard/ habits/ goals/ expenses/ ai/ profile/
    # each feature: data/models, data/repositories (supabase), providers, presentation/
```

---

## 🎨 Design System

- **Primary color:** `#7C3AED` (violet). Accents: `#8B5CF6`, `#6D28D9` (gradients), success `#10B981`, warning `#F59E0B`, danger `#EF4444`, blue `#3B82F6`, orange `#F97316`.
- **Full dark mode:** every screen, card, button, sheet, dialog, chart, and text must switch instantly when dark mode toggles. Do NOT use a static palette that ignores theme — force a full rebuild on theme change (e.g., `key: ValueKey(isDarkMode)` on `MaterialApp`) so anything reading a static color re-evaluates.
- **Splash screen:** violet background, app icon in a frosted rounded square, "Track Me" title, "AI-Powered Productivity" subtitle, subtle scale+fade animation, then navigate.
- **Cards:** large radius (16–24), soft shadows (transparent in dark mode), consistent spacing (20px page padding).
- **Currency:** Indian Rupee (₹) formatting via `intl` (`NumberFormat('#,##0')`); keep it centralized so it's easy to change.
- App name: **Track Me**; icon: `track_changes`.

---

## 🔐 Auth (Supabase Auth)

1. **Email + password register/login.** Normalize emails to lowercase before storing. Show friendly validation errors (e.g., 8+ char password).
2. **Google login:** use `google_sign_in` on mobile to get the Google ID token, then `supabase.auth.signInWithIdToken(provider: google, idToken: …)`. On web use `signInWithOAuth`. Handle the "debug SHA-1 not registered" error with a clear message.
3. **Session persistence:**
   - Store the Supabase session (`access_token`, `refresh_token`, user id) in `flutter_secure_storage`.
   - On app launch, restore the session; if the access token is expired, do a **single-flight refresh** (one refresh shared by all concurrent callers) — never two parallel refreshes that race and invalidate the rotating refresh token.
   - **Never log the user out on transient network errors.** Only clear the session when the refresh is *definitively rejected* (HTTP 400/401). A flaky connection must not force re-login.
4. **Forgot password:** `supabase.auth.resetPasswordForEmail()` → the user gets a Supabase email with a reset link → a **reset-password screen** lets them set a new password (`updateUser(password:)`). Invalidating old sessions on reset is a bonus.
5. **Logout:** clear session locally + `signOut()`.

---

## 🗄️ Supabase Schema (Postgres)

All tables have `id uuid primary key default gen_random_uuid()`, `user_id uuid references auth.users(id) on delete cascade`, `created_at`, `updated_at` — and **RLS enabled with `using (user_id = auth.uid())` and `with check (user_id = auth.uid())`** on every row. Also create a trigger that sets `updated_at = now()`.

### `profiles`
| field | type |
|---|---|
| id (uuid, = auth.uid()) | pk |
| name | text |
| email | text |
| avatar_url | text null |
| created_at | timestamptz |

*(Hint: auto-create a profile row on signup via a trigger or in the app after sign-in.)*

### `habits`
| field | type |
|---|---|
| name | text |
| emoji | text |
| color_hex | text |
| category | text (Health/Fitness/Learning/Mindfulness/Productivity/Social/Finance/Other) |
| repeat_days | boolean[7] (Mon..Sun) |
| reminder_enabled | bool |
| reminder_time | text ("HH:mm") |
| total_completed | int default 0 |
| created_at | timestamptz |

### `habit_logs`
| field | type |
|---|---|
| habit_id | uuid → habits.id (cascade) |
| date | date |
| is_skipped | bool default false |
| unique(habit_id, date) | |

- `total_completed` increments **only** when a log is **newly created** and decrements on delete. Never recompute by counting all logs (double-count bug).

### `missed_habit_reasons`
| field | type |
|---|---|
| habit_id | uuid |
| date | date |
| reason | text (min 20 chars enforced in UI) |
| created_at | timestamptz |

### `goals`
| field | type |
|---|---|
| name | text |
| category | text (Personal/Career/Fitness/Education/Finance/Health/Relationships/Other) |
| target_date | date |
| progress | float default 0 (clamp 0..1) |
| status | text default 'in_progress' (in_progress/completed/archived/cancelled) |
| created_at | timestamptz |

### `goal_progress_history`
| field | type |
|---|---|
| goal_id | uuid → goals.id (cascade) |
| progress | float |
| recorded_at | timestamptz |

*(Every progress update appends a history row in the same transaction so charts/audits work.)*

### `budgets`
| field | type |
|---|---|
| monthly_income | numeric |
| monthly_budget | numeric |
| start_day | int (day of month the budget starts — e.g., user sets up on Aug 16 → start_day = 16) |
| daily_goal | numeric (derived: remaining budget ÷ remaining days in the month from start_day) |
| month | text "yyyy-MM" |
| unique(user_id, month) | |

### `transactions`
| field | type |
|---|---|
| type | text ('expense' or 'income') |
| amount | numeric (positive) |
| category | text (Food/Groceries/Transport/Shopping/Entertainment/Health/Bills/Rent/Income/Salary/Other…) |
| note | text null |
| date | date |
| created_at | timestamptz |

### `notifications` (optional in-app inbox)
| field | type |
|---|---|
| type | text (habit_reminder/weekly_report/motivation) |
| title | text |
| body | text |
| read | bool default false |
| created_at | timestamptz |

### Supabase Storage
- Bucket `avatars`, RLS: authenticated users can upload; read public.

### Supabase Edge Functions
1. **`ai-insights`** — takes user_id + (optional) date range, reads the user's habits/goals/expenses, calls **Gemini** with the `GEMINI_API_KEY` (server-side secret, `x-goog-api-key` header, 30s timeout, non-200 handled), returns JSON insights. Fall back to locally-computed insights if the call fails (never 500).
2. **`weekly-report`** — same pattern; generates a deterministic weekly report; if Gemini fails, return a locally-computed summary.

---

## 📱 Screens & Features (detailed behavior)

### 1. Splash
- 2s branded splash (violet). During it, restore session + warm the local cache.
- **Startup must never hang:** initialize services (Isar, Supabase session restore, notifications) **in the background with hard timeouts** (e.g., Isar 12s, Supabase 10s, notifications 8s). `runApp` must happen immediately; a stalled plugin must never leave the user staring at the native launch logo. Log `[startup]` markers so issues are diagnosable.

### 2. Onboarding
- 3–4 swipeable steps with illustration/emoji, e.g.: "Welcome" → "Build habits" → "Track goals" → "Control spending" → "Get started".
- On finish, save `isCompleted = true` (in Isar) so it never shows again.

### 3. Auth screens
- **Login:** email + password, "Forgot password?", "Continue with Google", link to register. Buttons show inline loading; errors surfaced cleanly.
- **Register:** name, email, password (min 8), Google option.
- **Forgot password:** email field → send reset → confirmation message.
- **Reset password:** new password + confirm (only reachable from the Supabase email link).

### 4. Main shell (bottom nav)
5 tabs: **Home (dashboard), Habits, Goals, Expenses, Profile**. Rounded-icon bottom bar with active pill highlight.

### 5. Dashboard
Loads in parallel: profile, today's habits, active goals, current budget + expense dashboard, and the "missed yesterday" check.

- **Header:** greeting ("Good Morning/Afternoon/Evening"), user name + 👋, today's date, notification bell, avatar (cached image w/ letter fallback).
- **Quote card:** gradient card with a motivational quote + refresh button that cycles quotes.
- **3 progress cards:** Habits Done (`completed/total` + % bar), Day Streak 🔥 (+ 7-day mini bar chart), Weekly Progress (7-day trend line). Streak calculations use **O(1) Set-based lookups**, not list scans.
- **Budget summary card:** TODAY'S SPENDING ₹, daily goal, SAVED/OVER LIMIT, "On Track 🟢 / Overspent 🔴" chip, progress bar, "Daily Limit" + "View Details ↗". Tap → expenses. If no budget set, show a "Set Up Expenses" card.
- **Today's Habits** (top 3 compact rows: color bar, emoji, name, category, skip + check actions) with **View All**.
- **Active Goals** (top 2: name, due date, progress bar, illustration) with **View All**.
- **Missed-habit reflection:** when yesterday had missed habits (and today's reflection hasn't been submitted — track `lastReflectionDate` in settings), show a **full-screen, non-dismissible** "Yesterday's Reflection" dialog (see Habits).

### 6. Habits
- **List + weekly grid** (rows = habits, columns = last 7 days; tap a cell to complete/undo; today column distinct).
- **Add/Edit habit dialog:** name, emoji picker (24 curated emojis), color picker (12 colors), category chips, weekday repeat toggles, reminder time + enable.
- **Complete/undo:** optimistic update (UI flips instantly), local cache persisted, then POST to Supabase (`habit_logs`); on failure keep the optimistic state and retry later. Server `total_completed` must match.
- **Skip with reason:** dialog with reason chips (Feeling Sick / Too Busy / Traveling / Forgot / No Motivation / Other) + optional note → `habit_logs` with `is_skipped=true`.
- **Streaks:** current streak = consecutive scheduled days (Mon–Sun from `repeat_days`) where **every scheduled habit was completed**; today incomplete doesn't break the streak yet; missed yesterday breaks it. Longest streak too. Shown on Habits + Profile.
- **Missed-habit reflection dialog (critical UX):** full-screen gradient header "Yesterday's Reflection", one card per missed habit with a reason text field (**min 20 chars, max 250**, live char counter + validity check), cannot dismiss via back/barrier, submit disabled until all valid, then a short "Reflection completed 🌱" screen before continuing. Submissions save to `missed_habit_reasons` and mark `lastReflectionDate` so it shows once per day.
- **Delete** with confirm.

### 7. Goals
- **List** of active goals (progress bar, due date, category illustration, status chip) + quotes.
- **Add/Edit dialog:** name, category chips, target date picker, optional starting progress.
- **Progress update:** slider/stepper updates `progress` (clamp 0–1), appends to `goal_progress_history`, status auto-flips to `completed` at 100%.
- **Archive/delete/cancel** actions.
- Counters: active goals, completed, total.

### 8. Expenses
- **Setup wizard (critical logic):** user enters **monthly income**, **monthly budget**, and picks the **start day** (default = today, e.g., Aug 16). The **daily goal = remaining budget ÷ remaining days** (Aug 16 → spread over Aug 16–31, not the full month). Preview shows per-day limit. Stored on the budget for the month.
- **Dashboard (expenses tab):** today's spending vs daily goal (on-track/overspent), month total, income, saved, remaining days; "Add" FAB.
- **Add transaction sheet:** type toggle (Expense / Income), amount, category grid (emoji + color per category), date picker, note. **Income adds to the income total; it must never be double-counted against a salary-derived budget.**
- **Transactions list ("All Transactions"):** grouped by date, type icons, amount, category, edit + delete; month filter.
- **Expense detail:** full record view + edit/delete.
- **Analytics:** period tabs **Weekly / Monthly / Yearly**:
  - Stat cards: Total Spent, Transactions, Daily Avg.
  - **Spending by Category** pie chart (top 6 + % labels) and a category breakdown list (emoji, label, amount, %, progress bar).
  - **Daily Spending** bar chart.
  - Period switching must not flash the whole screen (sticky loading: `skipLoadingOnRefresh` + `copyWithPrevious`).

### 9. AI Insights & Weekly Report
- **AI Insights screen:** button to generate insights → calls the `ai-insights` Edge Function → displays markdown-ish cards (streak advice, spending tips, goal nudges). Loading spinner on the button only; **fallback to local computed insights if the API fails** (show a small "offline insights" note).
- **Weekly report:** auto-generated per week (notification + in-app). Deterministic; same pattern of fallback.

### 10. Notifications (local)
- **Habit reminders:** at each habit's reminder time, `zonedSchedule` daily notification ("⏰ Time for your habit! Don't forget: <name>"). Enable/disable per habit; canceled when habit deleted.
- **Goal reminders:** optional due-date reminders.
- **Weekly report notification.**
- Handle Android 12+ exact-alarm permission and Android 13+ notification permission gracefully.

### 11. Profile & Settings
- User card: avatar (upload to Supabase Storage), name (edit inline).
- **Stats grid:** Current Streak, Longest Streak, Total Completed Habits, Total Habits, Active Goals, Goals Achieved — computed live from local data when available (no fake zeros).
- **Settings:** Dark/Light theme toggle (persisted, applies everywhere instantly), language (stub), notifications on/off.
- **Logout** (clears session securely).

---

## ⚡ Cross-cutting Behavior (non-negotiable)

1. **Offline-first everywhere:**
   - Habits, goals, and transactions are cached locally (Isar + JSON file cache).
   - Every mutation is **optimistic**: update state + cache immediately, then sync to Supabase; if it fails, keep the local change and **retry on next launch** (pending "temp_" items with `temp_<timestamp>` ids get synced when connectivity returns).
2. **Sticky loading — never blank the screen:** reloads must keep showing previous data while refreshing (`AsyncValue.copyWithPrevious` + `skipLoadingOnRefresh`). Only the very first load may show skeletons. Saving must update fields in place, never replace the whole screen with a white spinner.
3. **Dark mode applies to 100% of the UI** (see Design System).
4. **Session survives outages** (see Auth #3).
5. **Performance:**
   - Set-based (`Set<String>`) lookups for all streak/completion checks; never O(n²) list scans in build methods.
   - Streak scans capped (max 366 days) both client- and server-side.
   - Parallel `Future.wait` for independent dashboard fetches.
   - **Lean logging:** one compact line per API call (`[api] GET /habits → 200 (95ms)`); never print full request/response JSON bodies in debug.
   - `const` widgets, `RepaintBoundary` where cheap; avoid rebuilding whole lists.
6. **Validation & security:**
   - All writes to Supabase rely on RLS (user-scoped) — never trust client claims for identity.
   - Trim/validate input lengths (name ≤ 50, note ≤ 250, reason 20–250).
   - Amounts positive; progress clamped 0–1.
7. **First-frame resilience:** `runApp` immediately; heavy init (Isar, Supabase, notifications) runs in background with timeouts and logs. An unreachable network must fail fast (10s connect timeout) and show an in-app error, never a hang.
8. **Loading UX:** first loads use shimmer skeletons; actions use button-level spinners; errors show snackbars with retry.

---

## ✅ Acceptance Criteria (verify before delivering)

- [ ] `flutter analyze` → **0 errors**; debug APK builds (`flutter build apk --debug`).
- [ ] Cold start gets past the splash into the app even if Supabase/network is down.
- [ ] Register/login/Google login/password-reset all work against Supabase Auth; reopening the app **stays logged in**; killing the connection during refresh does not log the user out.
- [ ] Create a habit → persists (survives restart), appears on dashboard, completes/skips/undo work instantly and sync.
- [ ] Streak counts match manual calculation; missed-habit reflection appears once per day and requires 20+ chars.
- [ ] Create a goal → progress updates clamp 0–1, completes at 100%, persists.
- [ ] Expense setup from Aug 16 → daily goal = budget ÷ days(16–31); adding income updates income (no double count); transactions, analytics (weekly/monthly/yearly) and charts render.
- [ ] Toggling dark mode changes **every** surface instantly and persists.
- [ ] Saving/adding anything never flashes a full-screen white loading state.
- [ ] All data is user-scoped (RLS) — a second account cannot see the first account's data.
- [ ] AI insights screen returns insights or a graceful offline fallback (never an error screen).

---

## 🚀 Build & Run

```bash
# 1. Create Flutter project (if not using the existing one)
flutter create track_me

# 2. Supabase setup
supabase init
supabase link --project-ref <your-project-ref>
supabase db push          # apply schema (RLS policies included)
supabase functions deploy ai-insights weekly-report
supabase storage create avatars

# 3. Auth config (Supabase dashboard)
#    - Enable Email + Google providers
#    - Add your Google OAuth Client IDs (Android SHA-1, iOS, Web)

# 4. Run
flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon-key>
flutter build apk --release --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Config lives in `lib/core/config/app_env.dart` via `String.fromEnvironment(...)`. Keep keys out of the binary for production (use secrets/Edge Functions for anything sensitive).
