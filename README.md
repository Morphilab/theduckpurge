# 🦆 The Duck Purge

**Secure and reliable metadata sanitizer**

Protect your privacy by removing metadata from PDFs, images, Office documents, audio, and video files.

![GitHub Actions](https://github.com/morphilab/theduckpurge/workflows/Tests/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.1.0-brightgreen)
![Shell](https://img.shields.io/badge/shell-bash-89e051)

## ✨ Features

- **4 progressive cleaning levels** (`light` → `paranoid`)
- Supports PDF, JPG, PNG, DOCX, XLSX, MP4, MP3, HEIC, WebP, SVG, and more
- Advanced options: `--check-only`, `--dry-run`, `--zero-trace`, `--report`
- Optional automatic backups
- Automatic renaming of cleaned files
- Config file support (`--config`)
- File exclusion patterns (`--exclude`)
- JSON output for integration (`--json`)
- SHA256-verified installer
- Fully offline — only depends on `mat2` and `exiftool`

## ⚠️ AI Disclosure / Divulgación de IA

**English:**  
This project was developed with assistance from artificial intelligence tools. Given the automated nature of some components, users are advised to review and test the code independently before integrating it into their own systems.

**Español:**  
Este proyecto fue desarrollado con asistencia de herramientas de inteligencia artificial. Dada la naturaleza automatizada de algunos componentes, se recomienda que los usuarios revisen y prueben el código independientemente antes de integrarlo en sus propios sistemas.

## 🚀 Installation

### Recommended (one-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/morphilab/theduckpurge/main/install.sh | sudo bash
```

### Or clone the repository

```bash
git clone https://github.com/morphilab/theduckpurge.git
cd theduckpurge
chmod +x theduckpurge
sudo cp theduckpurge /usr/local/bin/
```

## 📖 Usage

No arguments shows the help. Examples:

```bash
# Only check metadata
theduckpurge --check-only document.pdf

# Standard cleaning (recommended)
theduckpurge --level standard image.jpg

# Maximum recursive cleaning
theduckpurge --level paranoid -R ./my_files/

# Quiet, only errors and warnings
theduckpurge --quiet --level aggressive *.docx

# Detailed metadata report
theduckpurge --report photo.jpg

# JSON output for scripting
theduckpurge --json --check-only ./photos/

# Exclude patterns
theduckpurge --exclude "*.log" --exclude "node_modules" -R ./

# Generate config file
theduckpurge --init
```

### Demo

**Before cleaning** — metadata leaks your authorship and software:

```text
$ exiftool photo.jpg | grep -E 'Author|Title|Software'
Title                          : Prueba TheDuckPurge
Author                         : morphilab
```

**Clean it:**

```text
$ theduckpurge --level standard photo.jpg
theduckpurge v1.1.0 — standard
• [1/1] Processing: photo.jpg (level: standard)
✓ Cleaned: photo.jpg

Evaluated: 1  |  Cleaned: 1  |  Skipped: 0  |  Failed: 0
✓ Cleanup completed.
```

**After cleaning** — privacy metadata is gone, technical fields (size, dimensions, MIME) are preserved:

```text
$ exiftool photo.jpg | grep -E 'Author|Title'
(no output)
```

**Metadata report:**

```text
$ theduckpurge --report photo.jpg
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: photo.jpg
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Path:       /home/user/photo.jpg
  Extension:  .jpg
  Size:       245760 bytes
  Status:     ⚠ DIRTY (3 metadata fields found)

  Metadata details:
    Author [privacy]: morphilab
    Title [privacy]: Prueba TheDuckPurge
    Image Width [technical]: 1920
```

### Main options

| Option              | Description                                      |
|---------------------|--------------------------------------------------|
| `--level LEVEL`     | light / standard / aggressive / paranoid         |
| `--check-only`      | Only verify, do not modify                       |
| `--report`          | Detailed metadata report per file                |
| `--dry-run`         | Simulate without making changes                  |
| `--zero-trace`      | Silent mode, no backups                          |
| `--backup`          | Create backup before cleaning                    |
| `--rename`          | Rename cleaned files                             |
| `-R, --recursive`   | Process directories recursively                  |
| `--quiet`           | Only show errors and warnings                    |
| `--verbose`         | Show detailed per-file info                      |
| `--force`           | Ignore 100 MB size limit                         |
| `--no-color`        | Disable colored output                           |
| `--json`            | Output JSON report                               |
| `--config FILE`     | Load config file with defaults                   |
| `--exclude GLOB`    | Exclude files matching pattern (repeatable)      |
| `--jobs N`          | Process N files in parallel                      |
| `--init`            | Generate .theduckpurge.exclude in current dir    |

## 🛡️ Cleaning Levels

| Level         | Tools used                       | Speed        | Security       |
|---------------|----------------------------------|--------------|----------------|
| **light**     | mat2 --light                     | Very fast    | Basic          |
| **standard**  | mat2 (default)                   | Fast         | Good           |
| **aggressive**| mat2 + exiftool                  | Medium       | Very good      |
| **paranoid**  | mat2 + exiftool + re-encode     | Slow         | **Maximum**    |

## 📂 Project structure

```
theduckpurge/
├── theduckpurge              # Main script (~800 lines)
├── install.sh                # One-liner installer with SHA256
├── test/
│   ├── test_theduckpurge.bats # 51 Bats tests
│   └── fixtures/             # Real test files
├── dev/
│   ├── flujo_git.md          # Git workflow definition
│   └── bump_version.sh       # Version bumper script
├── .github/workflows/
│   ├── test.yml              # CI: ShellCheck + Bats (matrix)
│   └── release.yml           # Auto-release on tag
├── AGENTS.md                 # AI agent development guide
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## 🧪 Tests

The project includes **51 automated tests** using [Bats](https://github.com/bats-core/bats-core). They cover argument parsing, metadata detection, dry-run, quiet mode, real cleaning, backup, rename, symlink rejection, recursive processing, paranoid mode, config files, exclusions, JSON output, report mode, and more.

```bash
# Install test dependencies (once)
mkdir -p test/test_helper
git clone --depth 1 https://github.com/bats-core/bats-support.git test/test_helper/bats-support
git clone --depth 1 https://github.com/bats-core/bats-assert.git  test/test_helper/bats-assert

# Run tests
bats --print-output-on-failure test/test_theduckpurge.bats
```

## Exit codes

| Code | Meaning                        |
|------|--------------------------------|
| 0    | Success (all files processed)  |
| 1    | Processing errors occurred     |
| 2    | No files were processed        |
| 3    | Missing required dependency    |
| 4    | Permission error               |

## Config file

Create `~/.config/theduckpurge/config` or use `--config <path>`:

```ini
level=standard
backup=true
recursive=true
jobs=4
exclude=node_modules
exclude=.git
exclude=*.log
```

## Requirements

- `mat2`
- `exiftool` (`libimage-exiftool-perl`)
- `ffmpeg` (only needed for `paranoid` level)

Install on Debian/Ubuntu:
```bash
sudo apt install mat2 libimage-exiftool-perl ffmpeg
```

## Release process

```bash
# Bump version (updates all files, runs tests)
dev/bump_version.sh 1.2.0

# Review changes, then:
git add -A && git commit -m "chore: bump version to 1.2.0"
git tag v1.2.0
git push origin main --tags
```

---

**License:** MIT  
**Version:** 1.1.0  
**Author:** morphilab
