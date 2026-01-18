# Ralph Loop Guide: Best Practices for Autonomous AI Development

A comprehensive guide to using the Ralph Loop plugin for effective autonomous development with Claude Code.

---

## 1. What is Ralph Loop?

Ralph Loop is an AI development methodology based on continuous self-referential feedback loops. Named after Ralph Wiggum from The Simpsons, it embodies the philosophy of **persistent iteration despite setbacks**.

As Geoffrey Huntley describes it: *"Ralph is a Bash loop"* - a simple `while true` that repeatedly feeds an AI agent a prompt file, allowing it to iteratively improve its work until completion.

### How It Works

```
You run ONCE:
/ralph-loop "Your task description" --completion-promise "DONE"

Then Claude Code automatically:
1. Works on the task
2. Tries to exit
3. Stop hook blocks exit
4. Stop hook feeds the SAME prompt back
5. Repeat until completion
```

The loop happens **inside your current session** - no external bash loops required. A Stop hook creates the self-referential feedback loop by blocking normal session exit.

### Key Insight: Fresh Context Each Iteration

Standard agent loops suffer from **context accumulation** - every failed attempt stays in conversation history. Ralph Loop solves this by starting each iteration with fresh context. The agent's "memory" persists only through:
- Modified files on disk
- Git history and commits
- The IMPLEMENTATION_PLAN.md file (if using planning mode)

---

## 2. Core Philosophy

### 1. Iteration > Perfection
Don't aim for perfect on first try. Let the loop refine the work. Each iteration sees the previous work and improves upon it.

### 2. Failures Are Data
*"Deterministically bad"* means failures are predictable and informative. When Ralph does something bad, Ralph gets tuned—like a guitar.

### 3. Operator Skill Matters
Success depends heavily on **prompt engineering** and operator competency, not just having a good model.

### 4. Persistence Wins
Keep trying until success. The loop handles retry logic automatically. If you press the model hard enough against its own failures, it will eventually converge on a correct solution.

### 5. Observer Role Shift
You shift from **participant** to **orchestrator**. Observe failure patterns, add guardrails reactively, and tune the prompt based on results.

---

## 3. When to Use Ralph Loop

### Good For

| Use Case | Why It Works |
|----------|--------------|
| **Well-defined tasks with clear success criteria** | Clear exit conditions enable convergence |
| **Tasks requiring iteration and refinement** | Tests, linters, type-checkers provide feedback |
| **Greenfield projects** | No legacy constraints to navigate |
| **Tasks with automatic verification** | Build failures create backpressure |
| **Batch operations** | Migrations, refactoring, documentation |
| **Overnight/walkaway work** | Unattended autonomous execution |

### Not Good For

| Use Case | Why It Fails |
|----------|--------------|
| **Tasks requiring human judgment** | Design decisions need human input |
| **One-shot operations** | No benefit from iteration |
| **Unclear success criteria** | No convergence target |
| **Production debugging** | Requires targeted investigation |
| **Tasks without testable outcomes** | No feedback signal |

---

## 4. Two Modes: HITL and AFK

There are two ways to run Ralph:

| Mode | How It Works | Best For |
|------|--------------|----------|
| **HITL** (human-in-the-loop) | Run once, watch, intervene | Learning, prompt refinement |
| **AFK** (away from keyboard) | Run in a loop with max iterations | Bulk work, low-risk tasks |

### Start With HITL

HITL Ralph resembles pair programming. You and the AI work together, reviewing code as it's created. You can steer, contribute, and share project understanding in real-time.

It's also the best way to learn Ralph. You'll understand what it does, refine your prompt, and build confidence before going hands-off.

**When to use HITL:**
- Learning the Ralph methodology
- Refining and testing new prompts
- Risky architectural decisions
- Tasks requiring human judgment calls

### Graduate to AFK

Once your prompt is solid, AFK Ralph unlocks real leverage. Set it running, do something else, come back when it's done.

**When to use AFK:**
- Well-tested prompts that work reliably
- Lower-risk implementation tasks
- Bulk work like migrations or test coverage
- Overnight/walkaway execution

### The Progression

1. Start with HITL to learn and refine
2. Go AFK once you trust your prompt
3. Review the commits when you return

**Important:** Always cap iterations for AFK work. Infinite loops are dangerous with stochastic systems. Typical ranges:
- Small tasks: 5-10 iterations
- Larger tasks: 30-50 iterations

---

## 5. Commands Reference

### Starting a Loop

```bash
/ralph-loop "<prompt>" --max-iterations <n> --completion-promise "<text>"
```

**Options:**
- `--max-iterations <n>` - Stop after N iterations (safety net, highly recommended)
- `--completion-promise <text>` - Phrase that signals completion (exact match)

**Example:**
```bash
/ralph-loop "Build a REST API for todos. Requirements: CRUD operations, input validation, tests. Output <promise>COMPLETE</promise> when done." --completion-promise "COMPLETE" --max-iterations 50
```

### Canceling a Loop

```bash
/cancel-ralph
```

Removes the state file and allows normal session exit.

### Getting Help

```bash
/ralph-loop:help
```

---

## 6. Prompt Writing Best Practices

### 1. Define Clear Success Criteria

Before you let Ralph run, define what "done" looks like. Instead of specifying each step, describe the desired end state and let the agent figure out how to get there.

**Bad:**
```
Build a todo API and make it good.
```

**Good:**
```markdown
Build a REST API for todos.

When complete:
- All CRUD endpoints working
- Input validation in place
- Tests passing (coverage > 80%)
- README with API docs
- Output: <promise>COMPLETE</promise>
```

**Structured PRD Format (Recommended):**

For complex projects, structure PRD items as JSON with a `passes` field:

```json
{
  "category": "functional",
  "description": "New chat button creates a fresh conversation",
  "steps": [
    "Click the 'New Chat' button",
    "Verify a new conversation is created",
    "Check that chat area shows welcome state"
  ],
  "passes": false
}
```

Ralph marks `passes` to `true` when complete. The PRD becomes both scope definition and progress tracker—a living TODO list rather than a waterfall document.

**Why Explicit Scope Matters:**

You don't _need_ a structured TODO list. But the vaguer the task, the greater the risk:
- Ralph might loop forever, finding endless improvements
- Ralph might take shortcuts, declaring victory early

| What to Specify | Why It Prevents Shortcuts |
|-----------------|---------------------------|
| Files to include | Ralph won't ignore "edge case" files |
| Stop condition | Ralph knows when "complete" actually means complete |
| Edge cases | Ralph won't decide certain things don't count |

**Adjusting PRDs Mid-Flight:**

You can adjust while Ralph is running:
- Already implemented but wrong? Set `passes` back to `false`, add notes, rerun
- Missing a feature? Add a new PRD item even mid-loop

### 2. Use Incremental Goals / Phases

**Bad:**
```
Create a complete e-commerce platform.
```

**Good:**
```markdown
Phase 1: User authentication (JWT, tests)
Phase 2: Product catalog (list/search, tests)
Phase 3: Shopping cart (add/remove, tests)

Output <promise>COMPLETE</promise> when all phases done.
```

### 3. Build in Self-Correction (TDD Cycle)

**Bad:**
```
Write code for feature X.
```

**Good:**
```markdown
Implement feature X following TDD:
1. Write failing tests
2. Implement feature
3. Run tests
4. If any fail, debug and fix
5. Refactor if needed
6. Repeat until all green
7. Output: <promise>COMPLETE</promise>
```

### 4. Always Use Escape Hatches

Always set `--max-iterations` as a safety net:

```bash
/ralph-loop "Try to implement feature X" --max-iterations 20 --completion-promise "COMPLETE"
```

In your prompt, include stuck-handling instructions:
```markdown
If after 15 iterations not complete:
- Document what's blocking progress
- List what was attempted
- Suggest alternative approaches
- Output: <promise>BLOCKED</promise>
```

**Note:** The completion promise uses exact string matching. Rely on `--max-iterations` as your primary safety mechanism.

### 5. Use Specific Language Patterns

Geoffrey Huntley's tested phrases that work:

| Phrase | Purpose |
|--------|---------|
| `"Study X"` (not "read" or "look at") | Implies active engagement via subagents |
| `"Don't assume not implemented"` | Prevents duplicative work |
| `"Using parallel subagents"` | Explicit parallelization signal |
| `"Only 1 subagent for build/tests"` | Creates backpressure bottleneck |
| `"Capture the why"` | Emphasizes documentation |

### 6. Prioritize Risky Tasks First

Ralph chooses its own tasks. Without explicit guidance, it will often pick the first item in the list or whatever seems easiest. This mirrors human behavior—developers love quick wins. But seasoned engineers know you should nail down the hard stuff first.

**Task Priority Order:**

| Task Type | Priority | Why |
|-----------|----------|-----|
| Architectural work | High | Decisions cascade through entire codebase |
| Integration points | High | Reveals incompatibilities early |
| Unknown unknowns (spikes) | High | Better to fail fast than fail late |
| Standard features | Medium | Core implementation work |
| UI polish | Low | Can be parallelized later |
| Quick wins | Low | Easy to slot in anytime |

**Add prioritization to your prompt:**
```markdown
When choosing the next task, prioritize in this order:
1. Architectural decisions and core abstractions
2. Integration points between modules
3. Unknown unknowns and spike work
4. Standard features and implementation
5. Polish, cleanup, and quick wins

Fail fast on risky work. Save easy wins for later.
```

**HITL for Risky, AFK for Safe:**
- Use HITL Ralph for early architectural decisions—the code from these tasks stays forever
- Save AFK Ralph for when the foundation is solid and risky integrations work

### 7. Take Small Steps

The rate at which you can get feedback is your speed limit. Never outrun your headlights.

Humans doing a big refactor might bite off a huge chunk and roll through it. Tests, types, and linting stay red for hours. Breaking work into smaller chunks means tighter feedback loops.

The same applies to Ralph, with an additional constraint: context windows are limited, and LLMs get worse as they fill up. This is called **context rot**—the longer you go, the lower quality the output.

**The Tradeoff:**
- Larger tasks = less frequent feedback
- More context = lower quality code
- Smaller tasks = higher quality but slower progress

**Add step-size guidance to your prompt:**
```markdown
Keep changes small and focused:
- One logical change per commit
- If a task feels too large, break it into subtasks
- Prefer multiple small commits over one large commit
- Run feedback loops after each change, not at the end

Quality over speed. Small steps compound into big progress.
```

For AFK Ralph, keep PRD items small. You want the agent in top form when you're not watching. For HITL, items can be slightly larger since you're there to intervene.

---

## 7. Two-Mode Architecture (Advanced Planning)

For complex projects, use two interchangeable modes:

### Planning Mode
```markdown
# PROMPT_plan.md

Analyze specifications against existing code.
Identify discrepancies.
Create/update prioritized task list in IMPLEMENTATION_PLAN.md.

Plan only. Do NOT implement anything.

When done planning, output: <promise>PLANNED</promise>
```

### Building Mode
```markdown
# PROMPT_build.md

1. Orient via specs
2. Read current IMPLEMENTATION_PLAN.md
3. Select most important task
4. Investigate relevant source code
5. Don't assume not implemented
6. Implement using parallel subagents
7. Run tests (only 1 subagent for build/tests)
8. Update IMPLEMENTATION_PLAN.md
9. Commit

When all tasks complete, output: <promise>COMPLETE</promise>
```

### File Structure

```
project-root/
├── PROMPT_build.md         # Building mode instructions
├── PROMPT_plan.md          # Planning mode instructions
├── IMPLEMENTATION_PLAN.md  # Prioritized task list (persists across iterations)
├── specs/                  # Requirements (one per topic)
└── src/                    # Application source code
```

---

## 8. Steering Ralph: Feedback Mechanisms

### Upstream Steering (Input Tuning)
- Keep specs concise (~5,000 tokens allocated)
- Let existing code patterns guide implementations
- Add guardrails to prompt when patterns fail

### Downstream Steering (Backpressure)
Create feedback loops through:
- **Tests** - Failing tests block completion
- **Type checkers** - Type errors require fixes
- **Linters** - Style violations must be resolved
- **Build failures** - Compilation errors force iteration

**Critical:** The single-subagent-for-build rule creates a bottleneck that forces sequential validation, preventing "optimistic" parallel implementations that skip verification.

---

## 9. Track Progress with progress.txt

Every Ralph loop should emit a `progress.txt` file, committed directly to the repo. This addresses a core challenge: AI agents are like super-smart experts who forget everything between tasks. Each new context window starts fresh. Without a progress file, Ralph must explore the entire repo to understand the current state.

A progress file short-circuits that exploration. Ralph reads it, sees what's done, and jumps straight into the next task.

### What Goes In The Progress File

Keep it simple and concise:

- Tasks completed in this session
- Decisions made and why
- Blockers encountered
- Files changed
- PRD item references
- Architectural decisions
- Notes for the next iteration

### Example Prompt Addition

Add progress tracking to your Ralph prompt:

```markdown
After completing each task, append to progress.txt:
- Task completed and PRD item reference
- Key decisions made and reasoning
- Files changed
- Any blockers or notes for next iteration

Keep entries concise. Sacrifice grammar for the sake of concision.
This file helps future iterations skip exploration.
```

### Why Commits Matter

Ralph should commit after each feature. This gives future iterations:

- A clean `git log` showing what changed
- The ability to `git diff` against previous work
- A rollback point if something breaks

The combination of progress file plus git history gives Ralph full context without burning tokens on exploration.

### Cleanup

Don't keep `progress.txt` forever. Once your sprint is done, delete it. It's session-specific, not permanent documentation.

---

## 10. Context and State Management

### State File Location
```
.claude/ralph-loop.local.md
```

Contains YAML frontmatter:
```yaml
---
active: true
iteration: 1
max_iterations: 50
completion_promise: "COMPLETE"
started_at: "2026-01-17T..."
---

YOUR_PROMPT_TEXT_HERE
```

### What Persists Across Iterations
- Files on disk
- Git history (commits)
- IMPLEMENTATION_PLAN.md
- **progress.txt** (the iteration log)
- The state file itself

### What Resets Each Iteration
- Conversation context
- In-memory state
- Tool call history

This is **by design** - fresh context prevents context rot and accumulation.

---

## 11. When to Regenerate Plans

If using the two-mode architecture, regenerate IMPLEMENTATION_PLAN.md when:

| Symptom | Action |
|---------|--------|
| Ralph implements incorrect items | Regenerate plan |
| Ralph duplicates work | Regenerate plan |
| Plan feels stale or mismatched | Regenerate plan |
| Excessive completed-item clutter | Regenerate plan |
| Significant spec changes | Regenerate plan |
| Confusion about what's finished | Regenerate plan |

Regeneration costs one Planning loop—cheaper than Ralph circling indefinitely.

---

## 12. Safety and Sandboxing

### Best Practices

1. **Always use --max-iterations** - Prevent infinite loops on impossible tasks
2. **Run in isolated environments** - Docker locally or remote sandboxes (Fly Sprites, E2B)
3. **Minimize blast radius** - Ask: "If compromised, what's the damage?"
4. **Review git diffs periodically** - Check what Ralph has done
5. **Start small** - Test with small tasks before overnight runs

### Monitoring Progress

- Check git log for commits
- Read IMPLEMENTATION_PLAN.md for status
- Watch for the completion promise in output
- Use `/cancel-ralph` if things go wrong

---

## 13. Real-World Results

The Ralph technique has demonstrated significant results:

| Achievement | Details |
|-------------|---------|
| **Y Combinator Hackathon** | Generated 6 repositories overnight |
| **Contract Work** | $50K contract completed for $297 in API costs |
| **Programming Language** | Entire language ("cursed") created over 3 months |

---

## 14. Troubleshooting

### Loop Won't Exit

1. Check if completion promise exactly matches (case-sensitive)
2. Verify promise is wrapped in `<promise>TEXT</promise>` tags
3. Use `/cancel-ralph` to force exit
4. Check `.claude/ralph-loop.local.md` state file

### Ralph Keeps Making Same Mistake

1. Add explicit guardrails to prompt
2. Include negative examples ("Don't do X")
3. Add test cases that catch the specific failure
4. Regenerate plan if using planning mode

### Context Seems Corrupted

1. Cancel current loop
2. Check git history for recent changes
3. Regenerate IMPLEMENTATION_PLAN.md
4. Start fresh loop with updated prompt

### Rate Limiting / Cost Concerns

1. Set reasonable --max-iterations
2. Use simpler models for iteration-heavy tasks
3. Break large tasks into smaller loops
4. Monitor API costs during runs

---

## 15. Quick Reference

### Start Loop
```bash
/ralph-loop "<prompt>" --max-iterations 50 --completion-promise "COMPLETE"
```

### Cancel Loop
```bash
/cancel-ralph
```

### Completion Signal (in your work)
```
<promise>COMPLETE</promise>
```

### Essential Prompt Elements
- Clear success criteria
- Phased/incremental goals
- Self-correction instructions (TDD)
- Stuck-handling guidance
- Maximum iteration safety net
- Progress tracking with progress.txt

---

## 16. Alternative Loop Types

Ralph doesn't need to work through a feature backlog. The loop pattern works for many task types. Here are proven alternatives:

### Test Coverage Loop

Point Ralph at your coverage metrics. It finds uncovered lines, writes tests, and iterates until coverage hits your target.

```markdown
@coverage-report.txt
Find uncovered lines in the coverage report.
Write tests for the most critical uncovered code paths.
Run coverage again and update coverage-report.txt.
Target: 80% coverage minimum.
Output <promise>COMPLETE</promise> when target reached.
```

### Linting Loop

Feed Ralph your linting errors. It fixes them one by one, running the linter between iterations.

```markdown
Run: npm run lint
Fix ONE linting error at a time.
Run lint again to verify the fix.
Repeat until no errors remain.
Output <promise>COMPLETE</promise> when clean.
```

### Duplication Loop

Hook Ralph up to a duplicate code detector (like `jscpd`). Ralph identifies clones and refactors into shared utilities.

```markdown
Run jscpd to find duplicate code.
Identify the most impactful duplication.
Refactor into a shared utility.
Run jscpd again to verify reduction.
Output <promise>COMPLETE</promise> when duplication below threshold.
```

### Entropy Loop

Ralph scans for code smells—unused exports, dead code, inconsistent patterns—and cleans them up. Software entropy in reverse.

```markdown
Scan for code smells: unused exports, dead code, inconsistent patterns.
Fix ONE issue per iteration.
Document what you changed in progress.txt.
Output <promise>COMPLETE</promise> when no smells remain.
```

### The Pattern

Any task that can be described as "look at repo, improve something, report findings" fits the Ralph pattern. The loop is the same. Only the prompt changes.

---

## 17. Resources

### Official
- [Ralph Loop Plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) - Official Claude Code plugin

### Origin & Philosophy
- [Ralph Wiggum as a "software engineer"](https://ghuntley.com/ralph/) - Geoffrey Huntley's original article
- [how-to-ralph-wiggum](https://github.com/ghuntley/how-to-ralph-wiggum) - Complete methodology guide
- [11 Tips for Using Ralph](https://www.aihero.dev/11-tips-ralph) - Matt Pocock's comprehensive tips (progress.txt, HITL/AFK modes, task prioritization)

### Community
- [Ralph Orchestrator](https://github.com/mikeyobrien/ralph-orchestrator) - Multi-project Ralph management
- [Vercel Ralph Loop Agent](https://github.com/vercel-labs/ralph-loop-agent) - AI SDK implementation
- [Dev Interrupted Podcast](https://linearb.io/dev-interrupted/podcast/inventing-the-ralph-wiggum-loop) - Geoffrey Huntley interview
- [VentureBeat Article](https://venturebeat.com/technology/how-ralph-wiggum-went-from-the-simpsons-to-the-biggest-name-in-ai-right-now) - Industry coverage
