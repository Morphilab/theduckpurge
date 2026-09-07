#!/usr/bin/env bash
# =============================================================================
# theduckpurge — Installer with SHA256 verification
# =============================================================================
# Downloads the latest version from GitHub, verifies integrity, and installs.
# Usage: curl -fsSL https://raw.githubusercontent.com/morphilab/theduckpurge/main/install.sh | bash

set -euo pipefail

URL="https://raw.githubusercontent.com/morphilab/theduckpurge/main/theduckpurge"
CHECKSUM_URL="https://raw.githubusercontent.com/morphilab/theduckpurge/main/theduckpurge.sha256"
TARGET="/usr/local/bin/theduckpurge"
TMPFILE=""
CHECKSUM_FILE=""
SKIP_VERIFY=false

for arg in "$@"; do
    case "$arg" in
        --skip-verify) SKIP_VERIFY=true ;;
        --help|-h)
            echo "Usage: install.sh [--skip-verify]"
            echo "  --skip-verify  Skip SHA256 checksum verification"
            exit 0 ;;
    esac
done

cleanup() {
    [[ -n "$TMPFILE" && -f "$TMPFILE" ]] && rm -f "$TMPFILE"
    [[ -n "$CHECKSUM_FILE" && -f "$CHECKSUM_FILE" ]] && rm -f "$CHECKSUM_FILE"
}
trap cleanup EXIT INT TERM

# --- Pre-flight checks ---
if ! command -v curl &>/dev/null; then
    echo "✗ curl is not installed. Please install it and try again." >&2
    exit 1
fi

if [[ -f "$TARGET" ]]; then
    read -r -p "⚠ $TARGET already exists. Overwrite? [y/N] " reply
    [[ "$reply" != "y" && "$reply" != "Y" ]] && { echo "Installation cancelled."; exit 0; }
fi

# --- Download script ---
echo "• Downloading theduckpurge from GitHub..."
TMPFILE="$(mktemp /tmp/theduckpurge.XXXXXX)"
HTTP_CODE="$(curl -fsSL -w '%{http_code}' -o "$TMPFILE" "$URL" 2>/dev/null || true)"

if [[ "$HTTP_CODE" != "200" ]]; then
    echo "✗ Download error (HTTP $HTTP_CODE). Check your connection." >&2
    exit 1
fi

# Quick sanity check: the downloaded file should be a shell script
if ! head -1 "$TMPFILE" | grep -q '^#!/'; then
    echo "✗ Downloaded file does not look like a valid script." >&2
    exit 1
fi

# --- Download checksum ---
if [[ "$SKIP_VERIFY" != true ]]; then
    echo "• Downloading checksum..."
    CHECKSUM_FILE="$(mktemp /tmp/theduckpurge_checksum.XXXXXX)"
    HTTP_CODE="$(curl -fsSL -w '%{http_code}' -o "$CHECKSUM_FILE" "$CHECKSUM_URL" 2>/dev/null || true)"

    if [[ "$HTTP_CODE" == "200" ]] && [[ -s "$CHECKSUM_FILE" ]]; then
        EXPECTED="$(awk '{print $1}' "$CHECKSUM_FILE")"
        ACTUAL="$(sha256sum "$TMPFILE" | awk '{print $1}')"

        if [[ "$EXPECTED" != "$ACTUAL" ]]; then
            echo "✗ SHA256 checksum mismatch!" >&2
            echo "  Expected: $EXPECTED" >&2
            echo "  Got:      $ACTUAL" >&2
            echo "  The downloaded file may be corrupted or tampered with." >&2
            exit 1
        fi
        echo "✓ Checksum verified."
    else
        echo "⚠ Could not download checksum (HTTP $HTTP_CODE). Skipping verification." >&2
    fi
else
    echo "• Skipping checksum verification (--skip-verify)"
fi

chmod +x "$TMPFILE"

# --- Install ---
if [[ -w "$(dirname "$TARGET")" ]]; then
    mv "$TMPFILE" "$TARGET"
    TMPFILE=""
else
    echo "• Installing to $TARGET (requires sudo)..."
    if sudo mv "$TMPFILE" "$TARGET"; then
        TMPFILE=""
    else
        echo "✗ Could not install. File left at $TMPFILE" >&2
        exit 1
    fi
fi

# --- Verify installation ---
INSTALLED_VERSION=""
if command -v theduckpurge &>/dev/null; then
    INSTALLED_VERSION="$(theduckpurge --version 2>/dev/null || true)"
fi

echo "✅ theduckpurge successfully installed at $TARGET"
[[ -n "$INSTALLED_VERSION" ]] && echo "   $INSTALLED_VERSION"
echo ""
echo "Usage:"
echo "  theduckpurge              # Show help"
echo "  theduckpurge --check-only document.pdf"
echo "  theduckpurge --level paranoid -R ./my_files/"
echo ""
echo "Thank you for using theduckpurge!"
