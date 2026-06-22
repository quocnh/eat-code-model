# LeetCode Flashcards — Screen Map & Navigation Flow

## App Launch Flow

```
App Start (_AppInitializer)
    │
    ├─ Init DB + Seed problems (TemplateLlmService, ~instant)
    │
    ├─ Check: Is CodeGemma model downloaded?
    │       │
    │       ├─ NO  ──▶  ModelSetupScreen
    │       │               ├─ [Download]  ──▶  GemmaLlmService.init()  ──▶  MainNavigationScreen
    │       │               └─ [Skip]      ──────────────────────────────▶  MainNavigationScreen
    │       │
    │       └─ YES ──▶  GemmaLlmService.init()  ──▶  MainNavigationScreen
```

---

## Main Navigation (Bottom Tabs)

```
MainNavigationScreen  (PageView + BottomNavigationBar)
    │
    ├─ Tab 0  HomeScreen            (Flashcard Practice)
    ├─ Tab 1  CompanyCards          (Company Interview Problems)
    ├─ Tab 2  TrainingScreen        (Techniques Library)
    ├─ Tab 3  BookmarksScreen       (Saved Cards)
    ├─ Tab 4  ProgressScreen        (Stats & Solved Cards)
    └─ Tab 5  SettingsScreen        (Preferences & AI Model)
```

---

## Full Navigation Tree

```
MainNavigationScreen
│
├─ [Tab 0] HomeScreen
│       • Category filter (12 categories)
│       • Flip Q ↔ A on tap
│       • Bookmark, Timer, Stats dialog
│       • Random Card (guaranteed different card)
│       • Mark as Solved
│       • ← No outgoing navigations
│
├─ [Tab 1] CompanyCards
│       • 8 company cards (Google, Amazon, Meta, Microsoft,
│         Apple, Netflix, Uber, Airbnb)
│       • Easy / Medium / Hard counts per company
│       • [Practice] ──▶  CompanyProblemScreen(company)
│       • [Generate More] generates 3 new problems in-place
│
│       CompanyProblemScreen(company)
│           • PageView of company flashcards
│           • Header: difficulty + category + "{Company}-style" badge
│           • Flip Q ↔ A on tap
│           • Bookmark, prev/next navigation
│           • [Generate More] ──▶ adds 3 more (Easy/Medium/Hard)
│           • ← Back to CompanyCards
│
├─ [Tab 2] TrainingScreen
│       • Category filter: All / Fundamental / Tree-Graph /
│         Advanced / Optimization
│       • 15 technique cards with icon, difficulty, complexity
│       • [AI Banner / AppBar icon] ──▶  AiProblemScreen
│       • [Technique card] ──▶  TechniqueDetailScreen(technique)
│
│       TechniqueDetailScreen(technique)
│           Tab 1 — Learn
│               • Full description, key patterns
│               • Step-by-step guide (numbered)
│               • Time & Space complexity badges
│               • Tips + Common Mistakes
│           Tab 2 — Examples
│               • Syntax-highlighted code examples
│               • Explanation text per example
│           Tab 3 — Practice
│               • Related LeetCode problems list
│               • [Generate AI Problem] ──▶  AiProblemScreen(category=technique)
│           ← Back to TrainingScreen
│
│       AiProblemScreen
│           • Category selector (12 options)
│           • Difficulty selector (Easy / Medium / Hard)
│           • AI status: "CodeGemma 2B" or "Template Mode"
│           • [Setup AI] ──▶  ModelSetupScreen (if no model)
│           • [Generate Problem] streams live output
│           • Output: Title, Description, Examples,
│             Constraints, Approach, Code, Complexity
│           • [Save to Flashcards] saves to DB
│           ← Back to caller (TrainingScreen or TechniqueDetailScreen)
│
├─ [Tab 3] BookmarksScreen
│       • List of all bookmarked cards
│       • Tap to expand Q&A + solution
│       • Remove bookmark inline
│       • ← No outgoing navigations
│
├─ [Tab 4] ProgressScreen
│       • Overall stats: total / solved / reviews
│       • Category breakdown with progress bars
│       • Tap category ──▶ solved cards list (inline expand)
│       • ← No outgoing navigations
│
└─ [Tab 5] SettingsScreen
        Sections:
        • Account        — Upgrade dialog
        • Preferences    — Dark Mode toggle, Notifications toggle
        • AI Model       — [CodeGemma tile] ──▶  ModelSetupScreen
        • Data Mgmt      — Reset Progress, Clear Bookmarks (confirmation dialogs)
        • About          — About / Privacy Policy / Help dialogs

        ModelSetupScreen (also reachable from launch flow)
            • Model info card (CodeGemma 2B, ~900 MB, on-device)
            • Requirements (WiFi, storage, Android 10+ / iOS 16+)
            • States:
              ─ Not downloaded: [Download] button + [Skip] button
              ─ Downloading:    progress bar + MB counter
              ─ Downloaded:     ✓ ready + [Delete Model] option
            • onSetupComplete callback ──▶ re-inits GemmaLlmService
            ← Back to caller (splash OR Settings)
```

---

## Screen Reference

| Screen | Class | How to Reach |
|--------|-------|-------------|
| `HomeScreen` | `HomeScreen` | Tab 0 (always visible) |
| `CompanyCards` | `CompanyCards` | Tab 1 |
| `CompanyProblemScreen` | `CompanyProblemScreen` | CompanyCards → Practice |
| `TrainingScreen` | `TrainingScreen` | Tab 2 |
| `TechniqueDetailScreen` | `TechniqueDetailScreen` | TrainingScreen → technique card |
| `AiProblemScreen` | `AiProblemScreen` | TrainingScreen banner, TechniqueDetailScreen Practice tab |
| `BookmarksScreen` | `BookmarksScreen` | Tab 3 |
| `ProgressScreen` | `ProgressScreen` | Tab 4 |
| `SettingsScreen` | `SettingsScreen` | Tab 5 |
| `ModelSetupScreen` | `ModelSetupScreen` | App launch (no model) OR Settings → AI Model |

---

## AI Generation Flow

```
User requests a new problem
        │
        ▼
GemmaLlmService.generate(prompt)
        │
        ├─ Model loaded? ──YES──▶  FlutterGemmaPlugin.instance.getResponse()
        │                               • On-device CodeGemma 2B inference
        │                               • ~5–15 seconds, streams tokens live
        │
        └─ NO ──▶  TemplateLlmService.generate(prompt)
                        • Picks template by category + difficulty
                        • Returns instantly (no model needed)
                        • 36 problems: 12 categories × 3 difficulties
```

---

## Data Flow

```
Database (SQLite via sqflite)
    │
    ├─ flashcards table    ── HomeScreen, BookmarksScreen, CompanyProblemScreen
    ├─ progress table      ── ProgressScreen, HomeScreen (mark solved)
    └─ (in-memory)         ── TrainingData (techniques, static Dart list)

ModelDownloadService
    └─ ~/Documents/codegemma_2b_it_q8_ekv1024.task (~900 MB)
            • Downloaded on demand via HTTP from HuggingFace
            • Loaded into MediaPipe via FlutterGemmaPlugin
```

---

## Techniques Catalogue (Training Tab)

| # | Technique | Category | Difficulty |
|---|-----------|----------|------------|
| 1 | Two Pointers | Fundamental | Beginner |
| 2 | Sliding Window | Fundamental | Beginner |
| 3 | Binary Search | Fundamental | Beginner |
| 4 | Stack | Fundamental | Beginner |
| 5 | Hash Map / Set | Fundamental | Beginner |
| 6 | Linked List | Fundamental | Beginner |
| 7 | BFS / Tree Traversal | Tree/Graph | Intermediate |
| 8 | DFS / Backtracking | Tree/Graph | Intermediate |
| 9 | Dynamic Programming 1D | Advanced | Advanced |
| 10 | Dynamic Programming 2D | Advanced | Advanced |
| 11 | Heap / Priority Queue | Advanced | Intermediate |
| 12 | Greedy | Optimization | Intermediate |
| 13 | Trie (Prefix Tree) | Advanced | Intermediate |
| 14 | Union-Find | Advanced | Intermediate |
| 15 | Monotonic Stack | Advanced | Intermediate |
