# theduckpurge Changelog

All notable versions of the project are documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/).

## [1.1.0] - 2026-08-18

### Added
- `--report` mode: detailed metadata report per file with privacy/technical field labeling
- `--no-color` flag: explicit color disable (respects `NO_COLOR` env var)
- `--verbose` flag: show detailed per-file processing info
- `--json` flag: output structured JSON report for scripting/integration
- `--config FILE` support: load default settings from config file
- `--exclude GLOB` support: skip files matching patterns (repeatable)
- `.theduckpurge.exclude` auto-loading: exclusion patterns from project root
- `~/.config/theduckpurge/exclude` auto-loading: global exclusion patterns
- `--init` command: generate `.theduckpurge.exclude` in current directory
- Extended format support: HEIC, HEIF, WebP, SVG
- Improved exit codes: 0=success, 1=failure, 2=no files, 3=missing dep, 4=permission
- CI matrix: tests on Ubuntu 22.04 and 24.04
- CI dependency caching: apt packages and Bats helpers
- GitHub Release workflow: auto-creates releases with SHA256 checksums on tag push
- `dev/bump_version.sh`: version bumper script across all files
- SHA256 checksum verification in installer (`--skip-verify` to bypass)
- 19 new Bats tests (total: 51)

### Changed
- Version bumped from 1.0.0 to 1.1.0
- Script expanded from 557 to ~800 lines

## [1.0.0] - 2026-06-11

### Added
- 4 progressive cleaning levels: `light`, `standard`, `aggressive`, `paranoid`
- Metadata sanitization for PDF, JPG, JPEG, PNG, GIF, BMP, TIFF, Office (DOC/DOCX/XLS/XLSX/PPT/PPTX/ODT/ODS/ODP), audio (MP3/FLAC/WAV/M4A), and video (MP4/AVI/MOV/MKV/WMV)
- `mat2` as primary backend, `exiftool` as secondary, `ffmpeg` for paranoid re-encoding
- `--check-only` mode: verify metadata without modifying files
- `--dry-run` mode: simulate processing without changes
- `--zero-trace` mode: silent processing with no backups
- `--backup` option: create timestamped backups before cleaning
- `--rename` option: rename cleaned files with `clean_` prefix
- `-R, --recursive` for directory processing
- `--force` to override 100 MB size limit
- `--quiet` mode for minimal output
- Symlink rejection for security
- Progress indicator `[N/M]` for batch processing
- Exit codes: 0 success, 1 failure
- CI/CD with GitHub Actions (ShellCheck + Bats)
- One-liner installer (`install.sh`)
- 32 automated Bats tests

### Fixed
- ShellCheck SC1091 suppression in test source command
- CI: upgraded to `actions/checkout@v5`
