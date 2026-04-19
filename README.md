# Slumber — Sleep Tracking & AI Optimization App

A premium native iOS sleep tracking app built with SwiftUI, SwiftData, HealthKit, and Claude AI.

---

## Features

- **HealthKit Integration** — Pulls sleep stages (Deep, REM, Light, Awake), heart rate, and HRV from Apple Health. Compatible with Sleep Cycle, AutoSleep, Apple's built-in sleep tracking, and any app that writes to HealthKit.
- **Sleep Score** — Daily score (0–100) computed from duration, quality (stage distribution), consistency (bedtime variance), and recovery (efficiency + HRV).
- **Daily Lifestyle Log** — Log caffeine (time + amount + source), exercise (type/duration/intensity/timing), stress level, alcohol, screen time before bed, supplements, naps, and mood.
- **Correlation Detection** — Detects patterns from 30 days of data: late caffeine vs. deep sleep, alcohol vs. REM%, evening exercise vs. deep sleep, stress vs. efficiency, screen time vs. efficiency.
- **AI Sleep Insights** — Powered by Claude (`claude-sonnet-4-6`). Generates a personalized narrative summary, ranks correlations by impact, and produces specific, data-grounded recommendations (not generic advice).
- **Sleep History** — 7/30/90-day bar charts (colored by score tier), stacked area chart for sleep stages, and detailed per-night drill-down.
- **Onboarding** — 4-step flow: welcome → HealthKit permission → sleep goal + schedule → first sync.
- **Notifications** — Optional bedtime reminder and morning check-in.
- **Deep space dark design** — Near-black navy backgrounds, indigo/purple accents, glowing score rings, spring animations.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI (iOS 17+) |
| Data persistence | SwiftData (`@Model`) |
| Health data | HealthKit framework |
| Charts | Swift Charts |
| AI | Anthropic Claude API (`claude-sonnet-4-6`) |
| Architecture | MVVM + Clean Architecture |
| Dependencies | Swift Package Manager only |

---

## Project Structure

```
SleepApp/
├── SleepApp.swift                    # App entry + SwiftData container
├── ContentView.swift                 # Root TabView + custom tab bar
├── Core/
│   ├── Models/                       # SwiftData @Model classes
│   ├── Services/                     # HealthKit, Claude AI, scoring, correlations
│   ├── Repositories/                 # SwiftData CRUD abstractions
│   └── Utilities/                    # Extensions, constants
├── Features/
│   ├── Onboarding/                   # 4-step onboarding flow
│   ├── Dashboard/                    # Home screen with animated score ring
│   ├── SleepHistory/                 # Charts + per-night detail
│   ├── DailyLog/                     # Lifestyle logging sheet
│   ├── Insights/                     # AI analysis + correlation cards
│   └── Settings/                     # Goals, API key, notifications
└── UI/
    ├── Theme/                        # Colors, typography, spacing
    └── Components/                   # GlassCard, MetricCard, ChipButton, etc.
```

---

## Setup

### Requirements
- Xcode 15.2+
- iOS 17.0+ device (HealthKit requires real device, not simulator)
- Anthropic API key (for AI insights — optional, app works without it)

### Steps

1. **Open in Xcode**
   ```
   open Sleep-App-Final/SleepApp.xcodeproj
   ```
   *(Or create a new Xcode project and drag the `SleepApp/` folder in)*

2. **Set bundle identifier** — Change `com.slumber.app` to your own bundle ID in Xcode's project settings.

3. **Enable HealthKit capability** — In Xcode → Target → Signing & Capabilities → `+ Capability` → HealthKit.

4. **Add Claude API key** — Run the app → Settings → Claude AI → paste your key from [console.anthropic.com](https://console.anthropic.com).

5. **Sync sleep data** — Dashboard → tap "Sync" → approve HealthKit access.

---

## AI Insights

The AI feature uses `claude-sonnet-4-6` to analyze up to 30 nights of sleep data plus lifestyle logs. The prompt asks Claude to:

- Reference specific numbers from your data (not generic population norms)
- Detect correlations with at least 5 paired observations
- Rank recommendations by estimated personal impact
- Flag low-confidence findings when data is insufficient

Insights are cached for 24 hours and auto-regenerate when new sleep sessions are added.

---

## Sleep Score Algorithm

| Component | Weight | Calculation |
|-----------|--------|-------------|
| Duration | 25% | Actual vs. goal ratio; steep penalty below 6h |
| Quality | 35% | Stage distribution vs. ideal (Deep 20%, REM 25%, Light 45%, Awake <10%) |
| Consistency | 20% | Bedtime deviation from 14-day median |
| Recovery | 20% | Sleep efficiency × HRV vs. 7-day baseline |

---

## Design System

- **Backgrounds**: `#0A0E1A` (root) → `#111827` (cards) → `#1C2333` (elevated)
- **Accent**: `#7C3AED` (purple) + `#0D9488` (teal)
- **Score ring**: animated from 0 with `.spring(response: 0.8, dampingFraction: 0.6)`
- **Cards**: `GlassCard` — surface fill + 1pt border stroke + soft shadow
- **Typography**: SF Pro (system font), `.monospacedDigit()` on all numeric displays

---

## Roadmap

- [ ] WidgetKit extension (small widget: last night's score)
- [ ] Apple Watch complications
- [ ] iCloud sync
- [ ] Sleep journal / extended notes
- [ ] Advanced sleep debt tracking
- [ ] "Ask about your sleep" freeform AI chat
