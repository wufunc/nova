---
name: git-commit
description: Automated git commit workflow with intelligent commit message generation and memory management. Use when the user requests to commit code changes (e.g., "/git-commit", "commit my changes", "commit this work"). Generates detailed Conventional Commits format messages based on conversation context, invokes memory update for architecture/devlog/ADR maintenance, stages all changes, creates the commit, and applies memory tags.
---

# Git Commit

## Overview

This skill automates the complete git commit workflow: analyze changes, generate commit message, update project memory, stage, commit, and tag.

## Workflow

Execute the following steps in order when this skill is invoked:

### Step 1: Analyze Conversation Context

Review the conversation history to understand:
- What code changes were made
- What features were added or bugs were fixed
- What architectural decisions or design choices were discussed
- What files were modified or created

### Step 2: Check Git Status

Run parallel git commands to gather current repository state:

```bash
# Check untracked and modified files (never use -uall flag)
git status

# View staged and unstaged changes
git diff HEAD

# View recent commit messages to understand the project's commit style
git log --oneline -10
```

### Step 3: Generate Commit Message

Based on the analysis, generate a commit message following **Conventional Commits** format:

**Format:**
```
<type>(<scope>): <subject>

<body>

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Type options:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring without behavior change
- `perf`: Performance improvements
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `build`: Build system or dependencies changes
- `ci`: CI/CD changes
- `chore`: Other changes that don't modify src or test files

**Guidelines:**
- **Subject**: Concise summary (50-72 chars max), imperative mood, no period
- **Body**: Detailed description including what changed and why, key implementation details, impact on the codebase
- Keep each line in body under 72 characters
- Use blank line between subject and body

### Step 4: Invoke Memory Update

Before staging and committing, use the **Skill tool** to invoke the **memory** skill with argument **update**:

```
Skill(skill="memory", args="update")
```

The memory skill will:
- Update arch.md if architectural changes detected
- Create DevLog entries if development experience worth recording
- Create ADR entries if architectural decisions were made
- Return: list of created files + tag name (or "no updates needed")

**Note the returned tag name** - it will be used in Step 7.

**CRITICAL — Uninterrupted Execution:**
The memory skill internally invokes sub-skills (`devlog-creator`, `adr-creator`). When a sub-skill completes and returns, you MUST immediately continue the remaining workflow (memory's next steps → Step 5 → Step 6 → Step 7 → Step 8) without pausing or waiting for user input. Treat the entire git-commit workflow (Steps 1–8) as a single atomic operation — do NOT stop between steps unless an error requires user intervention.

### Step 5: Stage All Changes

```bash
# Stage all changes including any memory files created in Step 4
git add -A
```

### Step 6: Create Commit

```bash
# Create commit with the generated message using heredoc for proper formatting
git commit -m "$(cat <<'EOF'
<generated commit message here>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

**Important notes:**
- Always use heredoc format for commit messages to preserve formatting
- Never skip git hooks (no --no-verify flag)
- If pre-commit hooks fail, fix the issues and create a NEW commit (never use --amend unless explicitly requested)
- If commit fails, report the error to the user and stop the workflow

### Step 7: Apply Memory Tag

If Step 4 returned a tag name (memory files were created):

```bash
# Apply the memory tag to this commit
git tag mem/NNN

# Verify tag was created
git tag -l 'mem/*' --sort=-version:refname | head -3
```

If Step 4 returned "no updates needed", skip this step.

### Step 8: Verify

```bash
# Verify commit and tag
git status
git log --oneline -3
```

## Error Handling

- **If no changes to commit**: Inform the user that there are no changes and skip the workflow
- **If commit fails**: Report the specific error message and stop (do not proceed to tagging)
- **If pre-commit hooks fail**: Fix the reported issues, re-stage files, and create a NEW commit
- **If memory update fails**: Log the error but continue with the commit (memory update is non-blocking)
- **Never use force flags** unless explicitly requested by the user

## Notes

- This skill focuses on **detailed, meaningful** commit messages, not brief one-liners
- The commit message should tell the story of what changed and why
- Always include the Co-Authored-By line to credit Claude's contribution
- Memory update ensures architecture docs, devlogs, and ADRs stay in sync with code changes
