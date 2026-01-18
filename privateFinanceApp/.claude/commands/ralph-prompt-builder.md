---
description: Build Ralph loop prompts for autonomous AI development. Use when user wants to create a Ralph prompt for tasks like executing a PRD/plan, code hygiene (duplication, complexity, type safety, test coverage, linting, dead code, dependencies, naming, architecture), or custom autonomous loops.
user_invocable: true
arguments: "[task description or hygiene type]"
---

# Ralph Prompt Builder

You are a Ralph prompt builder. Your job is to create effective Ralph loop prompts based on the user's request and **write them to a file**.

## Output Location

**IMPORTANT:** Always write the generated prompt to a file in the project directory:

- **Primary location:** `RALPH_PROMPT.md` in the project root
- **Alternative:** If user specifies a different filename, use that

The file should contain:
1. A header comment explaining what the prompt does
2. The full prompt text (ready to copy into `/ralph-loop`)
3. The recommended command to run it

Example file structure:
```markdown
# Ralph Prompt: [Task Description]

Generated: [date]
Type: [hygiene type or custom]
Max Iterations: [N]
Completion Promise: [PROMISE]

---

## Prompt

[THE FULL PROMPT TEXT HERE]

---

## Run Command

\`\`\`bash
/ralph-loop "[prompt summary]" --max-iterations [N] --completion-promise "[PROMISE]"
\`\`\`

Or reference this file:
\`\`\`bash
/ralph-loop "@RALPH_PROMPT.md" --max-iterations [N] --completion-promise "[PROMISE]"
\`\`\`
```

## Understanding the Request

First, determine what type of Ralph prompt the user needs:

1. **PRD/Plan Execution** - Execute a product requirements document or implementation plan
2. **Code Hygiene Loop** - One of the 9 hygiene categories (see below)
3. **Custom Task Loop** - Any other autonomous task

Ask clarifying questions if needed:
- What language/framework is the codebase? (TypeScript, Swift, Python, etc.)
- What's the target/threshold? (e.g., 80% coverage, 0 lint errors)
- What test/build commands should be used?
- Are there specific files or directories to focus on or exclude?

## Code Hygiene Loop Types

If the user wants a code hygiene loop, identify which category:

| Type | Keywords | Promise |
|------|----------|---------|
| Duplication | DRY, copy-paste, jscpd, duplicates | DEDUPED |
| Complexity | arrow code, nesting, long functions, cyclomatic | SIMPLIFIED |
| Naming | vague names, unclear intent, readability | CLARIFIED |
| Dead Code | unused, entropy, stale, unreachable | CLEAN |
| Dependencies | outdated, vulnerabilities, circular deps | HEALTHY |
| Type Safety | any types, force unwrap, missing types | TYPED |
| Architecture | god objects, coupling, large files | DECOUPLED |
| Test Coverage | untested, coverage percentage | COVERED |
| Linting | style, eslint, swiftlint, formatting | LINTED |

## Prompt Structure (Required Elements)

Every Ralph prompt MUST include:

### 1. Detection Phase
```markdown
<detection>
Run: [command to detect issues]
Parse: [how to read results]
Count: [how to measure progress]
</detection>
```

### 2. Each Iteration Phase
```markdown
<each_iteration>
1. Run detection command
2. If 0 issues, output completion promise
3. Pick ONE item to address (largest impact or most instances)
4. Apply fix/refactoring
5. Run tests: [test command]
6. Update [progress-file].txt
7. Commit: '[type]: [description]'

ONLY ADDRESS ONE [ITEM] PER ITERATION.
</each_iteration>
```

### 3. Progress Tracking
```markdown
<progress_tracking>
Update [name]-progress.txt:
## Iteration N
- Issues found: X
- Fixed: [description]
- Tests: PASS/FAIL
- Remaining: Y
</progress_tracking>
```

### 4. Completion Condition
```markdown
<completion>
When [condition met]: <promise>PROMISE_TEXT</promise>
After [N] iterations if stuck: document remaining and <promise>PROMISE_TEXT</promise>
</completion>
```

## Best Practices to Include

Always incorporate these in your prompts:

### Task Prioritization
```markdown
When choosing the next task, prioritize:
1. Highest impact items first
2. Items with most instances/occurrences
3. Items blocking other work
```

### Small Steps Guidance
```markdown
ONLY ADDRESS ONE [ITEM] PER ITERATION.
Quality over speed. Small steps compound into big progress.
```

### HITL vs AFK Awareness
- For risky/architectural changes: recommend HITL mode with lower max-iterations
- For routine hygiene: AFK mode with higher max-iterations

### Recommended Max Iterations by Type
| Type | Max Iterations |
|------|----------------|
| Duplication | 20 |
| Complexity | 25 |
| Naming | 20 |
| Dead Code | 30 |
| Dependencies | 25 |
| Type Safety | 25 |
| Architecture | 15 |
| Test Coverage | 25 |
| Linting | 20 |
| PRD Execution | 50 |

## Output Format

Generate the prompt in this format:

```bash
/ralph-loop "[full prompt text]" --max-iterations [N] --completion-promise "[PROMISE]"
```

---

## Code Hygiene Loop Templates

Use these templates as starting points, customizing for the user's specific codebase:

### 1. Duplication Loop (DRY)

```markdown
Eliminate code duplication until jscpd reports no clones above threshold.

<detection>
Run: jscpd ./src --min-lines 10 --min-tokens 50 --reporters json,console --output ./jscpd-report --ignore '**/node_modules/**,**/*.test.*'
Parse: ./jscpd-report/jscpd-report.json
</detection>

<each_iteration>
1. Run detection command
2. If 0 clones, output completion promise
3. Pick ONE clone (largest or most instances)
4. Refactoring strategies:
   - Extract to shared utility function
   - Create protocol/interface with default implementation
   - Parameterize differences into single flexible function
5. Update all call sites
6. Run tests: [TEST_COMMAND]
7. Update dedup-progress.txt
8. Commit: 'refactor: extract [name] to reduce duplication'

ONLY ADDRESS ONE CLONE PER ITERATION.
</each_iteration>

<progress_tracking>
Update dedup-progress.txt:
## Iteration N
- Clones: X found, Y lines duplicated
- Fixed: [fileA:lines] + [fileB:lines] → [new utility]
- Tests: PASS/FAIL
- Remaining: Z clones
</progress_tracking>

<completion>
When 0 clones above threshold: <promise>DEDUPED</promise>
After 15 iterations with intentional remaining: document and <promise>DEDUPED</promise>
</completion>
```

### 2. Complexity Loop

```markdown
Reduce code complexity until no functions exceed complexity threshold.

<detection>
Run: npx eslint . --format json -o complexity-report.json --rule 'complexity: [error, 10]' --rule 'max-depth: [error, 4]' --rule 'max-lines-per-function: [error, 50]'
</detection>

<each_iteration>
1. Run complexity detection
2. Parse report for violations
3. If 0 violations, output completion promise
4. Pick ONE function/file with highest complexity
5. Apply refactoring:
   - FOR ARROW CODE: Use early returns/guard clauses to flatten
   - FOR LONG FUNCTIONS: Extract each responsibility to separate function
   - FOR GOD FILES: Extract cohesive groups to separate modules
6. Verify complexity reduced by re-running detection
7. Run tests: [TEST_COMMAND]
8. Update complexity-progress.txt
9. Commit: 'refactor: reduce complexity in [function/file]'

ONLY ADDRESS ONE FUNCTION/FILE PER ITERATION.
</each_iteration>

<progress_tracking>
Update complexity-progress.txt:
## Iteration N
- Violations found: X
- Fixed: [function/file name]
- Original complexity: Y → New: Z
- Technique: [guard clauses / extraction / decomposition]
- Tests: PASS/FAIL
</progress_tracking>

<completion>
When 0 complexity violations: <promise>SIMPLIFIED</promise>
After 20 iterations: document remaining and <promise>SIMPLIFIED</promise>
</completion>
```

### 3. Type Safety Loop

```markdown
Improve type safety by eliminating 'any' types and adding proper type annotations.

<detection>
Run: npx eslint . --format json -o type-report.json --rule '@typescript-eslint/no-explicit-any: error' --rule '@typescript-eslint/explicit-function-return-type: warn'
Quick count: grep -rn ': any' --include='*.ts' ./src | wc -l
</detection>

<each_iteration>
1. Run detection
2. Parse report for violations
3. If 0 violations, output completion promise
4. Pick ONE file with most type issues
5. For each 'any' type:
   - Trace where the value comes from
   - If API response: create interface matching the shape
   - If complex union: use discriminated union or generics
   - If truly dynamic: use 'unknown' with type guards
6. Run type checker: npx tsc --noEmit
7. Run tests: [TEST_COMMAND]
8. Update types-progress.txt
9. Commit: 'types: add type safety to [file]'

ONLY ADDRESS ONE FILE PER ITERATION.
</each_iteration>

<progress_tracking>
Update types-progress.txt:
## Iteration N
- File: [filename]
- Issues fixed: X any types, Y missing returns
- New types created: [interface/type names]
- Type check: PASS/FAIL
- Tests: PASS/FAIL
</progress_tracking>

<completion>
When 0 'any' types (or all documented as intentional): <promise>TYPED</promise>
After 20 iterations: document remaining and <promise>TYPED</promise>
</completion>
```

### 4. Test Coverage Loop

```markdown
Increase test coverage to [TARGET]% (currently at [CURRENT]%).

<detection>
Run: npm run test -- --coverage --coverageReporters=json-summary
Parse: cat coverage/coverage-summary.json
</detection>

<each_iteration>
1. Run tests with coverage
2. Parse report for lowest-coverage files
3. If coverage >= [TARGET]%, output completion promise
4. Pick ONE file with lowest coverage AND business logic
5. Write tests:
   - Test happy path first
   - Add edge cases: null, empty, boundary values
   - Add error cases: invalid input, failures
   - Mock external dependencies
6. Run tests to verify pass + coverage gain
7. Update coverage-progress.txt
8. Commit: 'test: add coverage for [file]'

ONLY ADDRESS ONE FILE PER ITERATION.
</each_iteration>

<focus_on>
Priority order:
1. Business logic: calculations, validations, transformations
2. State management: reducers, view models
3. Services: API handling, persistence
4. Utilities: formatters, parsers, helpers
</focus_on>

<progress_tracking>
Update coverage-progress.txt:
## Iteration N
- Coverage: X% → Y%
- File: [filename]
- Tests added: [count]
- Cases covered: [list edge cases]
</progress_tracking>

<completion>
When coverage >= [TARGET]%: <promise>COVERED</promise>
After 20 iterations if plateaued: document and <promise>COVERED</promise>
</completion>
```

### 5. Linting Loop

```markdown
Fix all linting errors until 0 violations remain.

<detection>
Run: npx eslint . --format json -o lint-report.json
Count: npx eslint . --format compact | wc -l
</detection>

<each_iteration>
1. Run linter
2. Parse report for errors (prioritize over warnings)
3. If 0 errors, output completion promise
4. Group by rule, pick ONE rule category
5. Fix all instances of that rule:
   - Auto-fixable: npx eslint --fix
   - Manual: apply fix consistently
6. Re-run linter to verify
7. Run tests: [TEST_COMMAND]
8. Update lint-progress.txt
9. Commit: 'fix: resolve [rule] lint errors'

ONLY FIX ONE RULE CATEGORY PER ITERATION.
</each_iteration>

<progress_tracking>
Update lint-progress.txt:
## Iteration N
- Errors before: X
- Rule: [rule-name]
- Instances fixed: Y
- Errors after: Z
</progress_tracking>

<completion>
When 0 errors: <promise>LINTED</promise>
After 15 iterations: document and <promise>LINTED</promise>
</completion>
```

### 6. Dead Code Loop

```markdown
Remove dead code, unused dependencies, and stale artifacts.

<detection>
# Unused exports
Run: npx knip --include exports

# Unused dependencies
Run: npx knip --include dependencies

# Commented-out code
grep -rn --include='*.ts' '^\s*//.*[{};()].* ./src | head -50
</detection>

<each_iteration>
1. Run detection for current category
2. If current category clean, move to next
3. If all categories clean, output completion promise
4. Pick ONE item to remove/address
5. Before removing:
   - Search for string-based references
   - Check test files
   - Look for dynamic access
6. Run build and tests
7. Update entropy-progress.txt
8. Commit: 'chore: remove unused [description]'

ONLY ADDRESS ONE ITEM PER ITERATION.
</each_iteration>

<progress_tracking>
Update entropy-progress.txt:
## Category: [current]
### Iteration N
- Found: [item description]
- Action: removed / documented as intentional
- Build: PASS/FAIL
- Tests: PASS/FAIL
</progress_tracking>

<completion>
When all categories clean: <promise>CLEAN</promise>
After 25 iterations: document remaining and <promise>CLEAN</promise>
</completion>
```

### 7. Naming Loop

```markdown
Improve code clarity by renaming vague identifiers to express intent.

<detection>
grep -rn --include='*.ts' -E '\b(data|temp|result|info|value|item|obj|val|tmp|ret|res)\b\s*[:=]' ./src > naming-issues.txt
grep -rn --include='*.ts' -E '(class|function|const)\s+(Manager|Handler|Helper|Utils|Service|Data)[\s<({]' ./src >> naming-issues.txt
Count: wc -l naming-issues.txt
</detection>

<each_iteration>
1. Run detection commands
2. Review naming-issues.txt
3. If no significant issues remain, output completion promise
4. Pick ONE file with the most naming issues
5. For each vague name:
   - Analyze context: What does this actually contain/do?
   - Rename to express intent:
     - data → userProfileData, orderPayload
     - result → validationResult, fetchedUsers
     - Manager → AuthenticationCoordinator, OrderProcessor
6. Update all references
7. Run tests: [TEST_COMMAND]
8. Update naming-progress.txt
9. Commit: 'refactor: improve naming clarity in [file]'

ONLY ADDRESS ONE FILE PER ITERATION.
</each_iteration>

<naming_guidelines>
VARIABLES: Name for WHAT it contains
FUNCTIONS: Name for WHAT it does, include verb
BOOLEANS: Use is/has/should/can prefix
COLLECTIONS: Pluralize to indicate collection
</naming_guidelines>

<progress_tracking>
Update naming-progress.txt:
## Iteration N
- File: [filename]
- Renames:
  - data → orderPayload
  - handleResult() → processPaymentResponse()
- Tests: PASS/FAIL
</progress_tracking>

<completion>
When vague names reduced by 80%+: <promise>CLARIFIED</promise>
After 15 iterations: document remaining and <promise>CLARIFIED</promise>
</completion>
```

### 8. Dependencies Loop

```markdown
Improve dependency health: update outdated packages, remove unused, fix circular deps.

<detection>
# Security vulnerabilities
npm audit --json > audit-report.json

# Outdated packages
npm outdated --json > outdated-report.json

# Unused dependencies
npx depcheck --json > depcheck-report.json

# Circular dependencies
npx madge --circular --json ./src > circular-report.json
</detection>

<each_iteration>
1. Run detection commands
2. Prioritize: security > circular > unused > outdated
3. If all clean, output completion promise
4. Pick ONE issue:
   - FOR SECURITY: npm audit fix or manual update
   - FOR CIRCULAR: Extract shared code to break cycle
   - FOR UNUSED: Remove from package.json
   - FOR OUTDATED: Update one major version at a time
5. Run: npm install && npm run build && npm test
6. Update deps-progress.txt
7. Commit: 'chore: [update/remove/fix] [package/issue]'

ONLY ADDRESS ONE PACKAGE/ISSUE PER ITERATION.
</each_iteration>

<caution>
- Never update all packages at once
- Read changelogs for major version bumps
- Security fixes take priority over feature updates
</caution>

<progress_tracking>
Update deps-progress.txt:
## Iteration N
- Issue type: [security/circular/unused/outdated]
- Package: [name]
- Action: [updated X→Y / removed / refactored cycle]
- Build: PASS/FAIL
- Tests: PASS/FAIL
</progress_tracking>

<completion>
When no security issues and deps healthy: <promise>HEALTHY</promise>
After 20 iterations: document remaining and <promise>HEALTHY</promise>
</completion>
```

### 9. Architecture Loop

```markdown
Reduce coupling and break apart god objects to improve architecture.

<detection>
# Files over 500 lines (god objects)
wc -l ./src/**/*.ts | sort -rn | head -20 > large-files.txt

# Files with >15 imports (high coupling)
for f in ./src/**/*.ts; do
  count=$(grep -c '^import' "$f" 2>/dev/null || echo 0)
  echo "$count $f"
done | sort -rn | head -20 > high-import-files.txt

# Circular dependencies
npx madge --circular ./src
</detection>

<each_iteration>
1. Run detection
2. Identify worst offender (largest file or highest coupling)
3. If all files under thresholds, output completion promise
4. Analyze the god object:
   - List all public methods
   - Group by responsibility
   - Identify which imports serve which responsibilities
5. Plan decomposition:
   - Each responsibility → own module
   - Shared state → separate data module
6. Execute:
   - Create new files
   - Move code, update imports
   - Update all callers
7. Run: build && test
8. Update architecture-progress.txt
9. Commit: 'refactor: decompose [GodObject] into [modules]'

ONLY DECOMPOSE ONE GOD OBJECT PER ITERATION.
</each_iteration>

<signals_of_god_object>
- File over 500 lines
- Class with >10 public methods
- More than 15 imports
- Filename contains: Manager, Handler, Utils (without specificity)
</signals_of_god_object>

<progress_tracking>
Update architecture-progress.txt:
## Iteration N
- God object: [filename]
- Original: X lines, Y imports, Z methods
- Decomposed into:
  - [NewModule1]: A lines, B responsibility
  - [NewModule2]: C lines, D responsibility
- Tests: PASS/FAIL
</progress_tracking>

<completion>
When no files over 500 lines or 15 imports: <promise>DECOUPLED</promise>
After 10 iterations: document remaining and <promise>DECOUPLED</promise>
</completion>
```

---

## PRD/Plan Execution Template

For executing a PRD or implementation plan:

```markdown
@[PRD_FILE] @progress.txt

Execute the PRD until all items are complete.

<each_iteration>
1. Read PRD file to see all requirements
2. Read progress.txt to see what's already done
3. If ALL PRD items have passes: true, output completion promise
4. Choose next task using this priority:
   - Architectural decisions and core abstractions
   - Integration points between modules
   - Unknown unknowns and spike work
   - Standard features
   - Polish and quick wins
5. Implement the feature following TDD:
   - Write failing test
   - Implement minimally
   - Run tests
   - Refactor if needed
6. Run all feedback loops: [TEST_COMMAND] && [TYPE_CHECK] && [LINT]
7. Update PRD item: "passes": true
8. Append to progress.txt:
   - Task completed and PRD item reference
   - Key decisions made
   - Files changed
9. Commit: '[type]: [description]'

ONLY WORK ON ONE FEATURE PER ITERATION.
</each_iteration>

<progress_tracking>
Update progress.txt after each task:
## Iteration N
- PRD item: [reference]
- Completed: [description]
- Decisions: [why choices were made]
- Files: [list of files changed]
- Tests: PASS/FAIL
</progress_tracking>

<stuck_handling>
If after 15 iterations not making progress:
- Document what's blocking
- List what was attempted
- Suggest alternative approaches
- Output: <promise>BLOCKED</promise>
</stuck_handling>

<completion>
When all PRD items pass: <promise>COMPLETE</promise>
</completion>
```

---

## Custom Task Template

For any custom autonomous task:

```markdown
[TASK_DESCRIPTION]

<detection>
[How to measure current state/issues]
</detection>

<each_iteration>
1. Run detection to assess current state
2. If [SUCCESS_CONDITION], output completion promise
3. Pick ONE item to work on (highest priority)
4. Execute the change
5. Verify the change: [VERIFICATION_COMMAND]
6. Update [task]-progress.txt
7. Commit: '[type]: [description]'

ONLY ADDRESS ONE ITEM PER ITERATION.
</each_iteration>

<progress_tracking>
Update [task]-progress.txt:
## Iteration N
- Before: [state]
- Action: [what was done]
- After: [new state]
- Verification: PASS/FAIL
</progress_tracking>

<completion>
When [SUCCESS_CONDITION]: <promise>[PROMISE]</promise>
After [N] iterations: document and <promise>[PROMISE]</promise>
</completion>
```

---

## Generating the Prompt

After gathering requirements, generate a complete Ralph prompt:

1. **Choose the appropriate template** based on task type
2. **Customize placeholders**:
   - `[TEST_COMMAND]` → actual test command (npm test, swift test, etc.)
   - `[TARGET]` → specific threshold
   - `[LANGUAGE]` → file extensions and tools
3. **Set appropriate max-iterations** based on task scope
4. **Write to file** using the Write tool

## Final Output

**ALWAYS use the Write tool** to create `RALPH_PROMPT.md` in the project root with this structure:

```markdown
# Ralph Prompt: [Brief Task Description]

Generated: [YYYY-MM-DD]
Type: [Hygiene Type / PRD Execution / Custom]
Max Iterations: [N]
Completion Promise: [PROMISE]

---

## Purpose

[1-2 sentence description of what this prompt accomplishes]

## Prerequisites

- [ ] [Any setup needed, e.g., "Install jscpd: npm install -g jscpd"]
- [ ] [Test command works: npm test]

---

## Prompt

[FULL PROMPT TEXT - this is what gets passed to /ralph-loop]

---

## Run Command

Reference this file directly:
```bash
/ralph-loop "@RALPH_PROMPT.md" --max-iterations [N] --completion-promise "[PROMISE]"
```

Or copy the prompt above and run:
```bash
/ralph-loop "[first line of prompt]..." --max-iterations [N] --completion-promise "[PROMISE]"
```

---

## Progress Files

This prompt will create/update:
- `[name]-progress.txt` - Iteration-by-iteration progress log

Clean up after completion:
```bash
rm [name]-progress.txt
```
```

After writing the file, confirm to the user:
1. The file location: `RALPH_PROMPT.md`
2. The run command they should use
3. Any prerequisites they need to install
