# Contributing to aicoding-memory

Thank you for your interest in contributing! 感谢你对本项目的关注！

This guide is bilingual (English / 中文).

---

## Reporting Issues / 提交 Issue

- Use [GitHub Issues](https://github.com/anthropic-lab/aicoding-memory/issues)
- Include your agent type/version (Claude/Codex/Cursor) and OS
- For bugs, describe: what you expected, what happened, and steps to reproduce
- For feature requests, describe the use case

---

## Pull Requests / 提交 PR

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-change`
3. Make your changes
4. Test locally (see below)
5. Submit a PR with a clear description

### PR Guidelines

- Keep changes focused — one PR per feature/fix
- Update both English and Chinese docs if you modify documentation
- Follow existing code style and conventions

---

## Skill Modification Guidelines / Skill 修改规范

Skills are the core of this project. When modifying skills:

1. **Skills must be generic** — no project-specific logic, paths, or configurations
2. **Test with a real agent session** — verify the skill works end-to-end
3. **Update references if format changes** — `references/` and `assets/` must stay in sync with `SKILL.md`
4. **Don't break the four-layer architecture** — decision logic stays in `memory`, writing stays in creators

### Skill Structure

```
skill-name/
├── SKILL.md              # Main skill file (required)
├── references/           # Format specs, guidelines (optional)
└── assets/               # Templates, scripts (optional)
```

---

## Local Testing / 本地测试

### Test Installation

```bash
# Test install on your machine
bash install.sh

# Verify skills are installed (examples)
ls ~/.claude/skills/memory/
ls ~/.codex/skills/memory/
ls ~/.cursor/skills/memory/

# Verify instruction files/rules were updated
grep "aicoding-memory" ~/.claude/CLAUDE.md
grep "aicoding-memory" ~/.codex/AGENTS.md
ls ~/.cursor/rules/aicoding-memory.mdc

# Optional: install only selected agents
bash install.sh --agents codex,cursor
```

### Test Uninstallation

```bash
bash uninstall.sh

# Verify skills are removed (examples)
ls ~/.claude/skills/memory/ 2>/dev/null || echo "Removed"
ls ~/.codex/skills/memory/ 2>/dev/null || echo "Removed"
ls ~/.cursor/skills/memory/ 2>/dev/null || echo "Removed"

# Verify instruction files/rules were cleaned up
grep "aicoding-memory" ~/.claude/CLAUDE.md || echo "Cleaned"
grep "aicoding-memory" ~/.codex/AGENTS.md || echo "Cleaned"
ls ~/.cursor/rules/aicoding-memory.mdc 2>/dev/null || echo "Removed"
```

### Test Memory Workflow

1. Install the skills
2. Open a test project with Claude Code, Codex, or Cursor
3. Verify `/memory recall` works (auto-initializes `.aicoding/memory/`)
4. Make a code change and run `/git-commit`
5. Check if memory evaluation runs correctly

---

## Documentation / 文档

- All user-facing documentation must be bilingual (English + Chinese)
- `README.md` (English) and `README.zh-CN.md` (Chinese) must stay in sync
- `DESIGN.md` (English) and `DESIGN.zh-CN.md` (Chinese) must stay in sync
- Technical terms should be accurate in both languages

---

## Code of Conduct / 行为准则

- Be respectful and constructive / 尊重他人，建设性地讨论
- Focus on technical merit / 聚焦技术本身
- Welcome newcomers / 欢迎新人参与
- No discrimination of any kind / 不接受任何形式的歧视
