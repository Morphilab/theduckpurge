#!/usr/bin/env bash
# =============================================================================
# theduckpurge — Installer
# =============================================================================
# Downloads the latest version from GitHub and installs it to /usr/local/bin.
# Usage: curl -fsSL https://raw.githubusercontent.com/morphilab/theduckpurge/main/install.sh | bash

set -euo pipefail

URL="https://raw.githubusercontent.com/morphilab/theduckpurge/main/theduckpurge"
TARGET="/usr/local/bin/theduckpurge"
TMPFILE=""

cleanup() {
    [[ -n "$TMPFILE" && -f "$TMPFILE" ]] && rm -f "$TMPFILE"
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

# --- Download ---
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

echo "✅ theduckpurge successfully installed at $TARGET"
echo ""
echo "Usage:"
echo "  theduckpurge              # Show help"
echo "  theduckpurge --check-only document.pdf"
echo "  theduckpurge --level paranoid -R ./my_files/"
echo ""
echo "Thank you for using theduckpurge! 🦆"
