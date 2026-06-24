# iOS UI implementation guide

_Started 2026-06-20 18:40 UTC_

---

## User

follow PRD and design and app icon. and make UI for ios

## Assistant

I'll start by reading the PRD and design files to understand what we're building.

_[tool: read_file]_

_[tool: read_file]_

The PRD and design doc are thorough. Let me look at the icon closely.

_[tool: view_image]_

I have everything I need to understand Sennel. Let me ask a few focused questions before building.

_[tool: questions_v2]_

## User

Questions answered:
- screens: All of them
- mode: Both, shown side by side
- stage: Show the progression across screens
- fidelity: Full iOS 26 fidelity (Liquid Glass, status bar, device frame)
- variations: No — one strong version of each screen
- interactive: Interactive (live timer, tap to log)

## Assistant

Plan: a side-by-side gallery of iOS device frames covering all Phase 1 screens, in both light and dark mode, with Home showing the slate→teal→emerald progression, live timers, and tap-to-log. Let me grab the iOS frame starter and set up todos.

_[tool: copy_starter_component]_

_[tool: update_todos]_

_[tool: read_file]_

The architecture: a gallery DC that mounts a reusable `SennelHome` child (live timer + tap-to-log, 5 stage/mode variants) plus the static screens. Let me build the Home component first.

_[tool: dc_write]_

SennelHome needs the Nunito font and the breathe keyframe. Let me add a helmet, then preview it standalone.

_[tool: dc_html_str_replace]_

_[tool: show_html]_

_[tool: show_html]_

Home looks strong. Standalone shows zeros (no props); real values come from the gallery. Now the static screens as themeable children. Starting with the Health Timeline.

_[tool: dc_write]_

Now the Interval Scheduler — the PRD's headline differentiator.

_[tool: dc_write]_

Now the Soft Paywall — real content blurred underneath, never a hard wall.

_[tool: dc_write]_

Now Settings — standard iOS grouped list.

_[tool: dc_write]_

Now Onboarding — 2 screens, full-bleed slate (stage 0), no glass.

_[tool: dc_write]_

Now the gallery that ties it all together.

_[tool: dc_write]_

_[tool: show_html]_

Header looks great. The onboarding frames render as blank white — let me check the logs and look closer.

_[tool: get_webview_logs]_

_[tool: save_screenshot]_

_[tool: save_screenshot]_

_[tool: save_screenshot]_

Onboarding renders beautifully. Let me check the Home rows and the rest.

_[tool: multi_screenshot]_

Home and Timeline look excellent — live money ($2.47, $138.85) and ring progression all working. Let me verify the dark Home, Scheduler, Paywall, and Settings.

_[tool: multi_screenshot]_

Dark Home, Timeline, and Paywall all look excellent. The Scheduler and Settings frames are further right in their rows — let me scroll horizontally to verify them.

_[tool: multi_screenshot]_

Everything renders correctly in both modes. Let me verify the tap-to-log interaction fires.

_[tool: eval_js]_

The read was synchronous before React re-rendered. Let me re-test with a delay.

_[tool: eval_js]_

Tap-to-log works — only the tapped frame increments (5→7 of 8), and the live timers/money tick. Everything's verified across both modes. Cleaning up and finalizing.

_[tool: delete_file]_

_[tool: update_todos]_

_[tool: snip]_

Built the full Sennel Phase 1 iOS UI as a side-by-side gallery of 15 device frames.

_[tool: ready_for_verification]_

**Sennel — Phase 1 iOS, 15 screens** following the PRD, design doc, and app-icon DNA:

- **Onboarding** (2 questions, slate stage-0, no glass) → **Home** in the full slate→teal→emerald progression, light *and* dark → **Health timeline**, **Interval scheduler**, **Soft paywall** (real content blurred underneath, never walled), **Settings** — each in both modes.
- The progress ring matches the icon's geometry (270° arc, small start dot, glowing leading "today" dot). Live timers and money-saved tick by the second; tapping **"I just used a pouch"** logs to that screen only, with a glass-card glow pulse.
- All color is from the token table; no flame icons; SF-Rounded feel via Nunito for the proud hero numbers.

Built as a reusable `SennelHome` component plus per-screen DCs, so you can drop any screen into a flow or tweak one in isolation.

Next steps if useful: a relapse/restart flow, the craving logger, or a Dynamic Island / Lock Screen widget mock for the interval countdown.

## User

continue phase 2

## Assistant

Let me check what Phase 2 covers in the PRD.

_[tool: grep]_

Let me read the full Phase 2 section.

_[tool: read_file]_

Phase 2 is the depth layer. Following the exact same design system, I'll build the screen-worthy Phase 2 features as themeable DCs (light + dark): **Craving/trigger logger**, **Withdrawal symptom matrix**, **Insights/weekly charts**, **Achievement badges**, **Guided breathing** (animated/interactive), **Relapse forgiveness**, and **Widgets + Live Activity/Dynamic Island**.

_[tool: update_todos]_

_[tool: dc_write]_

_[tool: dc_write]_

Now Insights (real Swift-Charts content) and Badges.

_[tool: dc_write]_

_[tool: dc_write]_

Now the interactive breathing screen and the relapse forgiveness screen.

_[tool: dc_write]_

_[tool: dc_write]_

## Assistant

_[tool: dc_write]_

## Assistant

_[tool: dc_write]_

Now the Widgets / Lock Screen / Live Activity showcase — the native-edge feature.

_[tool: dc_write]_

## Assistant

_[tool: dc_write]_

Now adding the Phase 2 section to the gallery.

_[tool: read_file]_

_[tool: str_replace_edit]_

Let me update the intro subtitle to reflect both phases, then screenshot the new Phase 2 frames.

_[tool: str_replace_edit]_

_[tool: show_html]_

_[tool: multi_screenshot]_

_[tool: show_html]_

_[tool: multi_screenshot]_

Phase 2 renders beautifully. One safety fix: the "Log a craving" title wraps and crowds its subtitle — let me give it a tight line-height and protect the layout.

_[tool: dc_html_str_replace]_

_[tool: update_todos]_

_[tool: snip]_

Phase 2 is built — 7 new screen types added to the gallery below a Phase 2 divider.

_[tool: ready_for_verification]_

**Phase 2 — Competitive parity + native-exclusive polish** — added beneath a Phase 2 divider in the same gallery, all in the established Sennel system (slate→teal→emerald, Nunito hero numbers, glass cards, light + dark):

- **Craving logger** — intensity bars, trigger chips, "rode it out / used one," with a pattern nudge ("most cravings hit 2–4 PM").
- **Withdrawal symptom matrix** — day-by-day severity grid trending down, plus today's check-in.
- **Insights** — the real Swift-Charts content behind the Phase 1 paywall: pouches/day (down 38%), top trigger, avg craving, cravings-by-time-of-day.
- **Badges** — 15-badge grid, earned vs locked, just-earned hero.
- **Guided breathing** — live animated orb (in/hold/out), tap to pause.
- **Relapse forgiveness** — streak shields + "restart, no judgment," historical stats preserved, warm not shameful.
- **Native edge** — Lock Screen widgets + **Live Activity** countdown, Home Screen widgets + **Dynamic Island** — the structurally-hard-to-copy stuff.

Next if useful: the smart contextual notification mock, the Annual/Lifetime IAP options on the paywall, or wiring these into a tappable flow.

## User

how do i navigate to each screen? where is the bottom nav bar?

## Assistant

Good catch — right now there's no tab bar. What you're looking at is a **design gallery**: every screen laid out as flat labeled frames side by side for review, not a connected app. There's no bottom navigation because I never built one — the screens are standalone mockups.

Let me check the design doc for the intended nav structure, then build a real iOS tab bar and wire the main screens into a navigable prototype.

_[tool: grep]_

_[tool: grep]_

The design doc confirms a glass tab bar but doesn't spell out the tabs. Let me check the screen inventory for the intended information architecture.

_[tool: read_file]_

Right — the doc specifies a **glass tab bar**, but I built the screens as a flat spec gallery, so there's no working navigation. Let me build a proper **interactive prototype**: one phone with a glass tab bar at the bottom that switches between the five core tabs (Home · Schedule · Insights · Health · Settings), with the live Home timer and tap-to-log intact, plus a craving sheet to show modal presentation.

_[tool: update_todos]_

_[tool: dc_write]_

The tab icons use an `innerHTML` attribute that React won't honor — let me render them as proper SVG elements instead.

_[tool: dc_js_str_replace]_

_[tool: dc_js_str_replace]_

_[tool: dc_html_str_replace]_

Let me preview and click through the tabs to confirm navigation works.

_[tool: show_html]_

Home renders with the live timer. Let me click through each tab and the craving sheet to confirm navigation.

_[tool: multi_screenshot]_

Clicks didn't switch — let me debug directly.

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: eval_js]_

Navigation works — clicking Insights swapped the content and lit the active tab teal. My earlier screenshot selector was just wrong. Let me capture each tab properly.

_[tool: multi_screenshot]_

All five tabs navigate correctly. Let me confirm the craving sheet opens, then hand off.

_[tool: eval_js]_

_[tool: eval_js]_

Everything works — the sheet is open in the DOM (`anySheet: true`), all five tabs switch, the live timer ticks, tap-to-log increments, and the Settings dark-mode toggle flips the whole app. My earlier screenshots just cropped above the bottom sheet and tab bar.

_[tool: update_todos]_

_[tool: snip]_

To answer your question directly: the gallery (`Sennel.dc.html`) had no tab bar — it's a flat **spec sheet**, every screen laid side-by-side for review. So I built **`SennelApp.dc.html`** — the actual clickable app.

**Navigate by tapping the glass tab bar at the bottom:**
- **Home** — live streak timer, tap "I just used a pouch" to log, "Feeling a craving?" opens a bottom sheet
- **Schedule** — interval scheduler
- **Insights** — charts ("Log a craving" also opens the sheet)
- **Health** — recovery timeline
- **Settings** — incl. a working **Dark mode** toggle that re-themes the whole app

The active tab lights up teal; the tab bar uses the native system glass the design doc calls for.

_[tool: ready_for_verification]_

Tab bar's at the bottom of **`SennelApp.dc.html`** (now open) — tap between Home · Schedule · Insights · Health · Settings.

Note: the secondary screens from the gallery — onboarding, badges, breathing, relapse forgiveness, paywall, symptom matrix, widgets — aren't wired into this shell yet; they'd present as sheets or sub-screens pushed from these five tabs. Want me to wire any of those in next?

## User

can you export it to figma?

## Assistant

I can export to Figma via the **Send to Canva** skill, which also works for Figma imports. Let me bundle the app and send it.

_[tool: bundle_project]_

The bundler needs a splash thumbnail. Let me add one to SennelApp, then export to Figma.

_[tool: dc_html_str_replace]_

_[tool: bundle_project]_

I have the bundle URL, but I realize you asked for **Figma export**, not a generic web bundle. The Canva/Figma import tool isn't available in this project. 

What I *can* do:
1. **Export as PPTX** — native editable shapes + text (best for bringing into design tools)
2. **Export as PDF** — print-ready, one page per screen
3. Keep the **web bundle** (just created) — works offline, fully interactive

Which would help most? Or if you need native Figma components, I'd need the Figma plugin/API connection set up first.

