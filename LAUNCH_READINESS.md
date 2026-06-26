# Sennel — App Store Launch Readiness

**Short answer: not yet.** Phases 1–3 (persistence, StoreKit, notifications) are
in good shape, but there are a few code-level blockers and a longer list of
account-side/manual tasks that have to happen outside this repo before
`com.sennel.app` can actually go to App Store review. This doc is a snapshot
as of commit `8a84e3e` on `design/phase1`.

---

## Blockers (must fix before submission)

1. **Premium copy promises features that don't exist yet.**
   `PaywallView.swift:67` and `SettingsView.swift:231` advertise "home screen
   widgets" and "a Live Activity countdown" as part of Premium. Neither
   exists — Phase 4 (WidgetKit) and Phase 5 (Live Activity) haven't been
   built. Apple review will reject this as misleading subscription
   marketing, and a paying subscriber would be owed a feature that isn't
   there. Either build Phase 4/5 first, or strip the widget/Live Activity
   language from both screens until they ship.

2. **Terms of Service / Privacy Policy links are placeholders.**
   `PaywallView.swift:164-165` link to `https://sennel.app/terms` and
   `https://sennel.app/privacy` — there's a `// TODO` next to them. App
   Store Connect requires a **working** privacy policy URL for every app,
   and a working Terms of Use URL is mandatory for any app selling
   auto-renewable subscriptions (Apple checks this). These pages need to
   exist on a real, reachable domain before submission, and the policy text
   needs to actually describe what Sennel collects (craving intensity,
   triggers, withdrawal symptoms — health-adjacent data, even though it
   never leaves the device today).

3. **No real subscription products in App Store Connect.**
   `Products.storekit` is a *local* StoreKit Testing config for the
   simulator — it has no relationship to what's live for real users.
   `com.sennel.app.premium.monthly` / `.yearly` need to be created for real
   in App Store Connect (same product IDs, same subscription group,
   pricing, localized display info), and the Paid Applications Agreement +
   banking/tax info need to be in place, or every purchase will fail in
   production.

4. **Phase 3 hasn't been compiled yet.** The last confirmed build was the
   `StoreManager.deinit` fix (commit `bdd6038`). The notification work in
   `8a84e3e` (`NotificationManager.swift`, the `SennelApp`/`MainTabView`/
   `SettingsView` wiring, the `remindersOn` field) has only been
   statically checked here — brace balance and pbxproj structure — not
   actually built. Do a clean build on your Mac before anything else below.

## Missing app-level config

5. **No `PrivacyInfo.xcprivacy` privacy manifest.** Apple has been enforcing
   this at review time; SwiftData/UserNotifications/StoreKit usage may
   trigger "required reason API" declarations. Worth adding even though
   everything here is first-party Apple framework usage.

6. **Export compliance not declared.** `ITSAppUsesNonExemptEncryption`
   isn't set in the generated Info.plist, so App Store Connect will ask at
   submission time. Standard HTTPS-only usage (StoreKit) normally qualifies
   for the exemption — just don't skip the question.

7. **App icon is unverified.** `Sennel-AppIcon-1024.png` exists at the
   right size, but I can't open/inspect images from this sandbox — confirm
   on your Mac that it has no alpha channel and isn't pre-rounded (Apple
   applies the mask itself; a pre-rounded icon gets rejected).

## Account-side / manual tasks (no code involved)

8. **Apple Developer Program enrollment** ($99/yr) and a registered App ID
   for `com.sennel.app`, if not already done.
9. **Code signing** — distribution certificate + provisioning profile (or
   Xcode "Automatically manage signing") for an actual archive/upload; the
   pbxproj has no `DEVELOPMENT_TEAM` set, which is normal for a repo but
   means this is still a manual per-developer step.
10. **App Store Connect listing**: app description, keywords, support URL,
    marketing URL, screenshots for every device size you ship (the project
    builds for iPad too — `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad`
    — so iPad screenshots are required, not just iPhone), age rating
    questionnaire, and the **App Privacy "nutrition label"** — you'll need
    to accurately declare that craving/symptom logs and usage counts are
    collected (even though only stored on-device today).
11. **On-device manual verification** the plan already calls out and that
    hasn't happened yet: StoreKit Testing sandbox purchase + restore flow,
    real notification delivery timing, Dynamic Type at largest accessibility
    size, light/dark mode, VoiceOver pass, and a full kill-and-relaunch to
    confirm persistence survives.

## Already in decent shape

- SwiftData persistence (Phase 1), StoreKit2 paywall wiring (Phase 2), and
  local notification scheduling (Phase 3) are implemented and structurally
  sound in the pbxproj.
- No HealthKit, location, camera, contacts, or tracking SDK usage — so no
  extra Info.plist privacy-string prompts or App Tracking Transparency
  flow needed.
- No login/account system, so no "must support account deletion" requirement.
- Permission priming is handled correctly — notification permission is
  requested from an explicit Settings toggle, not during onboarding.

## Recommended order

1. Decide: ship Phase 4/5 first, or cut the widget/Live Activity copy from
   Premium now and ship without them (can add later as a value-add update).
2. Build and run Phase 3 on your Mac; fix whatever the compiler finds.
3. Stand up real Terms/Privacy pages and wire the App Store Connect
   subscription products.
4. Work through the App Store Connect listing + manual verification list
   above.
5. Submit.
