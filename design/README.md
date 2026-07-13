# Design prototypes

Interactive design studies for the Countdown app. Open the `.html` files in any browser.

## dot-rollover-transitions.html

Explores how the "one dot per day" ledger (`DotLedgerView`) should behave when a
day rolls over. Moves the grid from a **subtractive** model (dots are removed as
days pass) to a **fixed-grid** model (every day of the span has a stable dot that
changes state).

Four transition treatments are shown side by side: **Dissolve**, **Ring draw**,
**Flip**, **Ripple**, plus a direction toggle (empty-as-days-pass vs
fill-as-days-pass).

### Decision (2026-07-13)

- **Direction:** *Empty as days pass* — the grid starts full and drains, reading
  as spending a finite reserve of days.
- **Transition:** *Dissolve* — a calm opacity/scale cross-fade between the filled
  and hollow states. Chosen for an ambient, always-on countdown.

### Implementation note

`DotLedgerView` currently receives only `days` (days remaining). The fixed-grid
model needs a **second input — the total span** (e.g. days from countdown
creation to the target date) so it can draw `total` dots and know which are
filled. Animating individual dots will likely mean moving from `draw(_:)` to
per-dot `CAShapeLayer`s, since Core Graphics can't animate individual dots.
