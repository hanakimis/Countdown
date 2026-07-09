# Countdown
iOS app for counting down days

Progress:

3/6/2016
DONE
- Figured out how to get code from paintcode into the actual app. This article was super helpful: https://www.raywenderlich.com/90690/modern-core-graphics-with-swift-part-1
- started Design v2 on another viewController so that I would still have the original design on the first view controller
TODO
- Make the drawing animate (I think I can follow this: http://stackoverflow.com/questions/26578023/animate-drawing-of-a-circle)
- Make the drawing a percentage / based on size of canvas / autolayout

------------

2026 revisit
DONE
- Modernized from Swift 2 to current Swift (Date/Calendar/UserDefaults, #selector,
  UILayoutPriority, UNUserNotificationCenter for the icon badge).
- Replaced the 84 pre-rendered dial PNGs (hour0…23 / minorsec0…59) with a single
  vector view, `TickDialView`, drawn in Core Graphics. It scales to any size, is
  recolorable, and is `@IBInspectable` in Interface Builder. This is the "draw it
  with shapes instead of images" idea from Design v2, done properly.
- Pointed the app back at the finished countdown screen. It previously launched into
  the empty "Design v2" stub, which has now been removed along with its leftover files
  (Timer.swift / TotalRemainingUIView.swift / daysLeftUIView.swift).
DONE (animation pass)
- Sweep-in fill: the rings animate from empty up to their values on first appear
  and whenever a new date is set (CADisplayLink interpolating a fractional value).
- Selected-tick styles: the accent tick can animate as Classic, Launch, Eject,
  Ripple In, Wake, or Ripple In + Wake — one `SelectStyle` enum on TickDialView.
  Ripple converges from the upcoming side; Wake trails the recent past.
- Settings sheet: a gear button opens StyleSettingsViewController to switch styles;
  the choice persists in UserDefaults and applies to all three dials.
- Bumped the deployment target to iOS 15 (uses safe-area layout, SF Symbols, etc).
TODO
- The old dial PNGs in Images.xcassets are now unused and can be deleted.
- ViewController.swift is the empty default template and is no longer referenced.