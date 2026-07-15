//
//  DotLedgerView.swift
//  Countdown
//
//  "One dot per day": a fixed grid holding every day of the countdown's span,
//  16 columns. The grid size is frozen at the original day count and never
//  loses dots. As days pass the grid *fills in* (reading order, top-left first):
//
//    • elapsed days  → filled discs in the style's foreground at reduced alpha
//    • today         → a depleting accent gauge (arc = fraction of today left)
//    • remaining     → outlined rings, 1.1 pt stroke
//
//  Everything is drawn each frame in `draw(_:)` (Core Graphics circles); a
//  `CADisplayLink` runs only while something is moving — the selectable load
//  animation on appear, the touch-response effects, or a day rollover — then
//  parks itself so an idle ledger costs nothing. This mirrors the dials'
//  `DialRing` engine and is what makes the continuous per-dot fields in the
//  touch spec (pulse ring, magnet pull, jitter) tractable.
//

import UIKit
import QuartzCore

// MARK: - Selectable load animation

/// How the whole grid arrives when the ledger first appears (and on tap-replay).
/// Persisted under `"ledgerLoadStyle"`; each case's per-dot timing lives in
/// `DotLedgerView.loadModifiers`.
enum LedgerLoadStyle: String, CaseIterable {
    case sprinkle, cascade, trace, gather

    var title: String {
        switch self {
        case .sprinkle: return "Sprinkle"
        case .cascade:  return "Cascade"
        case .trace:    return "Trace"
        case .gather:   return "Gather"
        }
    }
}

extension DialAnimationSettings {

    /// Raw user preference shown in the settings picker.
    static var ledgerLoadStyle: LedgerLoadStyle {
        get {
            let raw = UserDefaults.standard.string(forKey: "ledgerLoadStyle")
            return raw.flatMap(LedgerLoadStyle.init(rawValue:)) ?? .cascade
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "ledgerLoadStyle") }
    }

    /// Reduce Motion pins the load to Cascade rendered opacity-only (the y-offset
    /// is dropped inside the view), so nothing travels across the grid.
    static var effectiveLedgerLoadStyle: LedgerLoadStyle {
        UIAccessibility.isReduceMotionEnabled ? .cascade : ledgerLoadStyle
    }
}

final class DotLedgerView: UIView {

    // MARK: Palette (set by the host per visual style)

    var accentColor: UIColor = UIColor(hex: 0xBFE8FB)              { didSet { setNeedsDisplay() } }
    var strokeColor: UIColor = UIColor(white: 1, alpha: 0.28)      { didSet { setNeedsDisplay() } }
    /// Filled elapsed-day discs: the style's foreground at a reduced alpha.
    var elapsedColor: UIColor = UIColor(white: 1, alpha: 0.5)      { didSet { setNeedsDisplay() } }

    // MARK: Geometry

    private let columns = 16
    private let maxRows = 9                       // caps the grid (9 × 16 = 144-day capacity)
    private let cell: CGFloat = 19                // vertical pitch (row height)
    private let dotRadiusRatio: CGFloat = 0.22
    private let strokeWidth: CGFloat = 1.1
    private let gaugeWidth: CGFloat = 1.8

    // MARK: Data model

    private var total = 0                          // days in the whole span (fixed grid size)
    private var wholeDays = 0                       // whole days still remaining
    private var dayFraction: CGFloat = 0            // fraction of the current day still left (1…0)

    private var capacity: Int { maxRows * columns }
    private var visibleCount: Int { min(max(total, 1), capacity) }
    /// Grid slot of the day currently in progress. Elapsed days pile up ahead of
    /// it (reading order); remaining days trail behind it.
    private var todayIndex: Int { min(max(total - wholeDays, 0), visibleCount - 1) }

    private enum Role { case elapsed, today, remaining }
    private func role(of p: Int) -> Role {
        if p < todayIndex { return .elapsed }
        if p == todayIndex { return .today }
        return .remaining
    }

    // MARK: Animation timing constants

    private let loadDuration: CFTimeInterval = 1.4
    private let pulseDuration: CFTimeInterval = 0.38
    private let pulseMaxRadius: CGFloat = 100
    private let pulseBand: CGFloat = 20            // dots this close to the ring's edge swell
    private let pressRadius: CGFloat = 56          // finger vicinity for swell / drag effects
    private let springBack: CFTimeInterval = 0.2
    private let quickReleaseTime: CFTimeInterval = 0.35
    private let moveThreshold: CGFloat = 3
    private let rolloverDuration: CFTimeInterval = 0.5

    // MARK: Animation state

    private var displayLink: CADisplayLink?

    private var loadStart: CFTimeInterval?         // nil when not loading
    private var loadStyle: LedgerLoadStyle = .cascade
    private var loadOrigin: CGPoint = .zero        // gather origin (grid center, or finger on replay)
    private var loadMaxDist: CGFloat = 1
    private var hasPlayedLoad = false

    // Touch
    private var isPressed = false
    private var didDrag = false
    private var touchPoint: CGPoint = .zero
    private var lastTouchPoint: CGPoint = .zero
    private var touchStart: CFTimeInterval = 0
    private var touchStartPoint: CGPoint = .zero
    private var pulseStart: CFTimeInterval?
    private var pulseOrigin: CGPoint = .zero
    private var releaseTime: CFTimeInterval?       // start of the post-drag spring-back

    // Rollover (a day just passed)
    private var rolloverStart: CFTimeInterval?
    private var rolloverIndex = -1

    // MARK: Init

    override init(frame: CGRect) { super.init(frame: frame); commonInit() }
    required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        isUserInteractionEnabled = true
    }

    // MARK: Public API

    /// Seeds or advances the grid. `total` sizes it (the fixed original span),
    /// `wholeDays` is the count still remaining, `dayFraction` fills today's
    /// gauge. When `animated`, a day that just rolled over fades into place.
    func setValues(total: Int, wholeDays: Int, dayFraction: CGFloat, animated: Bool) {
        let newTotal = max(total, 1)
        let newWhole = min(max(wholeDays, 0), newTotal)
        let prevTodayIndex = self.total > 0 ? todayIndex : -1

        self.total = newTotal
        self.wholeDays = newWhole
        self.dayFraction = min(max(dayFraction, 0), 1)

        if newTotal != total { invalidateIntrinsicContentSize() }

        // A day passed: the old "today" dot has just become elapsed. Fade it in.
        if animated, prevTodayIndex >= 0, todayIndex > prevTodayIndex {
            rolloverIndex = prevTodayIndex
            rolloverStart = CACurrentMediaTime()
            startLink()
        }
        setNeedsDisplay()
    }

    /// Plays the selected load animation. `origin` seeds `gather` (grid center by
    /// default; the finger on tap-replay). Ignored by the other styles.
    func replayLoad(origin: CGPoint? = nil) {
        loadStyle = DialAnimationSettings.effectiveLedgerLoadStyle
        loadOrigin = origin ?? CGPoint(x: bounds.midX, y: gridHeight / 2)
        loadMaxDist = maxDistance(from: loadOrigin)
        loadStart = CACurrentMediaTime()
        startLink()
        setNeedsDisplay()
    }

    // MARK: Layout / lifecycle

    override var intrinsicContentSize: CGSize {
        let neededRows = Int(ceil(Double(max(total, 1)) / Double(columns)))
        let rows = max(1, min(neededRows, maxRows))
        return CGSize(width: CGFloat(columns) * cell, height: CGFloat(rows) * cell)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Play the load animation the first time we have real bounds on screen.
        if !hasPlayedLoad, window != nil, bounds.width > 0, total > 0 {
            hasPlayedLoad = true
            replayLoad()
        }
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            displayLink?.invalidate()
            displayLink = nil
        } else if !hasPlayedLoad, bounds.width > 0, total > 0 {
            hasPlayedLoad = true
            replayLoad()
        }
    }

    // MARK: Display link

    private func startLink() {
        if displayLink == nil {
            let link = CADisplayLink(target: self, selector: #selector(step))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
        displayLink?.isPaused = false
    }

    @objc private func step() {
        setNeedsDisplay()
        if !isAnimating(at: CACurrentMediaTime()) {
            displayLink?.isPaused = true   // park until the next interaction / rollover
        }
    }

    /// True while any time-based effect still has frames to draw.
    private func isAnimating(at now: CFTimeInterval) -> Bool {
        if isPressed { return true }
        if let s = loadStart, now - s < loadDuration { return true }
        if let s = pulseStart, now - s < pulseDuration { return true }
        if let s = releaseTime, now - s < springBack { return true }
        if let s = rolloverStart, now - s < rolloverDuration { return true }
        return false
    }

    // MARK: Geometry helpers

    private var gridHeight: CGFloat {
        let rows = Int(ceil(Double(visibleCount) / Double(columns)))
        return CGFloat(max(1, min(rows, maxRows))) * cell
    }

    private func dotCenter(_ p: Int) -> CGPoint {
        let colPitch = bounds.width / CGFloat(columns)
        let col = p % columns, row = p / columns
        return CGPoint(x: colPitch * (CGFloat(col) + 0.5),
                       y: cell * (CGFloat(row) + 0.5))
    }

    private func maxDistance(from origin: CGPoint) -> CGFloat {
        var m: CGFloat = 1
        for p in 0..<visibleCount { m = max(m, hypot(dotCenter(p).x - origin.x, dotCenter(p).y - origin.y)) }
        return m
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard bounds.width > 0, total > 0 else { return }
        let now = CACurrentMediaTime()
        let reduceMotion = UIAccessibility.isReduceMotionEnabled

        // Retire finished timelines so their contribution is zeroed.
        if let s = loadStart, now - s >= loadDuration { loadStart = nil }
        if let s = rolloverStart, now - s >= rolloverDuration { rolloverStart = nil; rolloverIndex = -1 }
        if let s = releaseTime, now - s >= springBack { releaseTime = nil }

        let baseR = dotRadiusRatio * cell
        let visible = visibleCount
        let overflow = total > capacity
        let markerIndex = visible - 1

        for p in 0..<visible {
            if overflow && p == markerIndex { drawOverflowMarker(at: dotCenter(p)); continue }

            var mod = DotMod()
            applyLoad(&mod, p: p, now: now, reduceMotion: reduceMotion)
            applyTouch(&mod, p: p, now: now, reduceMotion: reduceMotion)
            applyRollover(&mod, p: p, now: now)

            if mod.hidden { continue }

            let center = CGPoint(x: dotCenter(p).x + mod.dx, y: dotCenter(p).y + mod.dy)
            let r = max(0, baseR * mod.scale)
            // Every dot uses its true fill-in role; when the span overflows the
            // grid, only the final cell is swapped for the "…more beyond" marker
            // (handled above), standing in for the truncated far-future days.
            draw(role: role(of: p), at: center, radius: r, mod: mod)
        }

        drawPulseRing(now: now, reduceMotion: reduceMotion)
    }

    /// Per-dot modifiers accumulated by the load / touch / rollover passes.
    private struct DotMod {
        var scale: CGFloat = 1
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        var alpha: CGFloat = 1        // opacity multiplier (load ramps this from 0)
        var flash: CGFloat = 0        // accent-flash strength for outlined dots (0…1)
        var accentFill: CGFloat = 0   // faint accent fill for outlined dots under the finger
        var hidden = false
    }

    private func draw(role: Role, at c: CGPoint, radius r: CGFloat, mod: DotMod) {
        let a = max(0, min(1, mod.alpha))
        switch role {
        case .elapsed:
            circle(center: c, radius: r).fill(elapsedColor.withMultiplied(alpha: a))

        case .today:
            // Faint full track, then the accent arc = fraction of today remaining.
            let ringR = r - gaugeWidth / 2
            let track = circle(center: c, radius: ringR)
            track.lineWidth = strokeWidth
            strokeColor.withMultiplied(alpha: a).setStroke(); track.stroke()

            if dayFraction > 0.0001 {
                let start = -CGFloat.pi / 2
                let arc = UIBezierPath(arcCenter: c, radius: ringR,
                                       startAngle: start,
                                       endAngle: start + 2 * .pi * dayFraction,
                                       clockwise: true)
                arc.lineWidth = gaugeWidth
                arc.lineCapStyle = .round
                accentColor.withMultiplied(alpha: a).setStroke(); arc.stroke()
            }

        case .remaining:
            let ringR = r - strokeWidth / 2
            if mod.accentFill > 0 {                       // faint accent wash under the finger
                circle(center: c, radius: ringR).fill(accentColor.withMultiplied(alpha: 0.18 * mod.accentFill * a))
            }
            let ring = circle(center: c, radius: ringR)
            ring.lineWidth = strokeWidth
            // Accent flash / finger tint blends the stroke toward accent.
            let m = max(mod.flash, mod.accentFill)
            let stroke = m > 0 ? strokeColor.lerp(to: accentColor, m) : strokeColor
            stroke.withMultiplied(alpha: a).setStroke()
            ring.stroke()
        }
    }

    private func circle(center c: CGPoint, radius r: CGFloat) -> UIBezierPath {
        UIBezierPath(arcCenter: c, radius: max(0.01, r), startAngle: 0, endAngle: 2 * .pi, clockwise: true)
    }

    private func drawOverflowMarker(at c: CGPoint) {
        // "…more beyond" — the span is larger than the grid can hold.
        let dotR: CGFloat = 1.3, gap: CGFloat = 3.6
        let ellipsis = UIBezierPath()
        for k in -1...1 {
            ellipsis.append(UIBezierPath(arcCenter: CGPoint(x: c.x + CGFloat(k) * gap, y: c.y),
                                         radius: dotR, startAngle: 0, endAngle: 2 * .pi, clockwise: true))
        }
        ellipsis.fill(accentColor)
    }

    private func drawPulseRing(now: CFTimeInterval, reduceMotion: Bool) {
        guard !reduceMotion, let s = pulseStart else { return }
        let age = now - s
        guard age < pulseDuration else { pulseStart = nil; return }
        let e = CGFloat(age / pulseDuration)
        let radius = pulseMaxRadius * e
        let ring = UIBezierPath(arcCenter: pulseOrigin, radius: radius,
                                startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        ring.lineWidth = 1.5
        accentColor.withMultiplied(alpha: 0.5 * (1 - e)).setStroke()
        ring.stroke()
    }

    // MARK: - Load pass

    private func applyLoad(_ mod: inout DotMod, p: Int, now: CFTimeInterval, reduceMotion: Bool) {
        guard let start = loadStart else { return }
        let e = CGFloat((now - start) / loadDuration)       // overall 0…1
        let col = p % columns, row = p / columns
        let rows = Int(ceil(Double(visibleCount) / Double(columns)))

        // delay(i) / span per style; per-dot t clamps to [0,1].
        let delay: CGFloat, span: CGFloat
        switch loadStyle {
        case .sprinkle: delay = DialRing.hash(p) * 0.6;                                   span = 0.4
        case .cascade:  delay = CGFloat(col + row) / CGFloat(columns + rows) * 0.7;       span = 0.3
        case .trace:    delay = CGFloat(p) / CGFloat(max(visibleCount, 1)) * 0.78;        span = 0.22
        case .gather:
            let d = hypot(dotCenter(p).x - loadOrigin.x, dotCenter(p).y - loadOrigin.y)
            delay = d / loadMaxDist * 0.55;                                                span = 0.45
        }
        let t = DialRing.clamp((e - delay) / span)
        if t <= 0 { mod.hidden = true; return }             // not yet arrived

        switch loadStyle {
        case .sprinkle:
            mod.scale = DialRing.easeOutBack(t)
            mod.alpha = min(1, t * 2.5)
            mod.flash = max(mod.flash, 1 - t)

        case .cascade:
            mod.alpha = t
            if !reduceMotion { mod.dy = 12 * (1 - t) * (1 - t) }   // rise into place (skipped under Reduce Motion)

        case .trace:
            mod.scale = DialRing.easeOutCubic(t)
            mod.alpha = min(1, t * 3)
            mod.flash = max(mod.flash, 1 - t)

        case .gather:
            let ease = DialRing.easeOutCubic(t)
            let slot = dotCenter(p)
            let x = loadOrigin.x + (slot.x - loadOrigin.x) * ease
            let y = loadOrigin.y + (slot.y - loadOrigin.y) * ease
            mod.dx = x - slot.x
            mod.dy = y - slot.y
            mod.scale = max(0.05, ease)
            mod.alpha = min(1, t * 2.5)
            mod.flash = max(mod.flash, 1 - t)
        }
    }

    // MARK: - Touch pass

    /// Combines the press-vicinity swell, the drag character of the selected load
    /// style, and the expanding pulse ring's local kick into `mod`.
    private func applyTouch(_ mod: inout DotMod, p: Int, now: CFTimeInterval, reduceMotion: Bool) {
        let center = dotCenter(p)

        // Finger vicinity — active while pressed, easing out over `springBack`.
        var pressFactor: CGFloat = 0
        var finger = lastTouchPoint
        if isPressed { pressFactor = 1; finger = touchPoint }
        else if let r = releaseTime { pressFactor = 1 - DialRing.clamp(CGFloat((now - r) / springBack)) }

        if pressFactor > 0 {
            let d = hypot(center.x - finger.x, center.y - finger.y)
            if d < pressRadius {
                let wake = pow(1 - d / pressRadius, 2) * pressFactor
                mod.scale *= 1 + 0.75 * wake
                mod.accentFill = max(mod.accentFill, wake)

                if didDrag && !reduceMotion {
                    // Each style reacts in its own character while dragging.
                    switch loadStyle {
                    case .sprinkle:
                        let ms = now * 1000
                        mod.dx += 5 * wake * CGFloat(sin(ms / 70 + Double(p) * 2.1))
                        mod.dy += 5 * wake * CGFloat(sin(ms / 70 + Double(p) * 2.1 + 1.7))
                    case .cascade:
                        mod.dy -= 9 * wake
                    case .trace:
                        mod.flash = max(mod.flash, wake)
                    case .gather:
                        mod.dx += (finger.x - center.x) * 0.3 * wake
                        mod.dy += (finger.y - center.y) * 0.3 * wake
                    }
                } else if didDrag {
                    mod.flash = max(mod.flash, wake)   // Reduce Motion: swell + flash only
                }
            }
        }

        // Pulse-ring band kick (the expanding acknowledgment ring).
        if !reduceMotion, let s = pulseStart {
            let age = now - s
            if age < pulseDuration {
                let ringRadius = pulseMaxRadius * CGFloat(age / pulseDuration)
                let d = hypot(center.x - pulseOrigin.x, center.y - pulseOrigin.y)
                let band = max(0, 1 - abs(d - ringRadius) / pulseBand)
                let strength = band * CGFloat(1 - age / pulseDuration)
                if strength > 0 {
                    mod.scale *= 1 + 0.75 * strength
                    mod.flash = max(mod.flash, strength)
                }
            }
        }
    }

    // MARK: - Rollover pass

    private func applyRollover(_ mod: inout DotMod, p: Int, now: CFTimeInterval) {
        guard p == rolloverIndex, let s = rolloverStart else { return }
        let t = DialRing.clamp(CGFloat((now - s) / rolloverDuration))
        // The just-elapsed dot fades and settles from the gauge into a filled disc.
        mod.alpha = min(mod.alpha, 0.35 + 0.65 * t)
        mod.scale *= 1 - 0.12 * (1 - t) * (1 - t)
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let now = CACurrentMediaTime()
        let p = t.location(in: self)
        isPressed = true
        didDrag = false
        touchPoint = p; lastTouchPoint = p; touchStartPoint = p
        touchStart = now
        releaseTime = nil
        if !UIAccessibility.isReduceMotionEnabled { pulseStart = now; pulseOrigin = p }
        startLink()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        touchPoint = p; lastTouchPoint = p
        if hypot(p.x - touchStartPoint.x, p.y - touchStartPoint.y) >= moveThreshold { didDrag = true }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouch(replay: true)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouch(replay: false)
    }

    private func endTouch(replay: Bool) {
        let now = CACurrentMediaTime()
        isPressed = false
        let moved = hypot(lastTouchPoint.x - touchStartPoint.x, lastTouchPoint.y - touchStartPoint.y)
        let quick = (now - touchStart) < quickReleaseTime && moved < moveThreshold && !didDrag

        if replay && quick {
            // Tap-to-replay. `gather` reopens from the finger.
            let style = DialAnimationSettings.effectiveLedgerLoadStyle
            replayLoad(origin: style == .gather ? lastTouchPoint : nil)
        } else if didDrag {
            releaseTime = now          // spring the wake back to rest
        }
        startLink()
    }
}

// MARK: - Drawing helpers

private extension UIBezierPath {
    /// Fills the path in `color` without disturbing the surrounding fill state.
    func fill(_ color: UIColor) { color.setFill(); fill() }
}

// MARK: - Color helpers

private extension UIColor {
    /// This color with its alpha scaled by `m` (0…1).
    func withMultiplied(alpha m: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r, green: g, blue: b, alpha: a * max(0, min(1, m)))
    }

    /// Linear blend toward `other` by fraction `t` (0 = self, 1 = other),
    /// interpolating premultiplied-free RGBA so a faint stroke can flush to accent.
    func lerp(to other: UIColor, _ t: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let k = max(0, min(1, t))
        return UIColor(red: r1 + (r2 - r1) * k,
                       green: g1 + (g2 - g1) * k,
                       blue: b1 + (b2 - b1) * k,
                       alpha: a1 + (a2 - a1) * k)
    }
}
