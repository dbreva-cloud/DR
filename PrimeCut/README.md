# Prime Cut — iOS App

A metabolic priming, workout planning, and nutrition timing system for active users.

## Requirements

- Xcode 15+
- iOS 16+
- Swift 5.9+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (to generate the `.xcodeproj`)

## Setup

```bash
# 1. Install XcodeGen
brew install xcodegen

# 2. Navigate to the PrimeCut directory
cd PrimeCut

# 3. Generate the Xcode project
xcodegen generate

# 4. Open in Xcode
open PrimeCut.xcodeproj
```

## Project Structure

```
PrimeCut/
├── App/
│   ├── PrimeCutApp.swift       # @main entry point
│   ├── ContentView.swift       # TabView root
│   └── Info.plist              # HealthKit permissions
│
├── Models/
│   ├── Workout.swift           # WorkoutType enum + Workout model
│   ├── Meal.swift              # Meal, Macros, MealTiming
│   ├── DayPlan.swift           # DayPlan, WeekPlan, ChecklistItem
│   ├── RecoveryInput.swift     # Sleep/stress → recovery score
│   └── ProgressEntry.swift     # Weekly progress data
│
├── Store/
│   ├── PlannerStore.swift      # Central ObservableObject for all state
│   └── SettingsStore.swift     # AppStorage-backed user settings
│
├── Services/
│   ├── HealthKitManager.swift  # Step count + HealthKit auth
│   ├── AutoModeEngine.swift    # Carb/workout adjustment logic
│   ├── NotificationManager.swift
│   └── GroceryExporter.swift  # Weekly grocery list generator
│
├── Views/
│   ├── Dashboard/              # Home screen with step ring + checklist
│   ├── Planner/                # Timeline + AddWorkoutSheet
│   ├── Progress/               # Charts (Swift Charts)
│   └── Settings/               # HealthKit, Auto Mode, preferences
│
└── Utilities/
    ├── Theme.swift             # Color system, typography, spacing
    ├── HapticManager.swift     # Haptic feedback helpers
    └── Extensions.swift        # View modifiers, Date, Animation presets
```

## Features

| Feature | Status |
|---|---|
| Step ring (HealthKit live) | ✅ |
| Daily checklist + haptics | ✅ |
| Workout planner (BJJ / Strength / Rest) | ✅ |
| Auto meal generation (pre/post workout) | ✅ |
| 7-day timeline view | ✅ |
| Auto Mode Engine (carb adjustment) | ✅ |
| Recovery check-in (sleep + stress → score) | ✅ |
| Weekly progress charts (Swift Charts) | ✅ |
| Grocery list generator + share to Notes | ✅ |
| Streak counter with animations | ✅ |
| Notifications (meal reminders) | ✅ |
| Accent color switch (green / gold) | ✅ |

## Design System

- **Background**: `#0B0B0B`
- **Surface**: `#141414`
- **Accent**: `#4CAF72` (muted green) or `#C9A84C` (gold)
- **Text**: `#F5F5F5`
- Style: Apple Fitness × WHOOP — minimal, premium, dark

## Auto Mode Logic

```
Steps low (<50% of goal)  → Reduce carbs
BJJ session               → Increase carbs (+25%)
Strength session          → Maintain / slight reduce
Poor recovery (score <35) → Reduce carbs
High step output (>130%)  → Increase carbs
```
