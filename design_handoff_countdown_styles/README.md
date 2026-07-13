# Handoff: Countdown — Three Visual Styles + Unified Settings

## Overview
Redesign of the Countdown iOS app (repo: `hanakimis/Countdown`). The app keeps its core concept — rings of ticks counting down toward a target date — but ships **three switchable visual styles** (Ledger, Editorial, T-Minus), a **unified settings sheet** (style + date + animation in one place, replacing the separate gear menu and bottom date picker), and a single canonical **launch-volley refill animation** that plays whenever a ring rolls over.

Target codebase: the existing UIKit app. Key existing files to build on:
- `Countdown/TickDialView.swift` — vector tick dial (keep; extend)
- `Countdown/DaysRingsView.swift` — day-medallion grid (replaced by dot ledger in these styles)
- `Countdown/CountdownViewController.swift` — main screen (restructure per style)
- `Countdown/StyleSettingsViewController.swift` — replace with the unified sheet described below

## About the Design Files
The files in this bundle are **design references created in HTML** — live prototypes showing intended look and behavior, not production code to copy. The task is to **recreate these designs in the existing UIKit codebase** using its established patterns (Core Graphics drawing in `TickDialView`, `UserDefaults` persistence, `CADisplayLink` animation). Open `Countdown Redesigns.dc.html` in a browser; the handoff row (badges 7a–7e, top of the page) is the shipping spec. Earlier rows are exploration history.

## Fidelity
**High-fidelity.** Colors, typography, spacing and animation timing below are final. Recreate pixel-perfectly at iPhone point sizes (designs are drawn at 402×874 pt, iPhone 16/17 Pro class).

## Architecture: one screen, three styles
A single countdown screen renders in one of three styles. The style is an enum persisted in `UserDefaults` under key `visualStyle`:

```swift
enum VisualStyle: String { case ledger, editorial, tminus }
```

All styles share: the same date model (existing `Calendar.dateComponents`), the same tick geometry, and the same refill animation. Only palette, layout and typography differ.

## Screens / Views

### Style 1 · Ledger (reference: 7a)
Dark screen, unit rows with mini dials, serif numerals, dot-per-day ledger.
- **Background** `#212836`
- **Header row** (32 pt side margins, ~56 pt below status bar): date label `SEP 15, 2026` — SF 12 pt semibold, tracking 2.5, uppercase, `rgba(255,255,255,0.45)`; gear glyph right-aligned, same color, 19 pt. Tapping either opens the settings sheet.
- **Unit rows** (36 pt below header, 16 pt gaps, hairline separators `rgba(255,255,255,0.08)` under rows 1–2, 14 pt padding-bottom):
  - Order: **seconds, minutes, hours** (most volatile first).
  - Each row: 56 pt mini tick dial + numeral + unit label, 18 pt gaps.
  - Mini dial: single ring, 60 ticks (24 for hours), tick width 1.3 pt (1.6 pt hours), same fill/track/accent colors as the big dials.
  - Numeral: **Georgia / New York serif**, 32 pt, white, tabular figures, min-width 56 pt.
  - Unit label ("seconds" / "minutes" / "hours"): SF 13 pt, `rgba(255,255,255,0.4)`.
- **Days block** (40 pt below rows): serif 72 pt white `64`, tracking −2; below it italic serif 18 pt `days remaining` in `rgba(255,255,255,0.5)`, 6 pt gap.
- **Dot ledger** (pinned 56 pt above bottom, 32 pt margins): caption `ONE DOT PER DAY` — SF 11 pt, tracking 1.5, uppercase, `rgba(255,255,255,0.35)`, 12 pt below it the grid: one dot per remaining day, 16 columns, 19 pt cell, dot radius 0.22 × cell. Day 0 (today): filled accent `#BFE8FB`; the rest: 1.1 pt stroked circles `rgba(255,255,255,0.28)`.

### Style 2 · Editorial (reference: 7b)
Light paper screen, one concentric dial, serif center numeral, dot ledger.
- **Background** `#F5F2EC`; ink `#1E1D1B`; accent `#4C6CA8`.
- **Header row**: same layout as Ledger; date label `rgba(30,29,27,0.5)`, gear `rgba(30,29,27,0.4)`.
- **Concentric dial** (centered, 56 pt below header): 252 pt. Three nested tick rings, outer→inner = seconds (60), minutes (60), hours (24). Band height 0.08 × size, gap 0.032 × size, outermost radius 0.475 × size. Tick width 1.9 pt; current-value tick: accent, 2.5 pt. Filled tick alphas per ring: 0.75 / 0.50 / 0.30 of ink; track `rgba(30,29,27,0.09)`.
- **Dial center**: serif 52 pt ink `64`, below it SF 15 pt `days` in `rgba(30,29,27,0.5)`.
- Below dial (24 pt): italic serif 18 pt `until September 15`, `rgba(30,29,27,0.55)`.
- **Units row** (28 pt below, centered, 26 pt gaps): serif 24 pt ink numerals + SF 12 pt unit abbreviations (`hr`, `min`, `sec`) in `rgba(30,29,27,0.45)`. Numbers update live every second.
- **Dot ledger**: same as Ledger; stroke `rgba(30,29,27,0.35)`, today filled `#4C6CA8`.

### Style 3 · T-Minus (reference: 7c)
Near-black, coral accent, huge type, concentric dial cropped off the right edge.
- **Background** `#14161B`; accent `#FF7A59`.
- **Concentric dial**: 620 pt, vertically centered, positioned so its right edge extends 230 pt past the screen's right edge (left edge lands ~12 pt from screen left). Same ring structure as Editorial. Tick width 3.6 pt (selected 4.6 pt). Filled tick colors: white at alphas 0.30 / 0.22 / 0.14 per ring; track `rgba(255,255,255,0.05)`. No center numeral.
- **Type block** (left 28 pt, top ~150 pt): `T-MINUS` — SF 13 pt bold, tracking 3, coral; `64` — SF 120 pt weight 800, white, tracking −4, 8 pt below; `DAYS` — SF 15 pt semibold, tracking 4, `rgba(255,255,255,0.45)`, 6 pt below.
- **Unit stack** (left 28 pt, bottom 170 pt, 16 pt gaps): rows of coral SF 32 pt bold tabular numerals + label (`HR` / `MIN` / `SEC`) SF 12 pt semibold, tracking 2, `rgba(255,255,255,0.4)`. Live values.
- **Bottom pill** (left 28 pt, bottom 52 pt): `SEP 15, 2026 | ⚙` — bg `rgba(255,255,255,0.06)`, 0.5 pt border `rgba(255,255,255,0.1)`, fully rounded, padding 11×18 pt; date SF 15 pt semibold white; 1 pt divider; gear `rgba(255,255,255,0.5)`. Opens the settings sheet.

### Unified Settings Sheet (reference: 7d)
One bottom sheet replaces the gear menu + inline date picker. Presented as a UIKit sheet (`UISheetPresentationController`, medium/large detent), bg `#2A3140`, top corners 24 pt, grabber.
- **Title row**: `Countdown` SF 19 pt semibold white; `Done` right, 16 pt semibold, accent `#BFE8FB`.
- **STYLE section** (section captions: SF 12 pt semibold, tracking 1.5, uppercase, `rgba(255,255,255,0.4)`): three equal-width cards, 10 pt gaps. Each card: 14 pt radius, thumbnail preview of the style + name below (11.5 pt). Selected card: 1.5 pt accent border + `rgba(191,232,251,0.1)` fill + accent-colored name with ✓. Unselected: `rgba(255,255,255,0.05)` fill, `rgba(255,255,255,0.1)` border. Selecting applies instantly behind the sheet.
- **Date wheels**: standard `UIDatePicker` (`.wheels`, date-only), on the sheet's background with a `rgba(255,255,255,0.07)` selection band, 9 pt radius.
- **Refill animation row**: full-width inset row (`rgba(255,255,255,0.05)` fill, 1 pt `rgba(255,255,255,0.08)` border, 12 pt radius, 14×16 pt padding): label `Refill animation` (SF 14 pt, `rgba(255,255,255,0.6)`) and value `Launch volley` (SF 14 pt medium, white). The volley is the single shipped animation — this row is informational (the old 6-style animation list is retired).

## Interactions & Behavior

### Live countdown
- 1 Hz timer updates all numerals and ring values (existing `updateDifferenceLabels` pattern).
- Numerals use tabular figures so widths don't jitter.

### Launch-volley refill (all styles, all rings)
Plays whenever a unit rolls over (its ring drains to 0 and the parent unit decrements):
- **Trigger**: seconds hit 0 → minutes −1, seconds ring refills. Hour rollover: minutes AND seconds rings refill **simultaneously**.
- **Per-tick delay**: `hash(i) × 420 ms`, where `hash` is a stable per-index pseudo-random in [0,1) — use the sin-hash already in `TickDialView`: `fract(sin(i × 12.9898 + 1) × 43758.5453)`.
- **Per-tick travel**: 340 ms. The tick scales radially from the dial center to its slot: both endpoints multiplied by `s = easeOutBack(t)` with `c1 = 1.70158` (slight overshoot).
- **Color during travel**: accent at `0.3 + 0.7t` alpha, width +0.5 pt; on landing it settles to the ring's normal filled color/width.
- **Track ticks** stay visible underneath throughout.
- Total refill ≈ 760 ms. Implement with the existing `CADisplayLink` pattern (`sweepIn` is the closest current analog; this replaces its circular fill).
- Mini dials in Ledger use the identical mechanic at their smaller size.

### Settings
- Style selection writes `UserDefaults` `visualStyle` and re-renders the main screen immediately (crossfade ~250 ms acceptable).
- Date selection persists under the existing `date` key; on change, rings sweep to new values using the volley.

## State Management
- `visualStyle: VisualStyle` (UserDefaults `visualStyle`, default `.ledger`)
- `countdownDate: Date` (existing UserDefaults `date`)
- Per-ring animation state: refill progress 0…1 driven by `CADisplayLink` (existing pattern in `TickDialView`)
- Derived per second: `days`, `hours`, `minutes`, `seconds` (clamped ≥ 0)

## Design Tokens

### Shared geometry (matches existing TickDialView naming)
- Big-dial tick width 2.3 pt · `tickLengthRatio` 0.24 · `ringScale` 0.95
- Concentric dials: band 0.08 × size · gap 0.032 × size · outer radius 0.475 × size · tick 1.9 pt (selected 2.5 pt)
- Dot ledger: 16 columns · 19–21 pt cell · dot r = 0.22 × cell · stroke 1.1 pt

### Palettes
| Token | Ledger | Editorial | T-Minus |
|---|---|---|---|
| Background | `#212836` | `#F5F2EC` | `#14161B` |
| Foreground | `#FFFFFF` | `#1E1D1B` | `#FFFFFF` |
| Accent | `#BFE8FB` | `#4C6CA8` | `#FF7A59` |
| Filled tick | `rgba(151,151,151,0.9)` | ink @ 0.75/0.5/0.3 per ring | white @ 0.30/0.22/0.14 per ring |
| Track tick | `rgba(151,151,151,0.14)` | `rgba(30,29,27,0.09)` | `rgba(255,255,255,0.05)` |
| Secondary text | `rgba(255,255,255,0.4–0.5)` | `rgba(30,29,27,0.45–0.55)` | `rgba(255,255,255,0.4–0.45)` |

### Typography
- Serif numerals (Ledger, Editorial): **New York** on iOS (`UIFont.systemFont` with `.serif` design) — the HTML uses Georgia as the web stand-in.
- Everything else: SF (system). Sizes as specified per screen above.
- Uppercase captions: 11–13 pt semibold, letter-spacing 1.5–4.

### Animation
- Volley: delay `hash(i)×420 ms`, travel 340 ms, easeOutBack `c1=1.70158`, accent→filled
- Style switch crossfade: 250 ms
- Sheet: standard UIKit sheet physics

## Assets
None required. All graphics are drawn (Core Graphics ticks, circles). The gear may remain `UIImage(systemName: "gearshape")`.

## Screenshots
`screenshots/` contains reference captures (note: serif numerals render as Georgia in these; use New York on iOS):
- `style-1-ledger.png` · `style-2-editorial.png` · `style-3-tminus.png` — the three styles
- `settings-sheet.png` — unified settings sheet with the Style picker

## Files
- `Countdown Redesigns.dc.html` — full design document. The **handoff row is badges 7a–7e** (top section): 7a Ledger, 7b Editorial, 7c T-Minus (all live, animated), 7d settings sheet, 7e spec card. Earlier sections are exploration history and superseded ideas.
- `ios-frame.jsx` — iPhone device-frame scaffolding used by the HTML doc (presentation only; not part of the design).
- `support.js` — runtime for the HTML doc (presentation only).

Open `Countdown Redesigns.dc.html` in a browser to watch the live volley/rollover animations while implementing.
