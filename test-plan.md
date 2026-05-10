# SAMs UI Redesign — Test Plan

## What changed (user-visible)
- Color palette swapped from a generic primary-blue/orange + rainbow gradient cards to **ink navy + brass** (dark) / **warm paper + ink** (light).
- Headlines now use the **Fraunces serif** with editorial tracked-uppercase labels — replacing AI-generic SaaS sans + emoji greetings.
- Splash screen: **subtle radial vignette** instead of 3-stop rainbow gradient.
- Login & Register: **editorial composition** with "UMPSA · SAMs" lockup, tracked field labels, hairline divider, brass underline on links.
- Dashboard: **no rainbow gradient featured cards**; replaced with numbered module rows (`01 Tuition Fees`, `02 Class Attendance`, …). Quick-links grid is monochrome (single tonal palette) instead of 12 candy-colored circles. Fee summary uses **serif numerals on a calm surface** with no gradient. Greeting hero is a serif "Good X, Name." (no emoji).
- All routes/providers/services/models preserved.

## Adversarial principle
Every assertion below targets a specific element of the *new* design. If the redesign were broken or the old build were running, the assertion would visibly fail — e.g., presence of any rainbow gradient, any pastel circle, the `👋` emoji, a sans-serif "Welcome back" heading, or the old icon-tile lockup would all be failures.

## Test 1 — Splash + Login screen redesign
**Path:** `http://localhost:8765` (Flutter web build)

**Steps:**
1. Open the URL. Wait for splash to dismiss (~2.4s).
2. Once Login screen renders, observe.

**Pass/fail criteria:**
- ❌ FAIL if the splash shows a 3-stop blue→teal rainbow gradient. ✅ PASS if it shows a near-solid ink-navy with a soft brass radial glow and the serif "SAMs" wordmark.
- ❌ FAIL if Login shows a teal/blue gradient icon tile + "Welcome back" sans heading + "Sign in to your SAMs account". ✅ PASS if Login shows:
  - "UMPSA · SAMs" small tracked-caps lockup with a brass rule
  - Serif "Welcome" headline (Fraunces)
  - Two-line subhead: "Sign in to continue your\nacademic journey."
  - Tracked-caps field labels: "EMAIL", "PASSWORD"
  - Brass-colored "Sign In" button (in dark mode)
  - Hairline divider with brass dot
  - "New to SAMs? Create an account" with brass underline

## Test 2 — Register screen redesign
**Path:** Click "Create an account" from Login.

**Pass/fail criteria:**
- ❌ FAIL if the AppBar/title shows the old plain "Create Account" + plain "Join SAMs" sans heading.
- ✅ PASS if Register shows:
  - Tracked "NEW STUDENT" caps label with brass rule
  - Serif "Join SAMs" heading
  - Tracked-caps field labels: "STUDENT ID", "FULL NAME", "EMAIL", "PASSWORD", "FACULTY", "PROGRAM"
  - "Create account" button (sentence case, not "Create Account")

## Test 3 — Dashboard redesign (after auth)
**Path:** Register a fresh account against live backend → land on dashboard. (If backend register fails, fall back to localStorage seed.)

**Pass/fail criteria:**
- ❌ FAIL if the dashboard shows ANY of:
  - The old 3-color blue→teal gradient header strip
  - A horizontal scroller with **multiple different gradient cards** (purple/teal/pink/yellow)
  - 12 different pastel circle icons in a quick-links grid
  - "Good Morning, X 👋" with emoji
  - A solid-gradient tuition-fees banner with a sans-serif numeral
- ✅ PASS if the dashboard shows:
  - "UMPSA · SAMs" tracked-caps lockup at top
  - Serif greeting hero: "Good morning,\n[Name]." with a date subtitle in tracked caps
  - Section labels in tracked caps with brass rule: "MODULES", "QUICK ACCESS", "ANNOUNCEMENTS", "FACILITIES"
  - 4 numbered module rows: `01 Tuition Fees`, `02 Class Attendance`, `03 Curriculum Activity`, `04 Open Registration` separated by hairlines
  - Tuition fee card showing serif "RM" + serif numeral in same brass/ink palette
  - Quick-access grid: all icons monochrome on the same surface color (no rainbow pastels)
  - Footer: "UMPSA · 2026" tracked-caps mark

## Test 4 — Theme toggle (light mode)
**Path:** From dashboard, tap profile avatar (top right) → tap "Light mode".

**Pass/fail criteria:**
- ❌ FAIL if light mode renders with the old `#F5F7FA` cool-grey + Material-blue palette.
- ✅ PASS if light mode renders with **warm paper** background (`#F5EFE3`), **ink** primary buttons, and **brass** (`#B28A3E`) accent on rules/links.

## Out of scope
- Module screens (Fees / Attendance / Curriculum / Registration) inherit the new theme but were not individually redesigned this pass.
- Backend behavior — purely visual PR.
