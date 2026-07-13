# Countdown — Style-matched app icons (handoff)

Three alternate app icons, one per visual style. When the user changes style in
Settings (UserDefaults key `visualStyle`), the app icon switches to match.

## Icon sets

| Style key   | Icon name           | Design ref | Look |
|-------------|---------------------|------------|------|
| `ledger`    | `AppIcon-Ledger`    | 1b         | Navy #212836, 5×5 dot ledger, 16 of 25 dots filled white, rest 22% white |
| `editorial` | `AppIcon-Editorial` | 1d         | Paper #F5F2EC, concentric ink tick rings (60/40/24 ticks, alphas .75/.5/.3), center dot |
| `tminus`    | `AppIcon-TMinus`    | 1g         | Black #14161B, coral #FF7A59 tick rings (alphas 1/.55/.3), dial center at 83.3%/83.3% of icon so rings crop off the bottom-right corner |

Tick geometry matches TickDialView: length ratio 0.24, round caps.
All PNGs are full-square with NO baked-in corner radius and NO alpha — iOS
applies the squircle mask itself.

## Files per set

- `<Name>-1024.png` — App Store / asset catalog master
- `<Name>-180.png` — 60pt @3x (iPhone)
- `<Name>-120.png` — 60pt @2x (iPhone)

(iPad sizes 152/167 can be downscaled from the 1024 master if needed.)

## Integration

1. **Primary icon**: `AppIcon-Ledger` is the default style, so use it as the
   primary `AppIcon` in the asset catalog (drop the 1024 master into a
   single-size AppIcon set).

2. **Alternate icons** (`AppIcon-Editorial`, `AppIcon-TMinus`): add the 120/180
   PNGs to the app bundle (NOT the asset catalog) and declare them in
   Info.plist:

```xml
<key>CFBundleIcons</key>
<dict>
  <key>CFBundlePrimaryIcon</key>
  <dict>
    <key>CFBundleIconFiles</key><array><string>AppIcon-Ledger</string></array>
  </dict>
  <key>CFBundleAlternateIcons</key>
  <dict>
    <key>AppIcon-Editorial</key>
    <dict><key>CFBundleIconFiles</key><array><string>AppIcon-Editorial</string></array></dict>
    <key>AppIcon-TMinus</key>
    <dict><key>CFBundleIconFiles</key><array><string>AppIcon-TMinus</string></array></dict>
  </dict>
</dict>
```

Name the bundled files `AppIcon-Editorial@2x.png` / `AppIcon-Editorial@3x.png`
(from the 120/180 PNGs) etc. so `CFBundleIconFiles` resolves them.

3. **Switch on style change** — in the settings sheet, right where
   `visualStyle` is persisted:

```swift
func applyIcon(for style: String) {
    // primary (ledger) is selected by passing nil
    let name: String? = ["editorial": "AppIcon-Editorial",
                         "tminus":    "AppIcon-TMinus"][style] ?? nil
    guard UIApplication.shared.alternateIconName != name else { return }
    UIApplication.shared.setAlternateIconName(name) // system shows a one-time alert
}
```

Note: `setAlternateIconName` triggers a system alert ("You have changed the
icon…"); that's expected and unavoidable. Call it only when the style actually
changes, never on launch.

## Regenerating

Icons are drawn from the same geometry constants as the app
(see `design_handoff_countdown_styles/README.md` for the shared spec).
If colors change, re-render from those constants rather than editing pixels.
