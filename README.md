# 🦆 The Duck Purge

**Secure and reliable metadata sanitizer**

Protect your privacy by removing metadata from PDFs, images, Office documents, audio, and video files.

![GitHub Actions](https://github.com/morphilab/theduckpurge/workflows/Tests/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.0-brightgreen)
![Shell](https://img.shields.io/badge/shell-bash-89e051)

## ✨ Features

- **4 progressive cleaning levels** (`light` → `paranoid`)
- Supports PDF, JPG, PNG, DOCX, XLSX, MP4, MP3, and more
- Advanced options: `--check-only`, `--dry-run`, `--zero-trace`
- Optional automatic backups
- Automatic renaming of cleaned files
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
theduckpurge v1.0.0 — standard
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

**Dry-run recursive scan** of a directory tree:

```text
$ theduckpurge --dry-run --level paranoid -R ./my_files/
theduckpurge v1.0.0 — paranoid
• Processing directory: ./my_files/
• [1/3] [DRY RUN] Would process: report.pdf (level: paranoid)
⚠ Unsupported format: notes.txt
• [3/3] [DRY RUN] Would process: vacation.jpg (level: paranoid)

Evaluated: 3  |  Simulated: 2  |  Skipped: 1  |  Failed: 0
• Simulation completed.
```

### Main options

| Option              | Description                                      |
|---------------------|--------------------------------------------------|
| `--level LEVEL`     | light / standard / aggressive / paranoid         |
| `--check-only`      | Only verify, do not modify                       |
| `--dry-run`         | Simulate without making changes                  |
| `--zero-trace`      | Silent mode, no backups                          |
| `--backup`          | Create backup before cleaning                    |
| `--rename`          | Rename cleaned files                             |
| `-R, --recursive`   | Process directories recursively                  |
| `--quiet`           | Only show errors and warnings                    |
| `--force`           | Ignore 100 MB size limit                         |

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
├── theduckpurge              # Main script (557 lines)
├── install.sh                # One-liner installer
├── test/
│   ├── test_theduckpurge.bats # 32 Bats tests
│   └── fixtures/             # Real test files
├── .github/workflows/        # CI/CD (ShellCheck + Bats)
├── AGENTS.md                 # Development guide
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## 🧪 Tests

The project includes **32 automated tests** using [Bats](https://github.com/bats-core/bats-core). They cover argument parsing, metadata detection, dry-run, quiet mode, real cleaning, backup, rename, symlink rejection, recursive processing, paranoid mode, and more.

```bash
# Install test dependencies (once)
mkdir -p test/test_helper
git clone --depth 1 https://github.com/bats-core/bats-support.git test/test_helper/bats-support
git clone --depth 1 https://github.com/bats-core/bats-assert.git  test/test_helper/bats-assert

# Run tests
bats --print-output-on-failure test/test_theduckpurge.bats
```

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
**Version:** 1.0.0 (June 2, 2026)  
**Author:** morphilab
