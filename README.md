# 🦆 The Duck Purge

**Secure and reliable metadata sanitizer**

Protect your privacy by removing metadata from PDFs, images, Office documents, audio, and video files.

![GitHub Actions](https://github.com/morphilab/theduckpurge/workflows/Tests/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.2.0-brightgreen)
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

# Exclude patterns (ERE regex)
theduckpurge --exclude '\.log$' --exclude "node_modules" -R ./

# Generate config file
theduckpurge --init
```

### Demo

**Before cleaning** — metadata leaks your authorship and software:

```text
$ exiftool photo.jpg | grep -E 'Author|Title|Software'
Title                          : TheDuckPurge Test Image
Author                         : TheDuckPurge Test Suite
```

**Clean it:**

```text
$ theduckpurge --level standard photo.jpg
theduckpurge v1.2.0 — standard
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
    Author [privacy]: TheDuckPurge Test Suite
    Title [privacy]: TheDuckPurge Test Image
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
| `--exclude PATTERN` | Exclude files matching ERE regex (repeatable)    |
| `--init`            | Generate .theduckpurge.exclude in current dir    |

> Note: an older `--jobs N` flag is still accepted but not implemented; the tool runs sequentially and prints a warning.

## 🛡️ Cleaning Levels

| Level         | Tools used                                    | Speed     | Security    |
|---------------|-----------------------------------------------|-----------|-------------|
| **light**     | mat2 --light                                  | Very fast | Basic       |
| **standard**  | mat2 (default)                                | Fast      | Good        |
| **aggressive**| mat2 + exiftool                               | Medium    | Very good   |
| **paranoid**  | mat2 + exiftool + ffmpeg true re-encode       | Slow      | **Maximum** |

`paranoid` re-encodes media with real codecs (video: H.264/AAC, images: full pixel
re-encode), stripping metadata at container *and* stream level. If a format cannot
be re-encoded, a remux fallback is used and warned about. `ffmpeg` is **required**
for `paranoid`; the tool refuses to run that level without it.

## 📂 Project structure

```
theduckpurge/
├── theduckpurge               # Main script
├── install.sh                 # One-liner installer with SHA256
├── test/
│   ├── test_theduckpurge.bats # 79 Bats tests
│   └── fixtures/              # Real test files
├── .github/workflows/
│   ├── test.yml               # CI: ShellCheck + Bats (matrix)
│   └── release.yml            # Auto-release on tag
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## 🧪 Tests

The project includes **79 automated tests** using [Bats](https://github.com/bats-core/bats-core). They cover argument parsing, metadata detection, dry-run, quiet mode, real cleaning, backup, rename, symlink rejection, recursive processing, paranoid mode, config files, exclusions, JSON output, report mode, permission error handling, and more.

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
exclude=node_modules
exclude=\.git$
exclude=\.log$
```

Exclusion patterns use **extended regular expressions** (ERE, `grep -E` syntax)
and match against the file basename or full path.

## Requirements

- `mat2`
- `exiftool` (`libimage-exiftool-perl`)
- `ffmpeg` (only needed for `paranoid` level)

Install on Debian/Ubuntu:
```bash
sudo apt install mat2 libimage-exiftool-perl ffmpeg
```

---

**License:** MIT  
**Version:** 1.2.0  
**Author:** morphilab
