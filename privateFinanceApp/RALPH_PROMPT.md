# Ralph Prompt: GhostVault PRD Execution

Generated: 2026-01-17
Type: PRD Execution
Max Iterations: 50
Completion Promise: MVP_COMPLETE

---

## Purpose

Execute the GhostVault iOS MVP implementation plan, completing all 31 tasks across 10 phases (P0-P9) using TDD methodology with continuous build/test validation.

## Prerequisites

- [ ] Xcode project exists at `GhostVault/`
- [ ] iOS Simulator available: `xcrun simctl list devices | grep iPhone`
- [ ] Build succeeds: `xcodebuild build -scheme GhostVault -destination 'platform=iOS Simulator,name=iPhone 16'`

---

## Prompt

```
@IMPLEMENTATION_PLAN.md @progress.txt

Execute the GhostVault implementation plan until all 31 tasks are complete.

<context>
This is an iOS app built with SwiftUI and SwiftData. The app integrates with SimpleFIN for financial data aggregation. All code changes must pass Xcode build and tests.
</context>

<each_iteration>
1. Read IMPLEMENTATION_PLAN.md to understand all tasks and phases
2. Read progress.txt to see completed work and current status
3. If ALL tasks have "passes": true in progress tracking, output completion promise
4. Choose the NEXT incomplete task following phase order:
   - Complete all P0 tasks before P1
   - Complete all P1 tasks before P2
   - And so on through P9
   - Within a phase, complete tasks in order (T1, T2, T3...)
5. Mark current task as "In Progress" in progress.txt
6. Implement using TDD approach:
   a. Write failing unit test(s) FIRST (when acceptance criteria includes tests)
   b. Implement the minimum code to pass
   c. Refactor if needed while keeping tests green
7. Run feedback loops:
   - Build: xcodebuild build -scheme GhostVault -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20
   - Tests: xcodebuild test -scheme GhostVault -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30
8. If build or tests fail:
   - Read error output carefully
   - Fix the issue
   - Re-run until passing
9. Verify SwiftUI previews compile (for UI tasks)
10. Update progress.txt:
    - Move task from "In Progress" to "Completed Tasks"
    - Note files created/modified
    - Note any decisions made
11. Update IMPLEMENTATION_PLAN.md: set "passes": true for the task
12. Commit changes: git add -A && git commit -m '[phase]: [task description]'

ONLY WORK ON ONE TASK PER ITERATION.
</each_iteration>

<task_priority_within_phase>
When multiple tasks remain in a phase:
1. Foundation/infrastructure tasks first
2. Model/data layer before UI
3. Core functionality before polish
4. Tests before implementation when doing TDD
</task_priority_within_phase>

<build_commands>
# Quick build check
xcodebuild build -scheme GhostVault -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20

# Run tests
xcodebuild test -scheme GhostVault -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30

# List test failures only
xcodebuild test -scheme GhostVault -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -A 5 "failed\|error:"
</build_commands>

<progress_tracking>
Update progress.txt after each task:

## Completed Tasks

### [TASK_ID]: [Task Name]
- Status: COMPLETE
- Files created: [list]
- Files modified: [list]
- Tests added: [count]
- Notes: [any decisions or observations]

---

## In Progress

### [TASK_ID]: [Task Name]
- Started: [timestamp]
- Current step: [what you're working on]

---

## Current Status
- **Phase:** [current phase]
- **Current Task:** [task ID]
- **Last Updated:** [timestamp]
</progress_tracking>

<phase_completion>
When completing a phase:
1. Verify ALL tasks in phase have "passes": true
2. Run full test suite one more time
3. Add phase completion note to progress.txt:
   "## Phase [X] Complete - [timestamp]"
4. Commit: 'milestone: complete phase [X] - [phase name]'
</phase_completion>

<file_organization>
Follow the project structure from IMPLEMENTATION_PLAN.md:
- Views/ - All SwiftUI views organized by feature
- Models/ - SwiftData models
- Services/ - Business logic and API services
- GhostVaultTests/ - Unit tests mirror main structure
</file_organization>

<swift_conventions>
- Use SwiftUI for all UI
- Use SwiftData for persistence (not CoreData)
- Use async/await for asynchronous code
- Use Swift Charts for visualizations
- Follow Apple Human Interface Guidelines
- Use SF Symbols for icons
</swift_conventions>

<stuck_handling>
If stuck on a task for more than 5 sub-iterations:
1. Document the blocker in progress.txt under "Blocked Tasks"
2. List what was attempted
3. Note any error messages or issues
4. If it's a dependency issue, check if prerequisite tasks are truly complete
5. If architectural blocker, document proposed solutions
6. Move to next task if possible, or output: <promise>BLOCKED</promise>
</stuck_handling>

<completion>
When all 31 tasks have "passes": true:
1. Run final full build and test suite
2. Update progress.txt with MVP completion summary
3. List any known issues or future improvements
4. Output: <promise>MVP_COMPLETE</promise>
</completion>
```

---

## Run Command

Reference this file directly:
```bash
/ralph-loop "@RALPH_PROMPT.md" --max-iterations 50 --completion-promise "MVP_COMPLETE"
```

Or for a single phase at a time (recommended for HITL mode):
```bash
# Phase 0: Test Infrastructure
/ralph-loop "@RALPH_PROMPT.md Focus only on Phase 0 tasks" --max-iterations 10 --completion-promise "P0_COMPLETE"

# Phase 1: Onboarding
/ralph-loop "@RALPH_PROMPT.md Focus only on Phase 1 tasks" --max-iterations 15 --completion-promise "P1_COMPLETE"

# Phase 2: Dashboard
/ralph-loop "@RALPH_PROMPT.md Focus only on Phase 2 tasks" --max-iterations 12 --completion-promise "P2_COMPLETE"
```

---

## Progress Files

This prompt will create/update:
- `progress.txt` - Iteration-by-iteration progress log (already exists)
- Updates `IMPLEMENTATION_PLAN.md` - Sets "passes": true for completed tasks

---

## Task Summary by Phase

| Phase | Tasks | Description | Est. Iterations |
|-------|-------|-------------|-----------------|
| P0 | 3 | Test infrastructure | 5-8 |
| P1 | 5 | Onboarding flow | 10-15 |
| P2 | 4 | Dashboard (core) | 8-12 |
| P3 | 3 | Account management | 6-9 |
| P4 | 3 | Transaction view | 6-9 |
| P5 | 3 | Classification engine | 6-9 |
| P6 | 3 | Trend charts | 6-9 |
| P7 | 3 | Spending categories | 6-9 |
| P8 | 2 | Settings | 4-6 |
| P9 | 2 | Error states | 4-6 |

**Total: 31 tasks across 10 phases**

---

## Recommended Execution Strategy

### Option 1: Full AFK Run (Experienced)
```bash
/ralph-loop "@RALPH_PROMPT.md" --max-iterations 50 --completion-promise "MVP_COMPLETE"
```
Let it run through all phases autonomously. Check progress.txt periodically.

### Option 2: Phase-by-Phase HITL (Recommended)
Run each phase separately, review between phases:
```bash
# Start with test infrastructure
/ralph-loop "@RALPH_PROMPT.md Complete Phase 0 only" --max-iterations 10 --completion-promise "P0_COMPLETE"

# Review, then continue to onboarding
/ralph-loop "@RALPH_PROMPT.md Complete Phase 1 only" --max-iterations 15 --completion-promise "P1_COMPLETE"

# Continue through phases...
```

### Option 3: Task-by-Task (Maximum Control)
```bash
/ralph-loop "@RALPH_PROMPT.md Complete only task P0-T1" --max-iterations 5 --completion-promise "TASK_COMPLETE"
```

---

## Recovery from Interruption

If the loop is interrupted, simply restart with the same command. The prompt reads progress.txt to determine where to resume.

```bash
# Check current state
cat progress.txt | head -30

# Resume execution
/ralph-loop "@RALPH_PROMPT.md" --max-iterations 50 --completion-promise "MVP_COMPLETE"
```
