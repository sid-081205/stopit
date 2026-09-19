# stopit

stopit is a private, native iOS app for reducing one unwanted habit. A tap records either an urge or an actual occurrence, and the app turns those entries into a factual daily trend and weekly target view.

## features

- immediate `urge` and `did it` logging
- optional in-app notes after logging: `morning`, `bored`, `trigger`, or `night`
- reason trends for urges and occurrences on insights
- editable and deletable timestamped history
- daily urge and occurrence charts for 7, 30, and 90 days
- configurable target of 0 through 99 actual occurrences per week
- small and medium interactive home-screen widgets
- Dynamic Type, VoiceOver descriptions, and Reduce Motion support
- local App Group storage with no account or third-party dependency

## requirements

- iOS 17 or newer
- Xcode 15.4 or newer
- an Apple development team for device builds and App Group signing

## open and run

1. Open `stopit.xcodeproj` in Xcode.
2. Select the `stopit` scheme.
3. Configure signing as described below.
4. Choose an iOS 17+ simulator or device and press Run.

The project contains the app, widget, unit-test, and UI-test targets. It has no package-manager setup step.

## signing and identifiers

The checked-in example identifiers are intentionally easy to find:

| setting | example |
| --- | --- |
| app bundle | `com.example.stopit` |
| widget bundle | `com.example.stopit.widget` |
| App Group | `group.com.example.stopit` |

Before signing:

1. In the app target’s Build Settings, replace `PRODUCT_BUNDLE_IDENTIFIER`.
2. In the widget target’s Build Settings, replace `PRODUCT_BUNDLE_IDENTIFIER`.
3. Replace `APP_GROUP_IDENTIFIER` with an App Group owned by your team in both targets.
4. Select your development team for both targets.
5. In Signing & Capabilities, ensure the App Groups capability is present on both targets and that the same group is checked.

The App Group value is substituted into both entitlements files and each target’s `StopitAppGroupIdentifier` Info.plist key. No source-code edit is required. The test bundle identifiers may also be changed if your signing setup requires it.

## shared storage

Settings are encoded into App Group `UserDefaults`. Events live in the App Group container under `events/`, with one atomic Codable JSON file per UUID. Separate event files keep concurrent widget actions from overwriting unrelated entries. Dates are stored as absolute `Date` values and grouped with `Calendar.autoupdatingCurrent` when displayed.

App and widget mutations ask WidgetKit to reload their timelines. There is no network client, backend, analytics, cloud sync, or account.

## add the widget

1. Run the app once and finish setup.
2. Touch and hold the iOS Home Screen, then choose **Add Widget**.
3. Search for `stopit`.
4. Add the small or medium widget.

Both widget buttons use iOS 17 App Intents and record directly to the shared App Group while the app is closed.

## tests

From Xcode, use **Product → Test**. From a machine with Xcode installed:

```sh
xcodebuild test \
  -project stopit.xcodeproj \
  -scheme stopit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

Unit tests cover storage, sorting, day/range aggregation, weekly goals, estimates, trend comparison, optional reasons, and settings. UI tests cover onboarding, both log actions, attaching a reason, event editing/deletion, target changes, and insight range selection.

## privacy

Your data stays on this device. stopit does not collect or send it anywhere.

The app contains no analytics, advertising SDK, network requests, tracking permission, account system, or health claims.
