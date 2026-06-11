# How to contribute to theduckpurge

Thank you for wanting to contribute! 🎉

## 🚀 How to contribute

1. **Fork** the repository
2. **Create a branch** with a descriptive name:
   ```bash
   git checkout -b feature/new-functionality
   ```
3. **Make your changes** and make sure tests still pass:
   ```bash
   bats test/test_theduckpurge.bats
   ```
4. **Commit** with clear messages
5. **Open a Pull Request** describing what you changed and why

## 🧪 Tests

Before submitting a PR, verify all tests pass:

```bash
bats test/test_theduckpurge.bats
```

Also run ShellCheck:

```bash
shellcheck theduckpurge
```

## 📝 Style guidelines

- Use `set -euo pipefail` in any new script
- Prefer `[[ ]]` over `[ ]` for comparisons
- Boolean variables always compared with `== true` / `!= true`
- Keep the existing logging style (`log INFO`, `log ERROR`, etc.)
- Update `CHANGELOG.md` if the change is user-visible

## ❓ Questions or feedback

Open an [Issue](https://github.com/morphilab/theduckpurge/issues) if you have questions or want to suggest an improvement.

Thank you for your contribution! 🦆
