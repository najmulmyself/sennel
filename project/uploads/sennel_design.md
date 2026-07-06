# Sennel — iOS Design Guidelines
**For implementation handoff. Source: `Nicotine cessation app prd.md`. Platform: native SwiftUI, iOS 26+.**

This document is the single source of truth for visual design, motion, and consistency. If a screen needs a decision not covered here, default to the calmer, more restrained option — that's the brand.

---

## 1. Design Philosophy

**Clean-Recovery, not clinical, not "tech bro dark mode."** Every other app in this category defaults to dark backgrounds with neon-green accents and shame-based relapse UI. Sennel is the opposite: light-first, warm, proud. The user isn't sick — they're becoming someone new. Design for pride, not guilt.

Three non-negotiables carried from the PRD:
1. The UI gets visibly calmer/more vibrant as the streak grows — color is a storytelling device, not decoration.
2. Nothing about relapse/restart should look or feel like punishment.
3. Every animation should feel organic and earned, never gamified-slot-machine.

---

## 2. Color System

These are the only colors used anywhere in the app. Implement as an Asset Catalog color set (`Sennel.colorset`) or a `Color` extension — never hardcode hex values in views.

### Brand gradient (also the app icon)
| Token | Hex | Use |
|---|---|---|
| `brand.tealLight` | `#2DD4BF` | Gradient start, light-mode accents |
| `brand.emeraldDeep` | `#047857` | Gradient end, dark-mode accents, primary CTA |

### Progressive streak color (the core visual mechanic)
The hero card's accent color interpolates through these stops as streak length increases — never cut abruptly, always animate the transition.

| Stage | Days | Hex | Feel |
|---|---|---|---|
| 0 | 0–2 | `#94A3B8` (slate) | Cool, neutral — no judgment, just a start |
| 1 | 3–7 | `#5EEAD4` (teal-300) | Warming up |
| 2 | 8–29 | `#2DD4BF` (teal-400) | Building |
| 3 | 30+ | `#047857` (emerald-700) | Arrived |

### Surface & text
| Token | Light | Dark |
|---|---|---|
| `surface.background` | `#FAFAF9` (warm off-white, not pure white) | `#0B1410` (deep teal-black — **not** pure black/grey, dark mode must still feel like Sennel) |
| `surface.card` | `#FFFFFF` | `#13201C` |
| `text.primary` | `#0F172A` | `#ECFDF5` |
| `text.secondary` | `#64748B` | `#9CA8A4` |

### Functional accents (use sparingly, never as primary brand color)
| Token | Hex | Use |
|---|---|---|
| `accent.shield` | `#F59E0B` (warm amber) | Streak shield UI only |
| `accent.lock` | `#94A3B8` (neutral slate, low-opacity) | Soft-paywall blur overlays |

**Rule:** if a screen needs a color not in this table, the answer is to reuse an existing token with adjusted opacity, not introduce a new hex value.

---

## 3. Typography

System fonts only — SF Pro for UI text (full Dynamic Type support), **SF Pro Rounded** for the hero numbers (streak days, money saved). The rounded weight is what gives the big numbers their "proud," not clinical, character.

| Style | Font / Style | Size (base) | Use |
|---|---|---|---|
| Hero Number | SF Pro Rounded, Bold | 72–96pt, via `@ScaledMetric` | Streak day count, money saved |
| Large Title | SF Pro, system `.largeTitle` | 34pt | Screen headers |
| Headline | SF Pro, system `.headline` | 17pt semibold | Card titles |
| Body | SF Pro, system `.body` | 17pt | All body copy |
| Caption | SF Pro, system `.caption` | 12pt | Timestamps, helper text |

**Rule:** every text element uses a system text style (`.largeTitle`, `.body`, etc.), never a fixed point size, except the Hero Number — which still must scale via `@ScaledMetric` so it respects Dynamic Type at large accessibility sizes. Test every screen at the largest Dynamic Type setting before calling it done.

---

## 4. Spacing & Layout

4pt base grid.

| Token | Value | Use |
|---|---|---|
| `space.xs` | 4pt | Icon-to-label gaps |
| `space.sm` | 8pt | Internal component spacing |
| `space.md` | 16pt | Screen margins, standard gaps |
| `space.lg` | 24pt | Between major sections |
| `space.xl` | 40pt | Above/below hero card |
| `radius.card` | 24pt | All cards |
| `radius.button` | 16pt | All buttons |
| `radius.pill` | full (height/2) | Tags, badges |

One primary action per screen. Generous whitespace over density — if a screen feels crowded, cut content before shrinking spacing.

---

## 5. Liquid Glass (iOS 26) — Where It Goes and Where It Doesn't

Use `.glassEffect()` / `GlassEffectContainer`, tinted with the current progressive streak color (Section 2), on:
- The hero streak card and money-saved card (the two things screenshots/reviews will show)
- The floating pouch-log button
- The paywall card
- Tab bar (native system glass is fine here, no custom tint needed)

**Do not** use glass on:
- List rows (craving log entries, health timeline list) — glass reduces text contrast, keep these flat/solid
- Any dense body-text container
- The relapse/restart screen — this should feel solid and grounding, not airy

**Always** check text-on-glass contrast manually; translucency that looks fine in a screenshot can fail accessibility contrast in real lighting conditions.

---

## 6. Iconography

SF Symbols only — never a custom icon font. Use `.regular` or `.medium` weight; avoid `.bold`/`.black` weights, which read as aggressive against the calm aesthetic.

**One explicit rule: no flame/fire icons anywhere**, including for the streak. Flame is the standard "streak" symbol in Duolingo/Snapchat-style apps, but for a nicotine app it reads as "lighting up" — exactly the wrong association. Use the **progress ring** (matches the app icon) or `leaf.fill` / `drop.fill` for streak and growth motifs instead.

| Concept | Symbol |
|---|---|
| Streak / progress | Custom ring (Section 9), not a symbol |
| Money saved | `dollarsign.circle.fill` |
| Craving log | `waveform.path.ecg` |
| Breathing exercise | `wind` |
| Health milestone | `leaf.fill` |
| Streak shield | `shield.fill` (amber accent only) |
| Settings | `gearshape.fill` |

---

## 7. Motion

Default easing: `.spring(response: 0.4, dampingFraction: 0.8)` for anything tap-triggered, `.easeInOut(duration: 1.2)` for color/state transitions. Avoid `.linear` everywhere — it reads as mechanical.

| Moment | Animation |
|---|---|
| Streak timer | Continuous, live tick to the second — no easing, this one should just be accurate |
| Pouch log tap | Button scales to 0.96 and springs back; ring fills incrementally; brief 200ms glow pulse on the card |
| Crossing a streak-stage threshold (Section 2) | Background/accent color cross-fades over 1.2s — never an instant cut |
| Milestone reached (health timeline) | Single restrained scale+fade (1.0 → 1.05 → 1.0) with a success haptic — explicitly **not** confetti or particle effects, which would undercut the premium tone |
| Onboarding question transitions | Horizontal slide + crossfade, 0.3s |
| Soft paywall reveal | Gentle blur-in on locked content, glass shimmer, never a hard cut to a lock icon |
| Relapse / restart flow | Calm fade only. No shake, no red flash, no "are you sure" friction — matches the PRD's explicit no-shame requirement |

**Accessibility:** every animation must check `@Environment(\.accessibilityReduceMotion)` and substitute an instant state change when true. This isn't optional — build it into the base component, not per-screen.

---

## 8. Haptics

Use SwiftUI's `.sensoryFeedback()` modifier (iOS 17+). Exact mapping:

| Action | Feedback |
|---|---|
| Pouch logged | `.impact(weight: .light)` |
| Milestone reached | `.success` |
| Streak shield used | `.impact(weight: .medium)` |
| Relapse / restart | `.impact(weight: .soft)` — deliberately gentle, never a harsh/negative pattern |
| Interval scheduler unlock ("next pouch eligible now") | `.impact(weight: .light)` |

---

## 9. The Streak Ring (Core Component)

This is the single most-reused component in the app and the same motif as the app icon — keep them visually identical in concept.

- A circular progress ring, ~270° sweep (matches the icon's geometry), stroke width scales with card size, rounded caps
- Ring color = current progressive streak color (Section 2), animated per Section 7
- A bright accent dot at the leading edge represents "today" — this is the same "small start dot, larger glowing end dot" relationship as the icon
- VoiceOver: the ring itself is never just a decorative shape — pair it with `.accessibilityLabel("Streak progress")` and `.accessibilityValue("Day \(n), \(percent) to next milestone")`

---

## 10. Screen-by-Screen (Phase 1 scope)

**Onboarding (2 screens only, per PRD).** Full-bleed background in stage-0 slate. Single question per screen, large tap targets, slide+crossfade transition. No glass — keep this screen simple and fast.

**Home (the proof-of-value screen).** Hero card with glass effect in current stage color: streak ring + Hero Number day count, money-saved Hero Number ticking in real time below it. One large primary button: "I just used a pouch" (uses pouch-log haptic/animation from Section 7). No tab bar visible yet if it would compete with this moment — this screen IS the app on first launch.

**Pouch log confirmation.** Inline on the home screen, not a separate modal — ring increments, glow pulse, haptic, done. Never interrupt with a confirmation dialog.

**Health Timeline.** Flat list (no glass), milestone rows with `leaf.fill`, completed milestones in full stage color, upcoming ones in `text.secondary`.

**Interval Scheduler (Lite).** Simple card showing "Next pouch eligible at [time]," countdown styled consistently with the streak ring's accent color. Notification copy should match the calm, non-nagging tone established elsewhere.

**Soft Paywall.** Real content visible underneath, blurred via glass per Section 5 — never a flat lock screen. Price and Restore Purchases per the compliance doc, styled as a glass card matching the home screen's hero card.

**Settings.** Standard iOS list style, flat, no glass — this is a utility screen, treat it like one.

---

## 11. Dark Mode

Not an inverted light mode — a deliberate second mode using the dark tokens in Section 2. The progressive streak color system still applies; the deep teal-black background (`#0B1410`) means even early-stage (slate) accents read as intentional rather than washed out. Test every screen in both modes before considering it complete.

---

## 12. Accessibility Checklist

- [ ] Dynamic Type tested at largest accessibility size on every screen
- [ ] VoiceOver labels on streak ring, log button, and every milestone row
- [ ] Text-on-glass contrast manually verified (Section 5)
- [ ] Reduce Motion fallback implemented at the component level (Section 7)
- [ ] Haptics use `.sensoryFeedback()`, which already respects system haptic settings

---

## 13. App Icon

**File delivered:** `Sennel-AppIcon-1024.png` (1024×1024, RGB, no transparency, no pre-rounded corners — per Apple's requirement, iOS applies the corner mask automatically).

**Concept:** the same progress ring as Section 9, on the brand gradient (Section 2), with the small/large dot relationship telling a one-glance story — a small start point, a long arc of progress, a bright "you are here" point at the end. This is deliberately the same visual language as the in-app streak ring, so the icon isn't a separate logo — it's a preview of the actual product.

**Xcode setup:** modern Xcode asset catalogs only need this single 1024×1024 size — Xcode generates every other required size automatically. Drop it into the single-size App Icon slot in `Assets.xcassets`.

---

## 14. Consistency Rules (read this before building any screen)

1. No color outside the Section 2 token table. Ever.
2. No spacing value outside the Section 4 scale.
3. No custom icons — SF Symbols only, and never flame/fire imagery.
4. No fixed-point-size text outside the Hero Number style — use system text styles.
5. No glass on dense text or list rows.
6. No confetti/particle effects, anywhere, even for big milestones — the celebration vocabulary is restrained (Section 7).
7. No shame-coded UI on the relapse/restart flow — calm fade, soft haptic, preserved history.
8. Every new animated element gets a Reduce Motion fallback before it ships, not after.
