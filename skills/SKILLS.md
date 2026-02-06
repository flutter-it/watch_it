# Claude Code Skills for watch_it

This directory contains **Claude Code skill files** that help AI assistants (like Claude Code, Cursor, GitHub Copilot) generate correct watch_it code efficiently.

## What are Skills?

Skills are concise reference guides optimized for AI consumption. They contain:
- Critical rules and constraints (especially the watch ordering rule!)
- Common usage patterns
- Anti-patterns with corrections
- Integration examples

**Note**: These are NOT replacements for comprehensive documentation. For detailed guides, see https://flutter-it.dev/documentation/watch_it/

## Available Skills

This directory includes:

1. **`watch_it-expert.md`** - watch_it patterns, ordering rules, lifecycle functions, performance
2. **`get_it-expert.md`** - get_it dependency injection (watch_it depends on get_it)
3. **`flutter-architecture-expert.md`** - High-level app architecture guidance

**Note**: For the ecosystem overview, see `/skills/flutter_it.md` in the monorepo root.

## Installation

To use these skills with Claude Code:

### Option 1: Copy to Global Skills Directory (Recommended)

```bash
# Copy all skills to your global Claude Code skills directory
cp skills/*.md ~/.claude/skills/
```

### Option 2: Symlink (Auto-updates when package updates)

```bash
# Create symlinks (Linux/Mac)
ln -s $(pwd)/skills/watch_it-expert.md ~/.claude/skills/watch_it-expert.md
ln -s $(pwd)/skills/get_it-expert.md ~/.claude/skills/get_it-expert.md
ln -s $(pwd)/skills/flutter-architecture-expert.md ~/.claude/skills/flutter-architecture-expert.md
```

### Option 3: Manual Copy (Windows)

```powershell
# Copy files manually
copy skills\*.md %USERPROFILE%\.claude\skills\
```

## Using the Skills

Once installed, Claude Code will automatically have access to these skills when working on Flutter projects.

**For other AI assistants**:
- **Cursor**: Copy to project root or reference in `.cursorrules`
- **GitHub Copilot**: Copy to `.github/copilot-instructions.md`

## Verification

After installation, you can verify by asking Claude Code:

```
Can you help me create a reactive widget with watch_it?
```

Claude should reference the skill and provide correct watch patterns with proper ordering.

## Contents Overview

### watch_it-expert.md (~1500 tokens)

Covers:
- **CRITICAL**: Watch ordering rule (like React hooks)
- Widget requirements (WatchingWidget/WatchingStatefulWidget)
- Core watch functions (watchIt, watchValue, watchPropertyValue)
- Lifecycle functions (createOnce, callOnce, registerHandler)
- Startup orchestration with allReady()
- Widget granularity for performance optimization
- Proxy objects pattern for memory management
- Common anti-patterns

### get_it-expert.md (~1200 tokens)

Covers:
- Basic registration patterns (watch_it requires get_it)
- Async initialization
- Scopes for session management
- Testing patterns

### flutter-architecture-expert.md (~800 tokens)

Covers:
- Startup orchestration patterns
- Layer structure
- State management with managers and watch_it
- Widget granularity best practices

## Why watch_it Skills Are Important

watch_it has **strict ordering requirements** (similar to React Hooks) that can cause runtime errors if violated. The skills help AI assistants:

1. **Avoid ordering violations** - Always call watch functions in same order
2. **Use correct widgets** - Extend WatchingWidget or WatchingStatefulWidget
3. **Optimize performance** - Break into granular widgets
4. **Use lifecycle functions correctly** - createOnce, callOnce, registerHandler

## Documentation Links

- **Comprehensive docs**: https://flutter-it.dev/documentation/watch_it/
- **Package README**: https://pub.dev/packages/watch_it
- **GitHub**: https://github.com/escamoteur/watch_it
- **Discord**: https://discord.gg/ZHYHYCM38h

## Contributing

Found an issue or have suggestions for improving these skills?
- Open an issue on GitHub
- Join the Discord community
- Submit a PR with improvements

---

**Note**: These skills are designed for AI consumption. For human-readable documentation, please visit https://flutter-it.dev
