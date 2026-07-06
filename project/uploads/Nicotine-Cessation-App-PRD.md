# Sennel — Nicotine Pouch Cessation App
## Product Requirements Document (Native iOS / SwiftUI)

**Platform:** iOS only (native Swift/SwiftUI, iOS 26+)
**Developer:** Solo indie dev, AI-assisted (Claude)
**Source research:** `pouchless-market-research.md`, updated with live App Store + Reddit checks (June 2026)
**Status:** Draft v1

---

## 1. Overview

A nicotine pouch (Zyn/Velo/On!/Rogue/etc.) cessation and reduction tracker, positioned as a premium, native-feeling wellness app — not another dark-mode "tech bro" tracker clone. The wedge is craft: nobody in this category has shipped something that looks and feels like a genuine iOS 26 app (Liquid Glass, fluid animations, real haptics, real accessibility). The wedge is **not** cross-platform reach — this is iOS-only by design, trading Android TAM for execution quality.

---

## 2. Problem & Opportunity

Nicotine pouches have replaced cigarettes/vapes for millions of users who didn't expect to develop a real addiction. Generic quit-smoking apps don't model pouches (no per-pouch logging, no tapering logic suited to pouch use patterns). A pouch-specific cessation app category emerged in 2024–2025 and is still in a land-grab phase — no app has a real moat yet.

**Market sizing (from research, treat as directional, not precise):**
- Global nicotine pouch market: ~$8.6B (2025) → ~$56.7B (2035 forecast)
- Tier 1 (US/UK/CA/AU) addressable app users: ~700K–1.2M, growing 25–35%/yr
- FDA authorization of 20 Zyn products (Jan 2025) legitimized and accelerated mainstream adoption

---

## 3. Competitive Reality Check (updated)

The original research underestimated how funded/crowded this space actually is. Verified during this PRD's research pass:

- **"Pouchless" (Jonathan Kopp)** — the named clone target — is not a peer solo-dev app. It's one of three apps (alongside Quit Vaping, Quit Drinking) run by **Quitly**, a funded telehealth platform that has surpassed **3 million combined downloads**. This is a company with real distribution, not a fellow indie.
- **Snusless** (the "growing forest" app) is built by **Sober Bar**, a wellness company — also not solo.
- The category has at least 6 more live competitors not in the original table: Pouch Quit, Pouchly, Quitty, NOBUZZ, QuitNicPouches, UpperDecky — plus two more unrelated apps already named "Pouchless"/"PouchLess." New entrants are landing roughly monthly.
- **r/QuittingZyn is real and active**, with thousands of members actively seeking app recommendations — confirmed as a legitimate distribution channel.

**Implication:** treat the "0.5–1% market share / $3–5K MRR in 12–18 months" figure from the original research as a stretch goal, not a base case. A more grounded primary target is **$1–3K MRR within 12 months**, driven by a defensible craft/design moat rather than feature parity or first-mover advantage (neither of which is realistically available now).

---

## 4. Goals & Success Metrics

| Metric | Target |
|---|---|
| App Store submission (Phase 1) | 5–7 weeks from kickoff |
| First paying user | Within 1–2 weeks of launch |
| $100 MRR | 30–60 days post-launch |
| $1K MRR | 4–8 months post-launch |
| $1–3K MRR (primary goal) | 12 months |
| $3–5K MRR (stretch goal) | 18 months |
| Free → paid conversion | 4–8% (freemium health app benchmark) |

---

## 5. Target User

- Adults 21–40 (category skews male but rising female usage), daily-to-multiple-times-daily pouch users
- Heavy users: 1+ can/day, spending $150–300/month on pouches
- Motivated to quit but **subscription-fatigued** — resentful of paying to save money on an addiction
- Values identity/pride in quitting ("I'm someone who controls myself now") — wants an app that reflects that, not a clinical or shame-based one

---

## 6. Differentiation Strategy

Three pillars, in priority order:

1. **Native craft.** Real Liquid Glass, real motion, real haptics, real accessibility. This is the primary moat — Flutter/cross-platform competitors structurally cannot replicate this exactly.
2. **The interval scheduler.** Explicitly requested in Pouch Buddy reviews, built by nobody. Lead with this in the App Store description and release notes.
3. **Generous free tier + soft paywall.** The #1 complaint across every competitor is "why do I have to pay to quit an addiction." Never wall off the core loop.

---

## 7. Feature Breakdown by Phase

Tags used below:
- 🔓 **GAP** — a feature competitors don't have, or have built poorly. Named competitor(s) referenced where relevant.
- ⚙️ **NATIVE EDGE** — realistically only achievable well in native Swift, not Flutter/cross-platform.

### Phase 1 — MVP: Core Loop + Headline Differentiator
**Target: 5–7 weeks.** Goal: ship, validate monetization, lead with the one feature nobody has.

| Feature | Detail |
|---|---|
| 2-question onboarding | Last pouch time + daily goal only. Everything else deferred to a secondary flow post-streak-start. 🔓 **GAP** — nearly every competitor (QuitNic, Pouch Buddy, Snusless) front-loads a long survey before showing value. |
| Live streak timer | Running to the second from the first screen. |
| One-tap pouch logging | + haptic feedback on log (physical affirmation). 🔓 **GAP** — zero competitors use haptics meaningfully. |
| Money saved calculator | Real-time, ticking up. |
| Interval Scheduler (Lite) | Distribute daily pouch allowance across waking hours; local notification: "Next pouch eligible at 4:30 PM." 🔓 **GAP** — explicitly requested in Pouch Buddy reviews; **nobody in the category has shipped this.** This is the headline differentiator — ship it in Phase 1, not later, and lead with it in marketing. |
| Health timeline | 5–7 milestones (20 min, 1 hr, 1 day, 3 days, 1 week, 1 month, 3 months). |
| Daily limit + progress bar | Simple visual, no charts yet. |
| Progressive color theming | UI shifts cool/grey (Day 0) → vibrant teal/emerald (Day 30+). 🔓 **GAP** — no competitor uses color to represent progress; most default to static dark-mode-neon-green. |
| Soft paywall | Free tier = full core loop (streak, count, savings, basic timeline) forever. Advanced screens show blurred previews, never a hard block. 🔓 **GAP** — Pouch Buddy/Snusless/QuitNic/Pouch Count all hard-paywall, the single biggest source of 1–2★ reviews in the category. |
| Local persistence | SwiftData, with autosave on every log — competitors lose streak data on update, a category-wide complaint that's devastating since the streak *is* the product. |
| Baseline accessibility | Dynamic Type + VoiceOver labels on streak timer and log button, built in from day one (cheap now, expensive to retrofit). 🔓 **GAP** — zero competitors mention VoiceOver support. |
| Monetization | Single SKU: $3.99/month. No annual/lifetime yet — avoid SKU clutter at launch (Quit Snus's mistake). |
| Dark + light mode | Both, with the progressive-color system applied to both. |

**Explicitly deferred to later phases:** AI coaching, community/buddy system, advanced charts, badges, widgets, Watch app, barcode scanner, NRT tracking, cotinine graph, gum health, meditation library, craving/trigger logger, withdrawal symptom log.

---

### Phase 2 — Competitive Parity + Native-Exclusive Polish
**Target: 4–6 weeks post-launch.** Goal: match table-stakes features, ship things that are structurally hard to copy outside native iOS.

| Feature | Detail |
|---|---|
| Craving/trigger logger | With pattern visualization (time of day, activity). |
| Withdrawal symptom log | Day-by-day matrix: irritability, brain fog, insomnia, anxiety. 🔓 **GAP** — Quitzyn comes closest but has no full matrix; nobody owns this. |
| Weekly/monthly charts | Built with Swift Charts. |
| Achievement/badge system | 10–15 badges, designed with intention (most competitors' badges feel like an afterthought per user complaints — don't repeat that). |
| Guided breathing | 3–4 exercises, built natively, no third-party SDK dependency. |
| Relapse forgiveness | Streak shields (3/month) + "restart without judgment" that preserves historical data while resetting the streak. 🔓 **GAP** — only Tyn has this; most competitors make relapse logging shameful or hidden. |
| Home Screen + Lock Screen widgets | WidgetKit. 🔓 **GAP** — only ~30% of competitors support Lock Screen widgets. |
| Live Activity / Dynamic Island | Active countdown for the interval scheduler ("next pouch in 1h 12m") shown on the lock screen / Dynamic Island in real time. ⚙️ **NATIVE EDGE** — not realistically replicable in Flutter; literally nobody in this niche has this. |
| Smart contextual notifications | "It's been 4 hours — you're eligible for your 3rd pouch. Still want it?" — tied to the user's own tapering plan, not generic check-in pings. |
| Annual + Lifetime IAP | $24.99/yr, $49.99 lifetime, via StoreKit2. Positions below Pouch Count ($39.99/yr) and above QuitNic ($30/yr) with a meaningfully better free tier. |
| Full accessibility pass | VoiceOver + Dynamic Type across all Phase 2 screens, not just core loop. |

---

### Phase 3 — Moat Features (Build Only If Phase 1/2 Show Traction)
**Target: 2–3 months post-launch.** Goal: expensive-to-copy features that drive word-of-mouth and justify premium pricing. Gate this phase on actual revenue/retention signal from Phase 2 — don't build speculatively.

| Feature | Detail |
|---|---|
| AI quit coach | Claude API, contextual in-app suggestions based on logged patterns. Table stakes by 2026 per the research (QuitNic, QuitZyn already have basic versions) — but most are generic; a coach that actually reads the user's own craving/trigger/symptom data is still a gap. |
| Cotinine clearance graph | "How much nicotine is still in your body, and when does it clear?" 🔓 **GAP** — only Snusless ("Geek Mode") has this. |
| Gum health recovery timeline | 🔓 **GAP** — only Tyn has this; it's the #1 physical concern pouch users report. |
| NRT tracking | Track gum/patches/lozenges as a step-down tool, inside the same app. 🔓 **GAP** — nobody integrates this; users currently have to use a second app. |
| Buddy system, executed better | Live progress sharing, shared milestones, push notification when your buddy hits a streak. Pouchless has a basic version of this — out-execute it, don't just match it. |
| Community forum / milestone feed | In-app, lightweight. |
| Can/tin barcode scanner | Quick brand/strength logging. Only Tyn has this. |
| Apple Watch companion | Quick-log from the wrist. ⚙️ **NATIVE EDGE** + 🔓 **GAP** — nobody in the category has shipped this; realistic for you specifically because watchOS shares your SwiftUI codebase. |
| App Intents / Siri / Action Button | "Log a pouch" via voice, Shortcuts, or the iPhone Action Button. ⚙️ **NATIVE EDGE**. |
| Referral program | "Quit with a friend — share the app, get 1 month premium free." |
| Selfie-a-day progress | Optional, low priority — quirky/potentially viral, Pouchless has a basic version. |

---

## 8. Design Direction

**Visual identity — "Clean-Recovery," not "danger/warning."** Light, calm palette anchored in deep teal/emerald, soft white backgrounds — opposite of the dark-mode-neon-green look half the competitors default to (reads as "2019 fitness app," not "2026 premium wellness tool"). Color shifts progressively with streak length: cool/grey on Day 0, vibrant/alive by Day 30.

**Typography.** Rounded sans-serif for UI (system SF Pro with generous weight variation), a distinct display face for the big numbers (days clean, money saved) — these should feel proud, not clinical.

**Layout.** Card-based, calm, one primary action per screen, generous whitespace. Use `.glassEffect()` / `GlassEffectContainer` (iOS 26) for hero elements — the streak card and money-saved card specifically, since those are what a screenshot/review will show first.

**First 30 seconds (cold launch).** Streak clock running, "$0.00 saved since you started" ticking, one button: "I just used a pouch." No subscription screen, no onboarding wall. This is the single most important screen in the app — it's the proof-of-value moment competitors bury under onboarding surveys.

**Accessibility wins competitors miss (build in from Phase 1):**
- Dynamic Type support throughout
- VoiceOver-compatible streak timer and craving log
- Haptic feedback on every pouch log
- Lock screen widget (Phase 2)

---

## 9. Monetization

| Tier | Includes | Price | Phase |
|---|---|---|---|
| Free forever | Streak timer, daily counter, money saved, basic timeline, interval scheduler (lite), dark mode | $0 | 1 |
| Premium monthly | Full analytics/history, craving/trigger analysis, withdrawal log, breathing exercises, widgets, badges, no ads | $3.99/mo | 1→2 |
| Premium annual | Same as monthly, ~40% discount | $24.99/yr | 2 |
| Lifetime | Everything, one-time | $49.99 | 2 |

No ads at any tier — this is a health/wellness category; ads undermine credibility. Lifetime buyers tend to become vocal evangelists — worth the margin trade-off.

---

## 10. Technical Architecture & Dev Workflow

- **UI:** SwiftUI, targeting iOS 26+, using native Liquid Glass APIs for hero components
- **Persistence:** SwiftData (not CoreData) — less boilerplate, pairs cleanly with `@Observable`
- **Widgets/Live Activity:** WidgetKit + ActivityKit for Dynamic Island countdown
- **IAP:** StoreKit2
- **Future Watch target (Phase 3):** shared SwiftUI/SwiftData code where possible
- **Future Siri/Shortcuts (Phase 3):** App Intents framework
- **Charts (Phase 2):** Swift Charts
- **Dev workflow:** VS Code + Claude for primary editing, **SweetPad** for build/run/debug on simulator without leaving VS Code, **Xcode** kept open for SwiftUI Previews/Canvas (visual polish), signing/capabilities, and final archive/App Store submission. **InjectionIII + the Inject package** for true hot reload of the running app (state-preserving), since Xcode's native preview doesn't fully replace that workflow.
- **Health/wellness App Store review:** word the app description and metadata carefully as a cessation/wellness tool, not anything that could read as promoting nicotine products — this category has triggered extra App Store health/safety review in the past.

---

## 11. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Category saturation — new entrants landing monthly | Ship Phase 1 fast (5–7 wks), lead with the interval scheduler in marketing immediately |
| Named target app is backed by a funded company (Quitly), not a peer | Don't benchmark success against "beating Pouchless" — benchmark against carving out a defensible craft niche |
| Native iOS learning curve eats the speed advantage | Phase 1 scope is deliberately minimal; cut anything not in the table above, no exceptions |
| Streak/data loss (category-wide complaint) | SwiftData autosave on every write; consider iCloud sync once core loop is stable |
| App Store health-content review flags | Wellness/cessation framing throughout copy and metadata, age rating set correctly |
| Building Phase 3 features nobody asked for | Hard gate: only start Phase 3 once Phase 2 shows real retention/revenue signal |

---

## 12. Naming — Decided: Sennel

Chosen over Taper, Wean, Ebb, Lighten, LightN, Mend, Halcyon, Vael, Verolyn, and Tendaro — all of which had existing same-category or same-name collisions on the App Store or as active brands. Sennel turned up no App Store app and no same-category overlap; the only hits were a small unrelated production company and a nonprofit with negligible reach. Pouze remains the backup (zero hits anywhere, but pronunciation is ambiguous for a US/UK/CA/AU audience).

**Before locking this in, still do (none of this was done via search — these are the only 100% reliable checks):**
- [ ] Test "Sennel" in App Store Connect → My Apps → "+" → New App (free, instant yes/no on the exact-name registration block)
- [ ] Check sennel.com / sennel.app domain availability
- [ ] Check Instagram/TikTok handle availability
- [ ] Run a US trademark search at tmsearch.uspto.gov for software/health classes

**App Store keyword targets (from research, to carry the ASO load since "Sennel" itself isn't a category keyword):** "quit nicotine pouches," "zyn tracker," "pouch quit," "nicotine pouch tracker," "quit zyn app"

---

## 13. Open Questions

- Bundle ID (pending the App Store Connect name test for "Sennel")
- iCloud sync in Phase 1 or deferred to Phase 2?
- Exact wording/age rating strategy for App Store health review
- Whether the AI quit coach (Phase 3) uses the Claude API directly or routes through your existing automation stack
